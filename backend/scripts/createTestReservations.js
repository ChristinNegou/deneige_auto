const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: '../.env' });

const User = require('../models/User');
const Vehicle = require('../models/Vehicle');
const Reservation = require('../models/Reservation');

async function createTestReservations() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Create or find test client
    let client = await User.findOne({ email: 'client@test.com' });
    if (!client) {
      const hashedPassword = await bcrypt.hash('Test123!', 10);
      client = new User({
        email: 'client@test.com',
        password: hashedPassword,
        firstName: 'Marie',
        lastName: 'Tremblay',
        phone: '819-555-5678',
        role: 'client',
        addresses: [{
          label: 'Maison',
          street: '1234 Rue des Forges',
          city: 'Trois-Rivières',
          postalCode: 'G9A 1H7',
          isDefault: true
        }]
      });
      await client.save();
      console.log('Test client created: client@test.com / Test123!');
    }

    // Delete old test data
    await Reservation.deleteMany({ userId: client._id });
    await Vehicle.deleteMany({ userId: client._id });
    console.log('Cleaned up old test data');

    // Base coordinates (Trois-Rivières center)
    const baseLat = 46.3432;
    const baseLng = -72.5476;

    // Create test vehicles
    const vehiclesData = [
      { make: 'Honda', model: 'Civic', year: 2020, color: 'Bleu', licensePlate: 'ABC 123', type: 'sedan' },
      { make: 'Toyota', model: 'RAV4', year: 2022, color: 'Noir', licensePlate: 'XYZ 789', type: 'suv' },
      { make: 'Ford', model: 'F-150', year: 2021, color: 'Rouge', licensePlate: 'TRK 456', type: 'truck' },
      { make: 'Subaru', model: 'Outback', year: 2019, color: 'Vert', licensePlate: 'SUB 222', type: 'suv' },
      { make: 'Mazda', model: 'CX-5', year: 2023, color: 'Blanc', licensePlate: 'URG 911', type: 'suv' },
    ];

    const vehicles = [];
    for (const vData of vehiclesData) {
      const vehicle = new Vehicle({
        userId: client._id,
        ...vData,
        isDefault: vehicles.length === 0
      });
      await vehicle.save();
      vehicles.push(vehicle);
      console.log(`Vehicle created: ${vData.make} ${vData.model}`);
    }

    // Create test reservations
    const reservationsData = [
      {
        vehicle: vehicles[0]._id,
        departureTime: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2h from now
        location: {
          type: 'Point',
          coordinates: [baseLng + 0.01, baseLat + 0.005],
          address: '1234 Rue des Forges, Trois-Rivières'
        },
        customLocation: 'Stationnement A-12',
        serviceOptions: ['windowScraping'],
        snowDepthCm: 15,
        basePrice: 15.00,
        totalPrice: 20.00,
        isPriority: false,
        paymentMethod: 'card',
        paymentStatus: 'paid'
      },
      {
        vehicle: vehicles[1]._id,
        departureTime: new Date(Date.now() + 45 * 60 * 1000), // 45 min - URGENT
        location: {
          type: 'Point',
          coordinates: [baseLng - 0.008, baseLat + 0.003],
          address: '567 Boul. des Récollets, Trois-Rivières'
        },
        customLocation: 'Place B-5',
        serviceOptions: ['windowScraping', 'doorDeicing'],
        snowDepthCm: 20,
        basePrice: 23.00,
        totalPrice: 32.20,
        urgencyMultiplier: 1.4,
        isPriority: true,
        paymentMethod: 'card',
        paymentStatus: 'paid'
      },
      {
        vehicle: vehicles[2]._id,
        departureTime: new Date(Date.now() + 3 * 60 * 60 * 1000), // 3h from now
        location: {
          type: 'Point',
          coordinates: [baseLng + 0.02, baseLat - 0.01],
          address: '890 Rue Laviolette, Trois-Rivières'
        },
        customLocation: 'Entrée principale',
        serviceOptions: ['windowScraping', 'wheelClearance'],
        snowDepthCm: 25,
        basePrice: 15.00,
        totalPrice: 24.00,
        isPriority: false,
        paymentMethod: 'card',
        paymentStatus: 'paid'
      },
      {
        vehicle: vehicles[3]._id,
        departureTime: new Date(Date.now() + 1.5 * 60 * 60 * 1000), // 1.5h from now
        location: {
          type: 'Point',
          coordinates: [baseLng - 0.015, baseLat - 0.008],
          address: '2100 Boul. des Chenaux, Trois-Rivières'
        },
        customLocation: 'Stationnement C-22',
        serviceOptions: ['windowScraping', 'doorDeicing', 'wheelClearance'],
        snowDepthCm: 18,
        basePrice: 15.00,
        totalPrice: 27.00,
        isPriority: false,
        paymentMethod: 'card',
        paymentStatus: 'paid'
      },
      {
        vehicle: vehicles[4]._id,
        departureTime: new Date(Date.now() + 30 * 60 * 1000), // 30 min - VERY URGENT
        location: {
          type: 'Point',
          coordinates: [baseLng + 0.005, baseLat + 0.012],
          address: '45 Rue Hart, Trois-Rivières'
        },
        customLocation: 'Stationnement rue',
        serviceOptions: ['windowScraping'],
        snowDepthCm: 12,
        basePrice: 20.00,
        totalPrice: 28.00,
        urgencyMultiplier: 1.4,
        isPriority: true,
        paymentMethod: 'card',
        paymentStatus: 'paid'
      }
    ];

    for (const resData of reservationsData) {
      const deadlineTime = new Date(resData.departureTime.getTime() - 30 * 60 * 1000); // 30 min before departure

      const reservation = new Reservation({
        userId: client._id,
        ...resData,
        deadlineTime,
        status: 'pending'
      });
      await reservation.save();

      const vehicle = vehicles.find(v => v._id.equals(resData.vehicle));
      console.log(`Reservation: ${vehicle.make} ${vehicle.model} - ${resData.location.address.split(',')[0]} ${resData.isPriority ? '🔥 URGENT' : ''}`);
    }

    console.log('\n============================');
    console.log(`✅ Created ${reservationsData.length} test reservations`);
    console.log('============================');
    console.log('Refresh the worker app to see available jobs!');

    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error.message);
    if (error.errors) {
      for (const [key, err] of Object.entries(error.errors)) {
        console.error(`  - ${key}: ${err.message}`);
      }
    }
    process.exit(1);
  }
}

createTestReservations();
