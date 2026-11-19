const request = require('supertest');
const express = require('express');
const SupportRequest = require('../models/SupportRequest');
const ParkingSpot = require('../models/ParkingSpot');
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
  app.use('/api/messages', require('../routes/messages'));
  app.use('/api/support', require('../routes/support'));
  app.use('/api/ai', require('../routes/aiFeatures'));
  app.use('/api/parking-spots', require('../routes/parking-spots'));
  return app;
};

let seq = 0;
const email = (p) => `${p}${++seq}@example.com`;
const auth = (user) => ({ Authorization: `Bearer ${generateAuthToken(user)}` });

describe('Messages, support, IA et places', () => {
  let app;
  let client;
  let worker;
  let vehicle;

  beforeAll(() => {
    app = createApp();
  });

  beforeEach(async () => {
    client = await createTestUser({ email: email('c') });
    worker = await createTestWorker({ email: email('w') });
    vehicle = await createTestVehicle(client._id);
  });

  it('refuse proprement un message avant qu’un déneigeur accepte', async () => {
    const pending = await createTestReservation(client._id, vehicle._id, { status: 'pending' });
    const res = await request(app)
      .post(`/api/messages/${pending._id}`)
      .set(auth(client))
      .send({ content: 'Bonjour' });
    expect(res.status).toBe(400);
  });

  it('envoie un message et prévient le destinataire', async () => {
    const Notification = require('../models/Notification');
    const job = await createTestReservation(client._id, vehicle._id, { status: 'assigned', workerId: worker._id });
    const res = await request(app)
      .post(`/api/messages/${job._id}`)
      .set(auth(client))
      .send({ content: 'La voiture est derrière le bâtiment.' });
    expect(res.status).toBe(201);
    expect(await Notification.countDocuments({ userId: worker._id, type: 'newMessage' })).toBe(1);
  });

  it('ne montre jamais les notes internes du support à l’utilisateur', async () => {
    const admin = await createTestAdmin({ email: email('admin') });
    const ticket = await SupportRequest.create({
      userId: client._id,
      userEmail: client.email,
      userName: 'Client Test',
      subject: 'question',
      message: 'Comment modifier ma réservation ?',
      adminNotes: 'Client difficile, déjà remboursé une fois',
    });

    await request(app)
      .post(`/api/support/requests/${ticket._id}/respond`)
      .set(auth(admin))
      .send({ message: 'Ouvrez la réservation puis touchez Modifier.', sendNotification: true });

    const mine = await request(app).get('/api/support/my-requests').set(auth(client));
    expect(mine.status).toBe(200);
    const body = JSON.stringify(mine.body);
    expect(body).not.toContain('Client difficile');
    expect(mine.body.data[0].responses[0].message).toBe('Ouvrez la réservation puis touchez Modifier.');
    expect((await SupportRequest.findById(ticket._id)).adminNotes).toBe('Client difficile, déjà remboursé une fois');
  });

  it('laisse un déneigeur demander l’analyse de ses photos, pas de celles des autres', async () => {
    const mine = await createTestReservation(client._id, vehicle._id, { status: 'completed', workerId: worker._id });
    const other = await createTestWorker({ email: email('other') });
    const theirs = await createTestReservation(client._id, vehicle._id, { status: 'completed', workerId: other._id });

    const allowed = await request(app).post(`/api/ai/analyze-photos/${mine._id}`).set(auth(worker));
    expect(allowed.status).not.toBe(403);
    const refused = await request(app).post(`/api/ai/analyze-photos/${theirs._id}`).set(auth(worker));
    expect(refused.status).toBe(403);
  });

  it('ne révèle pas les résidents attitrés des places', async () => {
    const resident = await createTestUser({ email: email('resident'), firstName: 'Résident' });
    await ParkingSpot.create({ spotNumber: 'A1', level: 'outdoor', assignedTo: resident._id });

    const res = await request(app).get('/api/parking-spots').set(auth(client));
    expect(res.status).toBe(200);
    expect(JSON.stringify(res.body)).not.toContain(resident.email);
    expect(res.body.parkingSpots[0].assignedTo).toBeUndefined();
  });
});
