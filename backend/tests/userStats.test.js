const request = require('supertest');
const express = require('express');
const {
  createTestUser,
  createTestWorker,
  createTestAdmin,
  createTestVehicle,
  createTestReservation,
  generateAuthToken,
} = require('./helpers');
const { cityFromAddress } = require('../services/userStatsService');

jest.mock('stripe');

const createApp = () => {
  const app = express();
  app.use(express.json());
  app.use('/api/admin', require('../routes/admin'));
  return app;
};

describe('cityFromAddress', () => {
  it('lit la ville des formats utilises par l\'app', () => {
    expect(cityFromAddress('3746 Boulevard Jean-XXIII, Trois-Rivières, Canada')).toBe('Trois-Rivières');
    expect(cityFromAddress('3750 Boulevard Jean-XXIII, Trois-Rivières, Québec G8Z 3X4')).toBe('Trois-Rivières');
    expect(cityFromAddress('1234 Rue des Forges, Trois-Rivières')).toBe('Trois-Rivières');
    expect(cityFromAddress('10 Rue Sherbrooke, Montréal QC H2X 1Y4, Canada')).toBe('Montréal');
  });

  it('retourne null sans partie ville', () => {
    expect(cityFromAddress('Trois-Rivières')).toBeNull();
    expect(cityFromAddress('12 rue X, Canada')).toBeNull();
    expect(cityFromAddress(undefined)).toBeNull();
  });
});

describe('GET /api/admin/stats/users', () => {
  let app;

  beforeAll(() => {
    app = createApp();
  });

  it('compte les inscrits et classe l\'activite par ville', async () => {
    const admin = await createTestAdmin({ email: 'admin@example.com' });
    const marie = await createTestUser({ email: 'marie@example.com', firstName: 'Marie', lastName: 'Tremblay' });
    const paul = await createTestUser({ email: 'paul@example.com', firstName: 'Paul', lastName: 'Roy' });
    await createTestUser({ email: 'sans@example.com' }); // aucun deneigement
    const luc = await createTestWorker({ email: 'luc@example.com', firstName: 'Luc', lastName: 'Gagnon' });

    const v1 = await createTestVehicle(marie._id);
    const v2 = await createTestVehicle(paul._id);
    const tr = { location: { type: 'Point', coordinates: [-72.58, 46.34], address: '1 Rue A, Trois-Rivières, Canada' } };
    const mtl = { location: { type: 'Point', coordinates: [-73.56, 45.5], address: '2 Rue B, Montréal, Québec H2X 1Y4' } };

    await createTestReservation(marie._id, v1._id, { ...tr, status: 'completed', workerId: luc._id, totalPrice: 30, payout: { workerAmount: 22 } });
    await createTestReservation(marie._id, v1._id, { ...tr, status: 'completed', workerId: luc._id, totalPrice: 40, payout: { workerAmount: 30 } });
    await createTestReservation(paul._id, v2._id, { ...mtl, status: 'pending' });

    const res = await request(app)
      .get('/api/admin/stats/users?period=all')
      .set('Authorization', `Bearer ${generateAuthToken(admin)}`);

    expect(res.status).toBe(200);
    const s = res.body.stats;
    expect(s.totals).toEqual({ users: 4, clients: 3, workers: 1 });
    expect(s.newThisMonth).toEqual({ clients: 3, workers: 1 });
    expect(s.clientsWithoutReservation).toBe(1);
    expect(s.signupsByMonth).toHaveLength(12);
    expect(s.signupsByMonth[11]).toMatchObject({ clients: 3, workers: 1 });

    expect(s.cities[0]).toEqual({
      city: 'Trois-Rivières', clients: 1, workers: 1, reservations: 2, completed: 2, revenue: 70,
    });
    expect(s.cities[1]).toMatchObject({ city: 'Montréal', clients: 1, workers: 0, reservations: 1 });

    expect(s.topClients[0]).toMatchObject({ name: 'Marie Tremblay', city: 'Trois-Rivières', reservations: 2, spent: 70 });
    expect(s.topWorkers[0]).toMatchObject({ name: 'Luc Gagnon', city: 'Trois-Rivières', jobs: 2, earnings: 52 });

    // Filtre par ville (sans tenir compte des accents)
    const mtlOnly = await request(app)
      .get('/api/admin/stats/users?period=all&city=montreal')
      .set('Authorization', `Bearer ${generateAuthToken(admin)}`);
    expect(mtlOnly.body.stats.topClients.map((c) => c.name)).toEqual(['Paul Roy']);
    expect(mtlOnly.body.stats.topWorkers).toEqual([]);
  });

  it('est reserve aux admins', async () => {
    const client = await createTestUser({ email: 'client@example.com' });
    const res = await request(app)
      .get('/api/admin/stats/users')
      .set('Authorization', `Bearer ${generateAuthToken(client)}`);
    expect(res.status).toBe(403);
  });
});
