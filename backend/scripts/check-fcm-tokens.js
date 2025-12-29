require('dotenv').config();
const mongoose = require('mongoose');

async function checkTokens() {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/deneige_auto');

    const users = await mongoose.connection.db.collection('users').find(
        {},
        { projection: { email: 1, firstName: 1, role: 1, fcmToken: 1 } }
    ).toArray();

    console.log('Utilisateurs dans la base de données:');
    console.log('='.repeat(60));

    let withToken = 0;
    let withoutToken = 0;

    users.forEach(u => {
        const hasToken = u.fcmToken ? 'Token FCM' : 'Pas de token';
        const icon = u.fcmToken ? '✅' : '❌';
        console.log(icon + ' ' + u.email + ' (' + u.role + ') - ' + hasToken);
        if (u.fcmToken) {
            console.log('   Token: ' + u.fcmToken.substring(0, 40) + '...');
            withToken++;
        } else {
            withoutToken++;
        }
    });

    console.log('='.repeat(60));
    console.log('Total: ' + users.length + ' utilisateurs');
    console.log('Avec token FCM: ' + withToken);
    console.log('Sans token FCM: ' + withoutToken);

    await mongoose.disconnect();
}

checkTokens();
