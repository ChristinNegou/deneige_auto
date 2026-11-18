const request = require('supertest');
const express = require('express');
const User = require('../models/User');

// Pas de vrai SMS : le code est renvoye comme en developpement.
jest.mock('../services/twilioService', () => {
  const actual = jest.requireActual('../services/twilioService');
  return {
    ...actual,
    // Fonction simple : la config jest reinitialise les jest.fn entre les tests.
    sendVerificationCode: async (_phone, code) => ({ success: true, simulated: true, code }),
    isTwilioConfigured: () => false,
  };
});

const createApp = () => {
  const app = express();
  app.use(express.json());
  app.use('/api/phone', require('../routes/phoneVerification'));
  app.use('/api/auth', require('../routes/auth'));
  return app;
};

/** Date AAAA-MM-JJ d'une personne qui a `years` ans aujourd'hui. */
const birthDateForAge = (years) => {
  const d = new Date();
  d.setUTCFullYear(d.getUTCFullYear() - years);
  return d.toISOString().slice(0, 10);
};

const registration = (overrides = {}) => ({
  phoneNumber: '+15145550101',
  email: 'nouveau@example.com',
  password: 'Secret123',
  firstName: 'Marie',
  lastName: 'Tremblay',
  dateOfBirth: '1990-04-12',
  role: 'snowWorker',
  ...overrides,
});

describe('Inscription avec date de naissance', () => {
  let app;

  beforeAll(() => {
    app = createApp();
  });

  it('enregistre la date de naissance a la creation du compte', async () => {
    const sent = await request(app).post('/api/phone/send-code').send(registration());
    expect(sent.status).toBe(200);
    expect(sent.body.devCode).toHaveLength(6);

    const verified = await request(app)
      .post('/api/phone/verify-code')
      .send({ phoneNumber: '+15145550101', code: sent.body.devCode });
    expect(verified.status).toBe(201);
    expect(verified.body.accountCreated).toBe(true);

    const user = await User.findOne({ email: 'nouveau@example.com' });
    expect(user.role).toBe('snowWorker');
    expect(user.dateOfBirth.toISOString().slice(0, 10)).toBe('1990-04-12');
  });

  it('refuse une personne de moins de 18 ans', async () => {
    const res = await request(app)
      .post('/api/phone/send-code')
      .send(registration({ dateOfBirth: birthDateForAge(17) }));
    expect(res.status).toBe(400);
    expect(JSON.stringify(res.body)).toContain('18 ans');
  });

  it('accepte une personne qui a 18 ans aujourd\'hui', async () => {
    const res = await request(app)
      .post('/api/phone/send-code')
      .send(registration({ dateOfBirth: birthDateForAge(18) }));
    expect(res.status).toBe(200);
  });

  it('refuse une date mal formee', async () => {
    const res = await request(app)
      .post('/api/phone/send-code')
      .send(registration({ dateOfBirth: '12/04/1990' }));
    expect(res.status).toBe(400);
  });

  it('accepte encore une inscription sans date (anciennes versions de l\'app)', async () => {
    const { dateOfBirth, ...withoutDate } = registration();
    const res = await request(app).post('/api/phone/send-code').send(withoutDate);    expect(res.status).toBe(200);
  });

  it('refuse un mineur sur /auth/register aussi', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send(registration({ dateOfBirth: birthDateForAge(16) }));
    expect(res.status).toBe(400);
  });
});
