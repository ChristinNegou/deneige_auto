const mongoose = require('mongoose');
require('dotenv').config({ path: '../.env' });

const User = require('../models/User');

async function createTestWorker() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Delete and recreate test worker
    await User.deleteOne({ email: 'worker@test.com' });
    console.log('Deleted existing test worker if any');

    // Create test worker (password will be hashed by User model pre-save hook)
    const worker = new User({
      email: 'worker@test.com',
      password: 'Test123!',
      firstName: 'Jean',
      lastName: 'Déneigeur',
      phone: '819-555-1234',
      role: 'snowWorker',
      workerProfile: {
        isAvailable: true,
        currentLocation: {
          type: 'Point',
          coordinates: [-72.5476, 46.3432] // Trois-Rivières
        },
        preferredZones: [{
          name: 'Trois-Rivières Centre',
          centerLat: 46.3432,
          centerLng: -72.5476,
          radiusKm: 10
        }],
        equipmentList: ['shovel', 'brush', 'ice_scraper'],
        vehicleType: 'car',
        maxActiveJobs: 3,
        totalJobsCompleted: 0,
        totalEarnings: 0,
        totalTipsReceived: 0,
        averageRating: 0,
        totalRatings: 0
      }
    });

    await worker.save();
    console.log('Test worker created successfully!');
    console.log('============================');
    console.log('Email: worker@test.com');
    console.log('Password: Test123!');
    console.log('============================');

    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

createTestWorker();
