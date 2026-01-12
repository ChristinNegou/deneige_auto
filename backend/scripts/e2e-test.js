/**
 * E2E Test Script - Deneige Auto
 * Tests the complete flow: reservation → payment → worker accepts → completes → payout
 */

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const https = require('https');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const API_HOST = 'deneigeauto-production.up.railway.app';

function apiRequest(method, path, token, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: API_HOST,
      path: '/api' + path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': 'Bearer ' + token })
      }
    };

    const req = https.request(options, res => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function runE2ETest() {
  console.log('========================================');
  console.log('   E2E TEST - DENEIGE AUTO');
  console.log('========================================\n');

  // Step 1: Login as client
  console.log('STEP 1: Login as client (christiannegou@yahoo.com)');
  const clientLogin = await apiRequest('POST', '/auth/login', null, {
    email: 'christiannegou@yahoo.com',
    password: 'tata1234'
  });

  if (!clientLogin.data.token) {
    console.log('❌ Client login failed:', clientLogin.data.message);
    return;
  }
  console.log('✅ Client logged in successfully');
  console.log('   User ID:', clientLogin.data.user.id);
  const clientToken = clientLogin.data.token;

  // Step 2: Get client's vehicles
  console.log('\nSTEP 2: Get client vehicles');
  const vehicles = await apiRequest('GET', '/vehicles', clientToken);
  console.log('   Vehicles found:', vehicles.data.vehicles?.length || 0);

  let vehicleId;
  if (vehicles.data.vehicles && vehicles.data.vehicles.length > 0) {
    vehicleId = vehicles.data.vehicles[0]._id;
    console.log('✅ Using vehicle:', vehicles.data.vehicles[0].make, vehicles.data.vehicles[0].model);
  } else {
    console.log('   Creating test vehicle...');
    const newVehicle = await apiRequest('POST', '/vehicles', clientToken, {
      make: 'Toyota',
      model: 'Camry',
      year: 2022,
      color: 'Bleu',
      licensePlate: 'TEST123'
    });
    if (newVehicle.data.vehicle) {
      vehicleId = newVehicle.data.vehicle._id;
      console.log('✅ Vehicle created:', vehicleId);
    } else {
      console.log('❌ Failed to create vehicle:', newVehicle.data.message);
      return;
    }
  }

  // Step 3: Create reservation
  console.log('\nSTEP 3: Create reservation');
  const departureTime = new Date(Date.now() + 2 * 60 * 60 * 1000); // 2 hours from now
  const deadlineTime = new Date(Date.now() + 1.5 * 60 * 60 * 1000); // 1.5 hours from now

  const reservation = await apiRequest('POST', '/reservations', clientToken, {
    vehicleId: vehicleId,
    latitude: 46.3432,
    longitude: -72.5476,
    address: '123 Rue Test, Trois-Rivières, QC',
    customLocation: 'Stationnement principal',
    departureTime: departureTime.toISOString(),
    deadlineTime: deadlineTime.toISOString(),
    snowDepthCm: 15,
    serviceOptions: ['windowScraping'],
    totalPrice: 25.00,
    paymentMethod: 'card'
  });

  if (!reservation.data.reservation) {
    console.log('❌ Reservation failed:', reservation.data.message);
    console.log('   Full response:', JSON.stringify(reservation.data, null, 2));
    return;
  }

  const reservationId = reservation.data.reservation._id || reservation.data.reservation.id;
  console.log('✅ Reservation created:', reservationId);
  console.log('   Total price:', reservation.data.reservation.totalPrice, '$');
  console.log('   Status:', reservation.data.reservation.status);
  console.log('   Payment status:', reservation.data.reservation.paymentStatus);

  // Step 4: Get payment methods
  console.log('\nSTEP 4: Get payment methods');
  const paymentMethods = await apiRequest('GET', '/payments/payment-methods', clientToken);
  console.log('   Payment methods found:', paymentMethods.data.paymentMethods?.length || 0);

  if (!paymentMethods.data.paymentMethods || paymentMethods.data.paymentMethods.length === 0) {
    console.log('❌ No payment methods found. Client needs to add a card first.');
    console.log('   Reservation created but cannot proceed with payment.');
    console.log('   Reservation ID:', reservationId);
    return;
  }

  const paymentMethodId = paymentMethods.data.paymentMethods[0].id;
  console.log('✅ Using payment method:', paymentMethodId);

  // Step 5: Create payment intent
  console.log('\nSTEP 5: Create payment intent');
  const totalPrice = reservation.data.reservation.totalPrice;
  const paymentIntent = await apiRequest('POST', '/payments/create-intent', clientToken, {
    reservationId: reservationId,
    amount: totalPrice
  });

  if (!paymentIntent.data.clientSecret) {
    console.log('❌ Payment intent failed:', paymentIntent.data.message);
    console.log('   Full response:', JSON.stringify(paymentIntent.data, null, 2));
    return;
  }
  console.log('✅ Payment intent created');
  console.log('   Payment Intent ID:', paymentIntent.data.paymentIntentId);

  // Step 6: Confirm payment via Stripe API
  console.log('\nSTEP 6: Confirm payment via Stripe');
  try {
    const confirmedPayment = await stripe.paymentIntents.confirm(
      paymentIntent.data.paymentIntentId,
      {
        payment_method: paymentMethodId,
        return_url: 'https://deneigeauto-production.up.railway.app/payment-complete'
      }
    );
    console.log('✅ Stripe payment confirmed:', confirmedPayment.status);

    if (confirmedPayment.status === 'requires_action') {
      console.log('⚠️  Payment requires 3D Secure - skipping for test');
      console.log('   In production, user would complete 3DS on their device');
    }
  } catch (stripeErr) {
    console.log('❌ Stripe confirmation failed:', stripeErr.message);
    return;
  }

  // Call our confirm endpoint to update the reservation
  console.log('\nSTEP 6b: Update reservation via API');
  const confirm = await apiRequest('POST', '/payments/confirm', clientToken, {
    reservationId: reservationId,
    paymentIntentId: paymentIntent.data.paymentIntentId
  });

  console.log('   API confirmation:', confirm.data.success ? '✅ Success' : '❌ ' + confirm.data.message);

  // Check reservation status
  const resCheck = await apiRequest('GET', '/reservations/' + reservationId, clientToken);
  console.log('   Reservation payment status:', resCheck.data.reservation?.paymentStatus);

  if (resCheck.data.reservation?.paymentStatus !== 'paid') {
    console.log('⚠️  Payment not confirmed yet. Webhook may process it async.');
  }

  console.log('\n   Waiting 3 seconds for webhook processing...\n');
  await new Promise(r => setTimeout(r, 3000));

  // Step 7: Login as worker
  console.log('STEP 7: Login as worker (test@gmail.com)');
  const workerLogin = await apiRequest('POST', '/auth/login', null, {
    email: 'test@gmail.com',
    password: 'tata1234'
  });

  if (!workerLogin.data.token) {
    console.log('❌ Worker login failed:', workerLogin.data.message);
    return;
  }
  console.log('✅ Worker logged in successfully');
  const workerToken = workerLogin.data.token;

  // Step 8: Accept job
  console.log('\nSTEP 8: Accept job');
  const accept = await apiRequest('POST', '/workers/jobs/' + reservationId + '/accept', workerToken);
  console.log('   Accept result:', accept.data.success ? '✅ Accepted' : '❌ ' + accept.data.message);

  if (!accept.data.success) {
    console.log('   Full response:', JSON.stringify(accept.data, null, 2));
  }

  // Step 9: Start job
  console.log('\nSTEP 9: Start job');
  const start = await apiRequest('PATCH', '/workers/jobs/' + reservationId + '/start', workerToken);
  console.log('   Start result:', start.data.success ? '✅ Started' : '❌ ' + start.data.message);

  // Step 10: Complete job
  console.log('\nSTEP 10: Complete job');
  const complete = await apiRequest('PATCH', '/reservations/' + reservationId + '/complete', workerToken);
  console.log('   Complete result:', complete.data.success ? '✅ Completed' : '❌ ' + complete.data.message);

  if (complete.data.payout) {
    console.log('\n   === PAYOUT INFO ===');
    console.log('   Worker amount:', complete.data.payout.workerAmount, '$');
    console.log('   Platform fee:', complete.data.payout.platformFee, '$');
    console.log('   Payout status:', complete.data.payout.status);
    if (complete.data.payout.transfer) {
      if (complete.data.payout.transfer.success) {
        console.log('   Transfer: ✅', complete.data.payout.transfer.transferId);
      } else {
        console.log('   Transfer: ❌', complete.data.payout.transfer.error);
      }
    }
  }

  // Final check
  console.log('\nSTEP 11: Final reservation check');
  const finalCheck = await apiRequest('GET', '/reservations/' + reservationId, clientToken);
  if (finalCheck.data.reservation) {
    const r = finalCheck.data.reservation;
    console.log('   Status:', r.status);
    console.log('   Payment status:', r.paymentStatus);
    console.log('   Payout status:', r.payout?.status);
    console.log('   Payout transfer ID:', r.payout?.stripeTransferId || 'N/A');
  }

  console.log('\n========================================');
  console.log('   E2E TEST COMPLETED');
  console.log('========================================');
}

runE2ETest().catch(err => {
  console.error('Test failed with error:', err);
  process.exit(1);
});
