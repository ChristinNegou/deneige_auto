const request = require('supertest');
const express = require('express');
const Reservation = require('../models/Reservation');
const User = require('../models/User');
const Notification = require('../models/Notification');
const {
  createTestUser,
  createTestWorker,
  createTestAdmin,
  createTestVehicle,
  createTestReservation,
  generateAuthToken,
} = require('./helpers');

jest.mock('stripe');
const stripe = require('stripe')();
const { recordPaidTip, recoverWorkerShare, payoutReservation } = require('../services/payoutService');

const createApp = () => {
  const app = express();
  app.use(express.json());
  app.use('/api/workers', require('../routes/workers'));
  app.use('/api/reservations', require('../routes/reservations'));
  app.use('/api/admin', require('../routes/admin'));
  return app;
};

let seq = 0;
const email = (p) => `${p}${++seq}@example.com`;
const auth = (user) => ({ Authorization: `Bearer ${generateAuthToken(user)}` });

describe('Versements aux déneigeurs', () => {
  let app;
  let client;
  let worker;
  let vehicle;

  beforeAll(() => {
    app = createApp();
  });

  beforeEach(async () => {
    stripe.transfers.create.mockImplementation(async (params) => ({ id: `tr_${params.metadata.kind}_${seq}`, amount: params.amount }));
    stripe.transfers.createReversal.mockResolvedValue({ id: 'trr_1' });
    stripe.refunds.create.mockResolvedValue({ id: 're_1', status: 'succeeded' });
    client = await createTestUser({ email: email('client') });
    worker = await createTestWorker({ email: email('worker') });
    vehicle = await createTestVehicle(client._id);
  });

  const jobInProgress = (overrides = {}) => createTestReservation(client._id, vehicle._id, {
    status: 'inProgress',
    workerId: worker._id,
    paymentStatus: 'paid',
    paymentIntentId: `pi_job_${++seq}`,
    totalPrice: 40,
    photos: [{ url: 'https://example.com/after.jpg', type: 'after' }],
    ...overrides,
  });

  describe('fin du déneigement', () => {
    it('verse 75 % du prix une seule fois et compte la part, pas le prix', async () => {
      const job = await jobInProgress();

      const res = await request(app)
        .patch(`/api/workers/jobs/${job._id}/complete`)
        .set(auth(worker));
      expect(res.status).toBe(200);

      expect(stripe.transfers.create).toHaveBeenCalledTimes(1);
      const [params, options] = stripe.transfers.create.mock.calls[0];
      expect(params.amount).toBe(3000);
      expect(options.idempotencyKey).toBe(`payout_job_${job._id}`);

      const saved = await Reservation.findById(job._id);
      expect(saved.payout.status).toBe('paid');
      expect(saved.payout.workerAmount).toBe(30);
      const updated = await User.findById(worker._id);
      expect(updated.workerProfile.totalEarnings).toBe(30);
      expect(await Notification.countDocuments({ userId: worker._id, type: 'paymentReceived' })).toBe(1);

      // Un second passage (webhook, admin) ne verse rien de plus
      await payoutReservation(saved, updated);
      expect(stripe.transfers.create).toHaveBeenCalledTimes(1);
    });

    it('met la part en attente sans compte de paiement, puis l’admin la verse', async () => {
      const noAccount = await createTestWorker({
        email: email('noacct'),
        workerProfile: { ...worker.workerProfile.toObject(), stripeConnectId: null },
      });
      const job = await jobInProgress({ workerId: noAccount._id });

      await request(app).patch(`/api/workers/jobs/${job._id}/complete`).set(auth(noAccount));
      expect((await Reservation.findById(job._id)).payout.status).toBe('pending_account');
      expect(stripe.transfers.create).not.toHaveBeenCalled();

      await User.findByIdAndUpdate(noAccount._id, { 'workerProfile.stripeConnectId': 'acct_new' });
      const admin = await createTestAdmin({ email: email('admin') });
      const res = await request(app)
        .post('/api/admin/finance/process-pending-payouts')
        .set(auth(admin))
        .send({ dryRun: false });

      expect(res.body.summary.succeeded).toBe(1);
      const [params, options] = stripe.transfers.create.mock.calls[0];
      expect(params).toMatchObject({ amount: 3000, destination: 'acct_new' });
      expect(options.idempotencyKey).toBe(`payout_job_${job._id}`);
    });
  });

  describe('pourboire', () => {
    const completed = () => createTestReservation(client._id, vehicle._id, {
      status: 'completed',
      workerId: worker._id,
      paymentStatus: 'paid',
      paymentIntentId: `pi_job_${++seq}`,
      totalPrice: 40,
      completedAt: new Date(),
    });

    it('refuse un pourboire non payé', async () => {
      const job = await completed();
      const res = await request(app)
        .post(`/api/reservations/${job._id}/tip`)
        .set(auth(client))
        .send({ amount: 5 });
      expect(res.status).toBe(402);
      expect(res.body.code).toBe('TIP_PAYMENT_REQUIRED');
      expect(stripe.transfers.create).not.toHaveBeenCalled();
    });

    it('fait payer le client puis verse 100 % du pourboire au déneigeur', async () => {
      const job = await completed();
      stripe.paymentIntents.create.mockResolvedValue({ id: 'pi_tip_1', client_secret: 'secret_tip' });

      const intent = await request(app)
        .post(`/api/reservations/${job._id}/tip/intent`)
        .set(auth(client))
        .send({ amount: 5 });
      expect(intent.status).toBe(200);
      expect(stripe.paymentIntents.create.mock.calls[0][0]).toMatchObject({
        amount: 500,
        metadata: { type: 'tip', reservationId: String(job._id), userId: String(client._id) },
      });

      stripe.paymentIntents.retrieve.mockResolvedValue({
        id: 'pi_tip_1',
        status: 'succeeded',
        amount_received: 500,
        metadata: { type: 'tip', reservationId: String(job._id), userId: String(client._id), amount: '5' },
      });
      const res = await request(app)
        .post(`/api/reservations/${job._id}/tip`)
        .set(auth(client))
        .send({ amount: 5, paymentIntentId: 'pi_tip_1' });
      expect(res.status).toBe(200);

      const saved = await Reservation.findById(job._id);
      expect(saved.tipAmount).toBe(5);
      expect(saved.tipPayout.status).toBe('paid');
      const [params, options] = stripe.transfers.create.mock.calls[0];
      expect(params.amount).toBe(500);
      expect(options.idempotencyKey).toBe(`tip_job_${job._id}`);
      expect((await User.findById(worker._id)).workerProfile.totalTipsReceived).toBe(5);

      // Le webhook du meme paiement n'ajoute rien
      const again = await recordPaidTip(job._id, 5, 'pi_tip_1');
      expect(again).toMatchObject({ ok: true, duplicate: true });
      expect(stripe.transfers.create).toHaveBeenCalledTimes(1);
    });

    it('refuse un paiement qui ne correspond pas au pourboire', async () => {
      const job = await completed();
      stripe.paymentIntents.retrieve.mockResolvedValue({
        id: 'pi_other',
        status: 'succeeded',
        amount_received: 100,
        metadata: { type: 'tip', reservationId: String(job._id), userId: String(client._id) },
      });
      const res = await request(app)
        .post(`/api/reservations/${job._id}/tip`)
        .set(auth(client))
        .send({ amount: 50, paymentIntentId: 'pi_other' });
      expect(res.status).toBe(402);
      expect((await Reservation.findById(job._id)).tipAmount).toBe(0);
    });

    it('rembourse un second pourboire payé en double', async () => {
      const job = await completed();
      await recordPaidTip(job._id, 5, 'pi_first');
      const second = await recordPaidTip(job._id, 5, 'pi_second');
      expect(second).toMatchObject({ ok: false, conflict: true });
    });
  });

  describe('litige perdu par le déneigeur', () => {
    it('annule sa part du virement déjà versé', async () => {
      const job = await createTestReservation(client._id, vehicle._id, {
        status: 'completed',
        workerId: worker._id,
        paymentStatus: 'paid',
        totalPrice: 40,
        payout: { status: 'paid', workerAmount: 30, stripeTransferId: 'tr_job_x' },
      });
      await User.findByIdAndUpdate(worker._id, { 'workerProfile.totalEarnings': 30 });

      const result = await recoverWorkerShare(job, 40, 'Litige');

      expect(result).toMatchObject({ recovered: 30, method: 'transfer_reversal' });
      expect(stripe.transfers.createReversal).toHaveBeenCalledWith(
        'tr_job_x', expect.objectContaining({ amount: 3000 }), expect.any(Object));
      const saved = await Reservation.findById(job._id);
      expect(saved.payout.status).toBe('reversed');
      expect(saved.payout.reversedAmount).toBe(30);
      expect((await User.findById(worker._id)).workerProfile.totalEarnings).toBe(0);
    });

    it('reprend aussi sa part quand l’admin rembourse à la main', async () => {
      const job = await createTestReservation(client._id, vehicle._id, {
        status: 'completed',
        workerId: worker._id,
        paymentStatus: 'paid',
        paymentIntentId: 'pi_admin_refund',
        totalPrice: 40,
        payout: { status: 'paid', workerAmount: 30, stripeTransferId: 'tr_job_admin' },
      });
      const admin = await createTestAdmin({ email: email('admin') });

      const res = await request(app)
        .post(`/api/admin/reservations/${job._id}/refund`)
        .set(auth(admin))
        .send({ amount: 10, reason: 'Geste commercial' });

      expect(res.status).toBe(200);
      expect(res.body.workerShareRecovered).toBe(7.5);
      expect(stripe.transfers.createReversal).toHaveBeenCalledWith(
        'tr_job_admin', expect.objectContaining({ amount: 750 }), expect.any(Object));
    });

    it('réduit ce qui reste à verser quand rien n’est encore parti', async () => {
      const job = await createTestReservation(client._id, vehicle._id, {
        status: 'completed',
        workerId: worker._id,
        paymentStatus: 'paid',
        totalPrice: 40,
        payout: { status: 'pending_account', workerAmount: 30 },
      });

      const partial = await recoverWorkerShare(job, 20, 'Litige');
      expect(partial).toMatchObject({ recovered: 15, method: 'withheld' });
      let saved = await Reservation.findById(job._id);
      expect(saved.payout.workerAmount).toBe(15);

      await recoverWorkerShare(saved, 20, 'Appel');
      saved = await Reservation.findById(job._id);
      expect(saved.payout.status).toBe('cancelled');
      expect(stripe.transfers.createReversal).not.toHaveBeenCalled();
    });
  });
});
