const request = require('supertest');
const express = require('express');
const Reservation = require('../models/Reservation');
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

      expect(res.status).toBe(400);
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
});
