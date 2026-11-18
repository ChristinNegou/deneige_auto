const request = require('supertest');
const express = require('express');
const Reservation = require('../models/Reservation');
const Notification = require('../models/Notification');
const {
  createTestUser,
  createTestWorker,
  createTestVehicle,
  createTestReservation,
  generateAuthToken,
} = require('./helpers');

// Mock Stripe - le mock est dans __mocks__/stripe.js
jest.mock('stripe');

// Créer une app Express pour les tests
const createApp = () => {
  const app = express();
  app.use(express.json());

  const workerRoutes = require('../routes/workers');
  app.use('/api/workers', workerRoutes);

  app.use((err, req, res, next) => {
    res.status(err.statusCode || 500).json({
      success: false,
      message: err.message,
    });
  });

  return app;
};

describe('Worker Routes', () => {
  let app;
  let testWorker;
  let workerToken;

  beforeAll(() => {
    app = createApp();
  });

  beforeEach(async () => {
    testWorker = await createTestWorker();
    workerToken = generateAuthToken(testWorker);
  });

  describe('GET /api/workers/available-jobs', () => {
    it('should return available jobs near worker location', async () => {
      // Créer un client avec une réservation
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);
      await createTestReservation(client._id, vehicle._id, {
        status: 'pending',
        paymentStatus: 'paid',
        location: {
          type: 'Point',
          coordinates: [-73.5673, 45.5017],
          address: 'Montreal',
        },
      });

      const res = await request(app)
        .get('/api/workers/available-jobs')
        .query({ lat: 45.5017, lng: -73.5673, radiusKm: 50 })
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
    });

    it('should return no jobs when the worker is offline', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);
      await createTestReservation(client._id, vehicle._id, {
        status: 'pending',
        paymentStatus: 'paid',
        location: {
          type: 'Point',
          coordinates: [-73.5673, 45.5017],
          address: 'Montreal',
        },
      });
      const offlineWorker = await createTestWorker({
        workerProfile: { ...testWorker.workerProfile.toObject(), isAvailable: false },
      });

      const res = await request(app)
        .get('/api/workers/available-jobs')
        .query({ lat: 45.5017, lng: -73.5673, radiusKm: 50 })
        .set('Authorization', `Bearer ${generateAuthToken(offlineWorker)}`);

      expect(res.status).toBe(200);
      expect(res.body.offline).toBe(true);
      expect(res.body.data).toEqual([]);
    });

    it('should require lat and lng parameters', async () => {
      const res = await request(app)
        .get('/api/workers/available-jobs')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should deny access to non-workers', async () => {
      const client = await createTestUser();
      const clientToken = generateAuthToken(client);

      const res = await request(app)
        .get('/api/workers/available-jobs')
        .query({ lat: 45.5017, lng: -73.5673 })
        .set('Authorization', `Bearer ${clientToken}`);

      expect(res.status).toBe(403);
    });
  });

  describe('GET /api/workers/my-jobs', () => {
    it('should return worker assigned jobs', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);

      // Créer une réservation assignée au worker
      await createTestReservation(client._id, vehicle._id, {
        status: 'assigned',
        workerId: testWorker._id,
      });

      const res = await request(app)
        .get('/api/workers/my-jobs')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBe(1);
    });

    it('should return empty array when no assigned jobs', async () => {
      const res = await request(app)
        .get('/api/workers/my-jobs')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBe(0);
    });
  });

  describe('GET /api/workers/history', () => {
    it('should return completed jobs history', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);

      // Créer des réservations complétées
      await createTestReservation(client._id, vehicle._id, {
        status: 'completed',
        workerId: testWorker._id,
        completedAt: new Date(),
      });

      const res = await request(app)
        .get('/api/workers/history')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBe(1);
    });

    it('should paginate history', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);

      // Créer plusieurs réservations complétées
      for (let i = 0; i < 5; i++) {
        await createTestReservation(client._id, vehicle._id, {
          status: 'completed',
          workerId: testWorker._id,
          completedAt: new Date(),
        });
      }

      const res = await request(app)
        .get('/api/workers/history?page=1&limit=2')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(2);
      expect(res.body.total).toBe(5);
    });
  });

  describe('PATCH /api/workers/availability', () => {
    it('should toggle worker availability', async () => {
      const res = await request(app)
        .patch('/api/workers/availability')
        .set('Authorization', `Bearer ${workerToken}`)
        .send({ isAvailable: false });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.isAvailable).toBe(false);
    });

    it('should set worker as available', async () => {
      const res = await request(app)
        .patch('/api/workers/availability')
        .set('Authorization', `Bearer ${workerToken}`)
        .send({ isAvailable: true });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.isAvailable).toBe(true);
    });
  });

  describe('POST /api/workers/jobs/:id/accept', () => {
    it('should accept an available job', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);
      const reservation = await createTestReservation(client._id, vehicle._id, {
        status: 'pending',
        paymentStatus: 'paid',
      });

      const res = await request(app)
        .post(`/api/workers/jobs/${reservation._id}/accept`)
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      // L'API retourne les données dans data, pas reservation
      expect(res.body.data.status).toBe('assigned');
      expect(res.body.data.workerId.toString()).toBe(testWorker._id.toString());
    });

    it('should not accept a job while the worker is offline', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);
      const reservation = await createTestReservation(client._id, vehicle._id, {
        status: 'pending',
        paymentStatus: 'paid',
      });
      const offlineWorker = await createTestWorker({
        workerProfile: { ...testWorker.workerProfile.toObject(), isAvailable: false },
      });

      const res = await request(app)
        .post(`/api/workers/jobs/${reservation._id}/accept`)
        .set('Authorization', `Bearer ${generateAuthToken(offlineWorker)}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      const unchanged = await Reservation.findById(reservation._id);
      expect(unchanged.status).toBe('pending');
    });

    it('should not accept an already assigned job', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);
      const otherWorker = await createTestWorker();
      const reservation = await createTestReservation(client._id, vehicle._id, {
        status: 'assigned',
        workerId: otherWorker._id,
      });

      const res = await request(app)
        .post(`/api/workers/jobs/${reservation._id}/accept`)
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
    });
  });

  describe('PATCH /api/workers/jobs/:id/start', () => {
    it('should start an assigned job', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);
      const reservation = await createTestReservation(client._id, vehicle._id, {
        status: 'enRoute',
        workerId: testWorker._id,
      });

      const res = await request(app)
        .patch(`/api/workers/jobs/${reservation._id}/start`)
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('inProgress');
    });

    it('should not start a job not assigned to worker', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);
      const otherWorker = await createTestWorker();
      const reservation = await createTestReservation(client._id, vehicle._id, {
        status: 'assigned',
        workerId: otherWorker._id,
      });

      const res = await request(app)
        .patch(`/api/workers/jobs/${reservation._id}/start`)
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/workers/stats', () => {
    it('should return worker statistics', async () => {
      const client = await createTestUser();
      const vehicle = await createTestVehicle(client._id);

      // Créer quelques réservations complétées
      await createTestReservation(client._id, vehicle._id, {
        status: 'completed',
        workerId: testWorker._id,
        completedAt: new Date(),
        totalPrice: 25,
        rating: 5,
      });

      const res = await request(app)
        .get('/api/workers/stats')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      // L'API retourne les stats dans data, pas stats
      expect(res.body.data).toBeDefined();
      expect(res.body.data.today).toBeDefined();
      expect(res.body.data.week).toBeDefined();
      expect(res.body.data.month).toBeDefined();
      expect(res.body.data.allTime).toBeDefined();
    });
  });

  describe('GET /api/workers/profile', () => {
    it('should return worker profile', async () => {
      const res = await request(app)
        .get('/api/workers/profile')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.email).toBe(testWorker.email);
    });
  });

  describe('PUT /api/workers/profile', () => {
    it('should update worker profile', async () => {
      const res = await request(app)
        .put('/api/workers/profile')
        .set('Authorization', `Bearer ${workerToken}`)
        .send({
          vehicleType: 'truck',
          maxActiveJobs: 5,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('PUT /api/workers/location', () => {
    it('should update worker location', async () => {
      const res = await request(app)
        .put('/api/workers/location')
        .set('Authorization', `Bearer ${workerToken}`)
        .send({
          latitude: 45.5088,
          longitude: -73.5878,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('should fail without coordinates', async () => {
      const res = await request(app)
        .put('/api/workers/location')
        .set('Authorization', `Bearer ${workerToken}`)
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe('Assignment rules', () => {
    const TROIS_RIVIERES = [-72.5477, 46.3432];
    const MONTREAL = [-73.5673, 45.5017]; // ~120 km

    const paidJob = async (overrides = {}) => {
      const client = await createTestUser({ email: `c${Math.random()}@example.com` });
      const vehicle = await createTestVehicle(client._id);
      return createTestReservation(client._id, vehicle._id, {
        status: 'pending',
        paymentStatus: 'paid',
        ...overrides,
      });
    };

    const worker = (overrides = {}) => createTestWorker({
      email: `w${Math.random()}@example.com`,
      ...overrides,
      workerProfile: { ...testWorker.workerProfile.toObject(), ...(overrides.workerProfile || {}) },
    });

    const accept = (job, user) => request(app)
      .post(`/api/workers/jobs/${job._id}/accept`)
      .set('Authorization', `Bearer ${generateAuthToken(user)}`);

    const listJobs = (user, [lng, lat], radiusKm = 50) => request(app)
      .get('/api/workers/available-jobs')
      .query({ lat, lng, radiusKm })
      .set('Authorization', `Bearer ${generateAuthToken(user)}`);

    it('gives the job to only one worker when two accept at the same time', async () => {
      const job = await paidJob();
      const other = await worker();

      const results = await Promise.all([accept(job, testWorker), accept(job, other)]);

      expect(results.map((r) => r.status).sort()).toEqual([200, 409]);
      const saved = await Reservation.findById(job._id);
      const winner = results.find((r) => r.status === 200).body.data.workerId._id
        ?? results.find((r) => r.status === 200).body.data.workerId;
      expect(saved.workerId.toString()).toBe(String(winner));
      expect(await Notification.countDocuments({ userId: job.userId, type: 'reservationAssigned' })).toBe(1);
    });

    it('blocks a worker suspended automatically, until the suspension ends', async () => {
      const job = await paidJob();
      const suspended = await worker({ workerProfile: { isSuspended: true } });

      expect((await accept(job, suspended)).status).toBe(403);
      const list = await listJobs(suspended, MONTREAL);
      expect(list.body.suspended).toBe(true);
      expect(list.body.data).toEqual([]);
      const online = await request(app)
        .patch('/api/workers/availability')
        .send({ isAvailable: true })
        .set('Authorization', `Bearer ${generateAuthToken(suspended)}`);
      expect(online.status).toBe(403);

      const ended = await worker({
        workerProfile: { isSuspended: true, suspendedUntil: new Date(Date.now() - 60 * 1000) },
      });
      expect((await accept(job, ended)).status).toBe(200);
    });

    it('never offers a job outside the radius', async () => {
      await paidJob({ location: { type: 'Point', coordinates: MONTREAL, address: '1 Rue A, Montréal' } });

      const near = await listJobs(testWorker, TROIS_RIVIERES, 50);
      expect(near.body.data).toEqual([]);

      // Le rayon demande est plafonne a 100 km
      const huge = await listJobs(testWorker, TROIS_RIVIERES, 5000);
      expect(huge.body.data).toEqual([]);

      const local = await listJobs(testWorker, MONTREAL, 50);
      expect(local.body.data).toHaveLength(1);
    });

    it('neither lists nor accepts an unpaid job', async () => {
      const job = await paidJob({ paymentStatus: 'pending' });

      expect((await listJobs(testWorker, MONTREAL)).body.data).toEqual([]);
      const res = await accept(job, testWorker);
      expect(res.status).toBe(400);
      expect(res.body.code).toBe('JOB_NOT_PAID');
    });

    it('neither lists nor accepts a job whose deadline has passed', async () => {
      const job = await paidJob({
        departureTime: new Date(Date.now() + 10 * 60 * 1000),
        deadlineTime: new Date(Date.now() - 20 * 60 * 1000),
      });

      expect((await listJobs(testWorker, MONTREAL)).body.data).toEqual([]);
      const res = await accept(job, testWorker);
      expect(res.status).toBe(400);
      expect(res.body.code).toBe('JOB_EXPIRED');
    });

    it('refuses a job that needs equipment the worker lacks', async () => {
      const job = await paidJob({ snowDepthCm: 25 }); // souffleuse requise

      const res = await accept(job, testWorker);
      expect(res.status).toBe(400);
      expect(res.body.code).toBe('MISSING_EQUIPMENT');
      expect(res.body.missingEquipment).toContain('snow_blower');
      expect((await Reservation.findById(job._id)).status).toBe('pending');
    });

    it('counts jobs en route toward the active job limit', async () => {
      for (let i = 0; i < 3; i++) {
        await paidJob({ status: 'enRoute', workerId: testWorker._id });
      }
      const job = await paidJob();

      const res = await accept(job, testWorker);
      expect(res.status).toBe(400);
      expect(res.body.code).toBe('TOO_MANY_JOBS');
    });
  });

  describe('Earnings shown to the worker', () => {
    it('counts the worker share (75%) and tips separately', async () => {
      const client = await createTestUser({ email: 'pay-client@example.com' });
      const vehicle = await createTestVehicle(client._id);
      await createTestReservation(client._id, vehicle._id, {
        status: 'completed', paymentStatus: 'paid', workerId: testWorker._id,
        totalPrice: 40, tipAmount: 5, completedAt: new Date(),
      });

      const res = await request(app)
        .get('/api/workers/stats')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.today).toMatchObject({ completed: 1, earnings: 30, tips: 5 });
      expect(res.body.data.allTime).toMatchObject({ completed: 1, earnings: 30, tips: 5 });

      const earnings = await request(app)
        .get('/api/workers/earnings?period=week')
        .set('Authorization', `Bearer ${workerToken}`);
      expect(earnings.body.data.summary.totalEarnings).toBe(30);
      expect(earnings.body.data.daily).toHaveLength(1);
    });

    it('lists completed and cancelled jobs newest first', async () => {
      const client = await createTestUser({ email: 'hist-client@example.com' });
      const vehicle = await createTestVehicle(client._id);
      const hour = 60 * 60 * 1000;
      const old = await createTestReservation(client._id, vehicle._id, {
        status: 'completed', workerId: testWorker._id, completedAt: new Date(Date.now() - 3 * hour),
      });
      const cancelled = await createTestReservation(client._id, vehicle._id, {
        status: 'cancelled', workerId: testWorker._id, cancelledAt: new Date(Date.now() - hour),
      });

      const res = await request(app)
        .get('/api/workers/history')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.map((r) => String(r._id))).toEqual([String(cancelled._id), String(old._id)]);
      expect(res.body.data[0].vehicle.make).toBe('Toyota');
    });
  });
});
