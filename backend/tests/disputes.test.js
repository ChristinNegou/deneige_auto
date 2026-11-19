const request = require('supertest');
const express = require('express');
const Notification = require('../models/Notification');
const Dispute = require('../models/Dispute');
const Reservation = require('../models/Reservation');
const {
  createTestUser,
  createTestWorker,
  createTestAdmin,
  createTestVehicle,
  createTestReservation,
  generateAuthToken,
} = require('./helpers');

jest.mock('stripe');

const createApp = () => {
  const app = express();
  app.use(express.json());
  app.use('/api/disputes', require('../routes/disputes'));
  return app;
};

describe('Dispute flow (client report, worker response, admin decision)', () => {
  let app;
  let client;
  let worker;
  let admin;
  let vehicle;

  beforeAll(() => {
    app = createApp();
  });

  beforeEach(async () => {
    client = await createTestUser();
    worker = await createTestWorker();
    admin = await createTestAdmin();
    vehicle = await createTestVehicle(client._id);
  });

  const auth = (user) => ({ Authorization: `Bearer ${generateAuthToken(user)}` });

  it('lets the client report a no-show on a job marked completed', async () => {
    const reservation = await createTestReservation(client._id, vehicle._id, {
      status: 'completed',
      workerId: worker._id,
      completedAt: new Date(Date.now() - 30 * 60 * 1000),
      paymentStatus: 'paid',
    });

    const res = await request(app)
      .post(`/api/disputes/report-no-show/${reservation._id}`)
      .set(auth(client))
      .send({ description: 'Personne n’est venu, la voiture est encore enneigée.' });

    expect(res.status).toBe(201);
    const notified = await Notification.find({ userId: worker._id });
    expect(notified.length).toBeGreaterThan(0);
    // La photo "apres" doit etre examinee : pas de remboursement automatique
    const dispute = await Dispute.findById(res.body.dispute.id);
    expect(dispute.status).not.toBe('resolved');
  });

  it('refuses a no-show report more than 24 h after completion', async () => {
    const reservation = await createTestReservation(client._id, vehicle._id, {
      status: 'completed',
      workerId: worker._id,
      completedAt: new Date(Date.now() - 30 * 60 * 60 * 1000),
    });

    const res = await request(app)
      .post(`/api/disputes/report-no-show/${reservation._id}`)
      .set(auth(client))
      .send({});

    expect(res.status).toBe(400);
  });

  it('still resolves at once when the worker never set off', async () => {
    const reservation = await createTestReservation(client._id, vehicle._id, {
      status: 'assigned',
      workerId: worker._id,
      departureTime: new Date(Date.now() - 60 * 60 * 1000),
      deadlineTime: new Date(Date.now() - 90 * 60 * 1000),
      paymentStatus: 'paid',
      paymentIntentId: 'pi_test123',
    });

    const res = await request(app)
      .post(`/api/disputes/report-no-show/${reservation._id}`)
      .set(auth(client))
      .send({});

    expect(res.status).toBe(201);
    expect(res.body.dispute.autoResolutionEligible).toBe(true);
  });

  it('takes back the worker share when a refund is granted against him', async () => {
    const stripe = require('stripe')();
    stripe.refunds.create.mockResolvedValue({ id: 're_dispute', status: 'succeeded' });
    stripe.transfers.createReversal.mockResolvedValue({ id: 'trr_dispute' });
    const reservation = await createTestReservation(client._id, vehicle._id, {
      status: 'completed',
      workerId: worker._id,
      completedAt: new Date(),
      paymentStatus: 'paid',
      paymentIntentId: 'pi_test123',
      totalPrice: 40,
      payout: { status: 'paid', workerAmount: 30, stripeTransferId: 'tr_job_dispute' },
    });

    const created = await request(app)
      .post('/api/disputes')
      .set(auth(client))
      .send({
        reservationId: reservation._id.toString(),
        type: 'quality_issue',
        description: 'Le pare-brise est encore couvert de glace.',
      });
    const disputeId = created.body.dispute?._id || created.body.dispute?.id;

    const resolved = await request(app)
      .post(`/api/disputes/${disputeId}/resolve`)
      .set(auth(admin))
      .send({ decision: 'favor_claimant', refundAmount: 20, notes: 'Travail incomplet.' });
    expect(resolved.status).toBe(200);

    // 75 % des 20 $ rembourses sont repris sur le virement du deneigeur
    expect(stripe.transfers.createReversal).toHaveBeenCalledWith(
      'tr_job_dispute', expect.objectContaining({ amount: 1500 }), expect.any(Object));
    const saved = await Reservation.findById(reservation._id);
    expect(saved.payout.reversedAmount).toBe(15);
  });

  it('notifies everyone along a general dispute', async () => {
    const reservation = await createTestReservation(client._id, vehicle._id, {
      status: 'completed',
      workerId: worker._id,
      completedAt: new Date(),
      paymentStatus: 'paid',
      paymentIntentId: 'pi_test123',
    });

    const created = await request(app)
      .post('/api/disputes')
      .set(auth(client))
      .send({
        reservationId: reservation._id.toString(),
        type: 'quality_issue',
        description: 'Le pare-brise est encore couvert de glace.',
      });
    expect(created.status).toBe(201);
    const disputeId = created.body.dispute?._id || created.body.dispute?.id;
    expect(await Notification.countDocuments({ userId: worker._id })).toBeGreaterThan(0);

    const responded = await request(app)
      .post(`/api/disputes/${disputeId}/respond`)
      .set(auth(worker))
      .send({ text: 'J’ai gratté toutes les vitres, voici ma version des faits.' });
    expect(responded.status).toBe(200);
    expect(await Notification.countDocuments({ userId: client._id })).toBeGreaterThan(0);

    const resolved = await request(app)
      .post(`/api/disputes/${disputeId}/resolve`)
      .set(auth(admin))
      .send({ decision: 'favor_respondent', notes: 'Photos du déneigeur concluantes.' });
    expect(resolved.status).toBe(200);
    expect((await Dispute.findById(disputeId)).status).toBe('resolved');

    // Les deux parties sont prevenues de la decision
    const decisionNotes = await Notification.find({
      userId: { $in: [client._id, worker._id] },
      createdAt: { $gte: new Date(Date.now() - 60 * 1000) },
    });
    const recipients = new Set(decisionNotes.map((n) => String(n.userId)));
    expect(recipients.has(String(client._id))).toBe(true);
    expect(recipients.has(String(worker._id))).toBe(true);
  });

  it('keeps the worker photos with the response, for the admin', async () => {
    const reservation = await createTestReservation(client._id, vehicle._id, {
      status: 'completed',
      workerId: worker._id,
      completedAt: new Date(),
    });
    const created = await request(app)
      .post('/api/disputes')
      .set(auth(client))
      .send({
        reservationId: reservation._id.toString(),
        type: 'incomplete_work',
        description: 'Les roues ne sont pas dégagées du tout.',
      });
    const disputeId = created.body.dispute?._id || created.body.dispute?.id;

    // Preuve ajoutee avant la reponse, puis reponse avec une autre photo
    const evidence = await request(app)
      .post(`/api/disputes/${disputeId}/evidence`)
      .set(auth(worker))
      .send({ photos: ['https://img.test/avant.jpg'] });
    expect(evidence.status).toBe(200);

    const responded = await request(app)
      .post(`/api/disputes/${disputeId}/respond`)
      .set(auth(worker))
      .send({
        text: 'Les quatre roues ont été dégagées, voir les photos jointes.',
        photos: ['https://img.test/apres.jpg'],
      });
    expect(responded.status).toBe(200);

    const saved = await Dispute.findById(disputeId);
    expect(saved.response.photos.map((p) => p.url)).toEqual([
      'https://img.test/avant.jpg',
      'https://img.test/apres.jpg',
    ]);
    expect(saved.evidence.photos).toHaveLength(0);

    const asAdmin = await request(app).get(`/api/disputes/${disputeId}`).set(auth(admin));
    expect(asAdmin.body.dispute.response.photos).toHaveLength(2);
  });

  it('does not show the internal AI analysis to the parties', async () => {
    const reservation = await createTestReservation(client._id, vehicle._id, {
      status: 'completed',
      workerId: worker._id,
      completedAt: new Date(),
    });
    const created = await request(app)
      .post('/api/disputes')
      .set(auth(client))
      .send({
        reservationId: reservation._id.toString(),
        type: 'other',
        description: 'Une description suffisamment longue.',
      });
    const disputeId = created.body.dispute?._id || created.body.dispute?.id;
    await Dispute.updateOne({ _id: disputeId }, { aiAnalysis: { reasoning: 'interne', analyzedAt: new Date() } });

    const asClient = await request(app).get(`/api/disputes/${disputeId}`).set(auth(client));
    expect(asClient.body.dispute.aiAnalysis).toBeUndefined();
  });
});
