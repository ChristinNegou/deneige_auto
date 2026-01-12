/**
 * Test FCM Notifications via Production API
 * Usage: node scripts/test-fcm-api.js [email]
 *
 * Examples:
 *   node scripts/test-fcm-api.js                     # Use default admin account
 *   node scripts/test-fcm-api.js user@email.com     # Send test to specific user
 */

const https = require('https');

const API_HOST = 'deneigeauto-production.up.railway.app';
const ADMIN_EMAIL = 'admin@deneige-auto.com';
const ADMIN_PASSWORD = 'Admin123!';

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

async function testFCMNotifications() {
    const targetEmail = process.argv[2];

    console.log('========================================');
    console.log('   TEST FCM NOTIFICATIONS');
    console.log('========================================\n');

    // Step 1: Login as admin
    console.log('STEP 1: Login as admin');
    const adminLogin = await apiRequest('POST', '/auth/login', null, {
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD
    });

    if (!adminLogin.data.token) {
        console.log('❌ Admin login failed:', adminLogin.data.message);
        console.log('\n   Trying with christiannegou@yahoo.com...');

        // Fallback to christiannegou
        const fallbackLogin = await apiRequest('POST', '/auth/login', null, {
            email: 'christiannegou@yahoo.com',
            password: 'tata1234'
        });

        if (!fallbackLogin.data.token) {
            console.log('❌ Fallback login also failed');
            return;
        }

        if (fallbackLogin.data.user.role !== 'admin') {
            console.log('⚠️  Account is not admin. Run this to promote:');
            console.log('   node scripts/create-admin.js christiannegou@yahoo.com');
            console.log('\n   Then redeploy and run this test again.');
            return;
        }

        adminLogin.data = fallbackLogin.data;
    }

    console.log('✅ Logged in as:', adminLogin.data.user.firstName);
    const token = adminLogin.data.token;
    console.log('   Role:', adminLogin.data.user.role);

    if (adminLogin.data.user.role !== 'admin') {
        console.log('❌ Not an admin account!');
        return;
    }

    // Step 2: Get FCM status for all users
    console.log('\nSTEP 2: Check FCM token status');
    const fcmStatus = await apiRequest('GET', '/admin/notifications/fcm-status', token);

    if (fcmStatus.status === 404) {
        console.log('⚠️  FCM status endpoint not found - deploy pending');
        console.log('   Run: git add . && git commit -m "Add FCM test endpoints" && git push');
        return;
    }

    if (fcmStatus.data.success) {
        const stats = fcmStatus.data.stats;
        console.log('   Total users:', stats.total);
        console.log('   With FCM token:', stats.withFcmToken);
        console.log('   Without FCM token:', stats.withoutFcmToken);

        if (fcmStatus.data.usersWithToken?.length > 0) {
            console.log('\n   Users with FCM tokens:');
            fcmStatus.data.usersWithToken.forEach(u => {
                console.log(`   ✓ ${u.email} (${u.name}) - ${u.role}`);
            });
        } else {
            console.log('\n⚠️  No users have FCM tokens!');
            console.log('   → Users need to login on mobile app to register token');
            return;
        }
    } else {
        console.log('❌ Failed to get FCM status:', fcmStatus.data.message);
        return;
    }

    // Step 3: Send test notification
    console.log('\nSTEP 3: Send test notification');

    const testPayload = targetEmail
        ? { email: targetEmail }
        : {}; // Empty = send to admin self

    const testResult = await apiRequest('POST', '/admin/notifications/test', token, testPayload);

    if (testResult.data.success) {
        console.log('✅ Test notification sent!');
        console.log('   To:', testResult.data.user?.email);
        console.log('   FCM Status:', testResult.data.fcmStatus);
        console.log('   Title:', testResult.data.notification?.title);
        console.log('\n   → Check the phone for push notification!');
    } else {
        console.log('❌ Failed:', testResult.data.message);
    }

    console.log('\n========================================');
    console.log('   TEST COMPLETED');
    console.log('========================================');
}

testFCMNotifications().catch(err => {
    console.error('Test failed:', err.message);
    process.exit(1);
});
