const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

let mongoServer;

// Setup avant tous les tests
beforeAll(async () => {
  // Démarrer MongoDB en mémoire
  // Machine chargee (tests de l'app en parallele) : laisser le temps a
  // MongoDB de demarrer plutot que d'echouer apres 10 s
  mongoServer = await MongoMemoryServer.create({ instance: { launchTimeout: 60000 } });
  const mongoUri = mongoServer.getUri();

  // Configurer les variables d'environnement pour les tests
  process.env.NODE_ENV = 'test';
  process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing-purposes-only';
  process.env.MONGODB_URI = mongoUri;
  process.env.STRIPE_SECRET_KEY = 'sk_test_fake_key_for_testing';
  process.env.STRIPE_PUBLISHABLE_KEY = 'pk_test_fake_key_for_testing';

  // Connecter à MongoDB
  await mongoose.connect(mongoUri);

  // Attendre les index (2dsphere pour les recherches par distance) : sinon
  // une recherche peut arriver avant qu'ils existent et echouer au hasard
  await Promise.all(Object.values(mongoose.models).map((model) => model.init()));
}, 90000);

// Nettoyer après chaque test
afterEach(async () => {
  // Supprimer toutes les collections
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});

// Cleanup après tous les tests
afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

// Supprimer les logs pendant les tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};
