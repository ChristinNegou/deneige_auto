const request = require('supertest');
const express = require('express');
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

  const paymentRoutes = require('../routes/payments');
  const reservationRoutes = require('../routes/reservations');
  app.use('/api/payments', paymentRoutes);
  app.use('/api/reservations', reservationRoutes);

  app.use((err, req, res, next) => {
    res.status(err.statusCode || 500).json({
      success: false,
      message: err.message,
    });
  });

  return app;
};

describe('Payment Routes', () => {
  let app;
  let testUser;
  let authToken;

  beforeAll(() => {
    app = createApp();
  });

  beforeEach(async () => {
    testUser = await createTestUser({
      stripeCustomerId: 'cus_test123',
    });
    authToken = generateAuthToken(testUser);
  });

  describe('GET /api/payments/payment-methods', () => {
    it('should return empty array for user without Stripe customer', async () => {
      const userWithoutStripe = await createTestUser();
      const token = generateAuthToken(userWithoutStripe);

      const res = await request(app)
        .get('/api/payments/payment-methods')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.paymentMethods).toEqual([]);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .get('/api/payments/payment-methods');

      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/payments/payment-methods', () => {
    it('should require authentication', async () => {
      const res = await request(app)
        .post('/api/payments/payment-methods')
        .send({
          paymentMethodId: 'pm_test_new',
          setAsDefault: true,
        });

      expect(res.status).toBe(401);
    });
  });

  describe('DELETE /api/payments/payment-methods/:id', () => {
    it('should delete a payment method', async () => {
      const stripe = require('stripe')();
      stripe.paymentMethods.retrieve.mockResolvedValue({ id: 'pm_test123', customer: 'cus_test123' });
      stripe.paymentMethods.detach.mockResolvedValue({ id: 'pm_test123' });
      const res = await request(app)
        .delete('/api/payments/payment-methods/pm_test123')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('should not delete another client card', async () => {
      const stripe = require('stripe')();
      stripe.paymentMethods.retrieve.mockResolvedValue({ id: 'pm_other', customer: 'cus_someone_else' });
      const res = await request(app)
        .delete('/api/payments/payment-methods/pm_other')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
      expect(stripe.paymentMethods.detach).not.toHaveBeenCalled();
    });
  });

  describe('POST /api/payments/create-intent', () => {
    it('should require authentication', async () => {
      const res = await request(app)
        .post('/api/payments/create-intent')
        .send({
          amount: 25,
          reservationId: 'temp',
        });

      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/reservations/:id/tip', () => {
    it('should refuse a tip the client has not paid', async () => {
      const worker = await createTestWorker();
      const vehicle = await createTestVehicle(testUser._id);
      const reservation = await createTestReservation(testUser._id, vehicle._id, {
        status: 'completed',
        workerId: worker._id,
        completedAt: new Date(),
        paymentStatus: 'paid',
        payout: {
          status: 'paid',
          workerAmount: 18.75,
          platformFee: 6.25,
        },
      });

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/tip`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 5,
        });

      expect(res.status).toBe(402);
      expect(res.body.code).toBe('TIP_PAYMENT_REQUIRED');
    });

    it('should fail with negative tip amount', async () => {
      const worker = await createTestWorker();
      const vehicle = await createTestVehicle(testUser._id);
      const reservation = await createTestReservation(testUser._id, vehicle._id, {
        status: 'completed',
        workerId: worker._id,
        completedAt: new Date(),
      });

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/tip`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: -5,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should fail for non-completed reservation', async () => {
      const worker = await createTestWorker();
      const vehicle = await createTestVehicle(testUser._id);
      const reservation = await createTestReservation(testUser._id, vehicle._id, {
        status: 'pending',
        workerId: worker._id,
      });

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/tip`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 5,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should fail for reservation without worker', async () => {
      const vehicle = await createTestVehicle(testUser._id);
      const reservation = await createTestReservation(testUser._id, vehicle._id, {
        status: 'completed',
        completedAt: new Date(),
      });

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/tip`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 5,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe('removed routes', () => {
    it('no longer lets anyone mark a reservation paid or refund it themselves', async () => {
      const user = await createTestUser({ email: 'removed-routes@example.com' });
      const auth = { Authorization: `Bearer ${generateAuthToken(user)}` };

      const confirm = await request(app).post('/api/payments/confirm').set(auth)
        .send({ paymentIntentId: 'pi_test123', reservationId: '507f1f77bcf86cd799439011' });
      const refund = await request(app).post('/api/payments/refunds').set(auth)
        .send({ reservationId: '507f1f77bcf86cd799439011' });

      const payout = await request(app).post('/api/payments/payouts').set(auth)
        .send({ reservationId: '507f1f77bcf86cd799439011' });
      const refundStatus = await request(app).get('/api/payments/refunds/re_123').set(auth);

      expect(confirm.status).toBe(404);
      expect(refund.status).toBe(404);
      expect(payout.status).toBe(404);
      expect(refundStatus.status).toBe(404);
    });
  });
});
