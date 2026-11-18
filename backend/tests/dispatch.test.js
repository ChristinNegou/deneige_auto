const Notification = require('../models/Notification');
const Reservation = require('../models/Reservation');
const {
  createTestUser,
  createTestWorker,
  createTestVehicle,
  createTestReservation,
} = require('./helpers');
const { notifyNearbyWorkers, alertUnassignedReservations } = require('../services/dispatchService');

jest.mock('stripe');

const MONTREAL = [-73.5673, 45.5017];
const LAVAL_FAR = [-73.75, 45.85]; // ~40 km

let seq = 0;
const email = (p) => `${p}${++seq}@example.com`;

const worker = (profile = {}, root = {}) => createTestWorker({
  email: email('w'),
  ...root,
  workerProfile: {
    isAvailable: true,
    currentLocation: { type: 'Point', coordinates: MONTREAL },
    equipmentList: ['shovel', 'brush', 'ice_scraper'],
    maxActiveJobs: 3,
    vehicleType: 'car',
    ...profile,
  },
});

const paidJob = async (overrides = {}) => {
  const client = await createTestUser({ email: email('c') });
  const vehicle = await createTestVehicle(client._id);
  return createTestReservation(client._id, vehicle._id, {
    status: 'pending',
    paymentStatus: 'paid',
    ...overrides,
  });
};

const notifiedIds = async (type, reservationId) =>
  (await Notification.find({ type, reservationId })).map((n) => String(n.userId));

describe('notifyNearbyWorkers', () => {
  it('prevents only the workers who could take the job, once', async () => {
    const near = await worker();
    const far = await worker({ currentLocation: { type: 'Point', coordinates: LAVAL_FAR } });
    const offline = await worker({ isAvailable: false });
    const suspended = await worker({ isSuspended: true });
    const busy = await worker({ maxActiveJobs: 1 });
    const job = await paidJob();
    await paidJob({ status: 'enRoute', workerId: busy._id });

    expect(await notifyNearbyWorkers(job)).toBe(1);

    const ids = await notifiedIds('urgentRequest', job._id);
    expect(ids).toEqual([String(near._id)]);
    for (const w of [far, offline, suspended, busy]) expect(ids).not.toContain(String(w._id));

    const notification = await Notification.findOne({ userId: near._id });
    expect(notification.title).toBe('Nouvelle demande près de vous');
    expect(notification.message).toMatch(/^Déneigement à 0 km/);

    // Deuxieme vague : personne n'est prevenu deux fois
    expect(await notifyNearbyWorkers(job)).toBe(0);
    expect(await Notification.countDocuments({ userId: near._id })).toBe(1);
  });

  it('skips workers missing the required equipment', async () => {
    await worker();
    const equipped = await worker({ equipmentList: ['shovel', 'brush', 'snow_blower'] });
    const job = await paidJob({ snowDepthCm: 25 });

    await notifyNearbyWorkers(job);

    expect(await notifiedIds('urgentRequest', job._id)).toEqual([String(equipped._id)]);
  });

  it('does nothing for an unpaid or already taken job', async () => {
    const w = await worker();
    expect(await notifyNearbyWorkers(await paidJob({ paymentStatus: 'pending' }))).toBe(0);
    expect(await notifyNearbyWorkers(await paidJob({ status: 'assigned', workerId: w._id }))).toBe(0);
  });
});

describe('alertUnassignedReservations', () => {
  const minutes = (n) => new Date(Date.now() + n * 60 * 1000);

  /** Reservation creee il y a `ageMin` minutes, heure limite dans `deadlineMin`. */
  const jobAged = async (ageMin, deadlineMin, overrides = {}) => {
    const job = await paidJob({
      departureTime: minutes(deadlineMin + 30),
      deadlineTime: minutes(deadlineMin),
      ...overrides,
    });
    await Reservation.collection.updateOne({ _id: job._id }, { $set: { createdAt: minutes(-ageMin) } });
    return job;
  };

  it('tells the client once when nobody accepted as the deadline nears', async () => {
    const job = await jobAged(20, 40);
    const lateWorker = await worker();

    expect(await alertUnassignedReservations()).toBe(1);

    const alert = await Notification.findOne({ userId: job.userId, type: 'searchingWorker' });
    expect(alert.title).toBe('Nous cherchons encore un déneigeur');
    expect(alert.message).toContain('remboursée en entier');
    expect(String(alert.reservationId)).toBe(String(job._id));
    // Relance des deneigeurs en meme temps
    expect(await notifiedIds('urgentRequest', job._id)).toEqual([String(lateWorker._id)]);

    expect(await alertUnassignedReservations()).toBe(0);
  });

  it('waits for workers to answer and for the deadline to near', async () => {
    await jobAged(5, 40); // trop recente
    await jobAged(20, 180); // heure limite encore loin
    const w = await worker();
    await jobAged(20, 40, { status: 'assigned', workerId: w._id }); // deja prise

    expect(await alertUnassignedReservations()).toBe(0);
  });
});

describe('expired jobs without a worker', () => {
  const { processExpiredJobs } = require('../services/expiredJobsService');

  it('cancels and refunds an unassigned job as soon as its deadline passes', async () => {
    const w = await worker();
    const unassigned = await paidJob({
      departureTime: new Date(Date.now() + 25 * 60 * 1000),
      deadlineTime: new Date(Date.now() - 5 * 60 * 1000),
    });
    const assigned = await paidJob({
      status: 'assigned',
      workerId: w._id,
      departureTime: new Date(Date.now() + 25 * 60 * 1000),
      deadlineTime: new Date(Date.now() - 5 * 60 * 1000),
    });

    await processExpiredJobs();

    const cancelled = await Reservation.findById(unassigned._id);
    expect(cancelled.status).toBe('cancelled');
    expect(cancelled.cancelReason).toMatch(/Aucun déneigeur/);
    // Le deneigeur assigne garde ses 30 minutes de grace
    expect((await Reservation.findById(assigned._id)).status).toBe('assigned');
  });
});
