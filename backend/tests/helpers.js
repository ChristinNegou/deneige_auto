const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Vehicle = require('../models/Vehicle');
const Reservation = require('../models/Reservation');
const mongoose = require('mongoose');

/**
 * Crée un utilisateur de test
 */
const createTestUser = async (overrides = {}) => {
  const defaultUser = {
    email: `test${Date.now()}@example.com`,
    password: 'Test123456!',
    firstName: 'Test',
    lastName: 'User',
    phoneNumber: '+15141234567',
    role: 'client',
    isPhoneVerified: true,
    ...overrides,
  };

  const user = await User.create(defaultUser);
  return user;
};

/**
 * Crée un déneigeur de test
 */
const createTestWorker = async (overrides = {}) => {
  const worker = await createTestUser({
    role: 'snowWorker',
    workerProfile: {
      isAvailable: true,
      currentLocation: {
        type: 'Point',
        coordinates: [-73.5673, 45.5017], // Montreal
      },
      equipmentList: ['shovel', 'brush', 'ice_scraper'],
      maxActiveJobs: 3,
      vehicleType: 'car',
      stripeConnectId: 'acct_test123',
      stripeConnectStatus: 'active',
    },
    ...overrides,
  });
  return worker;
};

/**
 * Crée un admin de test
 */
const createTestAdmin = async (overrides = {}) => {
  return createTestUser({
    role: 'admin',
    ...overrides,
  });
};

/**
 * Crée un véhicule de test
 */
const createTestVehicle = async (userId, overrides = {}) => {
  const defaultVehicle = {
    userId,
    make: 'Toyota',
    model: 'Camry',
    year: 2022,
    color: 'Noir',
    licensePlate: 'ABC123',
    size: 'sedan',
    ...overrides,
  };

  const vehicle = await Vehicle.create(defaultVehicle);
  return vehicle;
};

/**
 * Crée une réservation de test
 */
const createTestReservation = async (userId, vehicleId, overrides = {}) => {
  const defaultReservation = {
    userId,
    vehicle: vehicleId,
    customLocation: '123 Rue Test, Montreal',
    departureTime: new Date(Date.now() + 2 * 60 * 60 * 1000), // Dans 2 heures
    deadlineTime: new Date(Date.now() + 4 * 60 * 60 * 1000), // Dans 4 heures
    status: 'pending',
    basePrice: 25,
    totalPrice: 25,
    paymentMethod: 'card',
    paymentStatus: 'pending',
    location: {
      type: 'Point',
      coordinates: [-73.5673, 45.5017],
      address: '123 Rue Test, Montreal',
    },
    ...overrides,
  };

  const reservation = await Reservation.create(defaultReservation);
  return reservation;
};

/**
 * Génère un token JWT valide pour un utilisateur
 */
const generateAuthToken = (user) => {
  return jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );
};

/**
 * Génère des headers d'authentification
 */
const getAuthHeaders = (user) => {
  const token = generateAuthToken(user);
  return {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
};

/**
 * Nettoie la base de données
 */
const cleanDatabase = async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
};

/**
 * Génère un ObjectId valide
 */
const generateObjectId = () => new mongoose.Types.ObjectId();

module.exports = {
  createTestUser,
  createTestWorker,
  createTestAdmin,
  createTestVehicle,
  createTestReservation,
  generateAuthToken,
  getAuthHeaders,
  cleanDatabase,
  generateObjectId,
};
