const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

let mongoServer;

// Setup avant tous les tests
beforeAll(async () => {
  // Démarrer MongoDB en mémoire
  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();

  // Configurer les variables d'environnement pour les tests
  process.env.NODE_ENV = 'test';
  process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing-purposes-only';
  process.env.MONGODB_URI = mongoUri;
  process.env.STRIPE_SECRET_KEY = 'sk_test_fake_key_for_testing';
  process.env.STRIPE_PUBLISHABLE_KEY = 'pk_test_fake_key_for_testing';

  // Connecter à MongoDB
  await mongoose.connect(mongoUri);
});

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
