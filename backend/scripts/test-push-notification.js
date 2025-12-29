/**
 * Script de test pour envoyer une notification push
 * Usage: node scripts/test-push-notification.js [email]
 *
 * Exemples:
 *   node scripts/test-push-notification.js                     # Envoie au topic "clients"
 *   node scripts/test-push-notification.js user@email.com     # Envoie à cet utilisateur
 */

require('dotenv').config();
const mongoose = require('mongoose');
const { initializeFirebase, sendPushNotification, sendTopicNotification } = require('../services/firebaseService');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/deneige_auto';

// Schéma User simplifié
const userSchema = new mongoose.Schema({
    email: String,
    firstName: String,
    lastName: String,
    fcmToken: String,
    role: String,
});
const User = mongoose.model('User', userSchema);

async function testPushNotification() {
    console.log('='.repeat(50));
    console.log('TEST NOTIFICATION PUSH');
    console.log('='.repeat(50));

    try {
        // 1. Initialiser Firebase
        console.log('\n1. Initialisation Firebase...');
        const app = initializeFirebase();
        if (!app) {
            console.error('❌ Firebase non initialisé!');
            process.exit(1);
        }
        console.log('✅ Firebase initialisé');

        // 2. Connexion MongoDB
        console.log('\n2. Connexion MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('✅ MongoDB connecté');

        const emailArg = process.argv[2];

        if (emailArg) {
            // 3a. Envoyer à un utilisateur spécifique
            console.log(`\n3. Recherche de l'utilisateur: ${emailArg}`);
            const user = await User.findOne({ email: emailArg.toLowerCase() });

            if (!user) {
                console.log(`❌ Utilisateur "${emailArg}" non trouvé`);
                console.log('\nUtilisateurs avec token FCM:');
                const usersWithToken = await User.find({ fcmToken: { $ne: null } }, 'email firstName fcmToken');
                if (usersWithToken.length === 0) {
                    console.log('   Aucun utilisateur n\'a de token FCM enregistré.');
                    console.log('   → Connectez-vous d\'abord sur l\'app mobile.');
                } else {
                    usersWithToken.forEach(u => {
                        console.log(`   - ${u.email} (${u.firstName}) - Token: ${u.fcmToken?.substring(0, 20)}...`);
                    });
                }
                process.exit(1);
            }

            if (!user.fcmToken) {
                console.log(`❌ L'utilisateur ${user.email} n'a pas de token FCM`);
                console.log('   → Connectez-vous d\'abord sur l\'app mobile.');
                process.exit(1);
            }

            console.log(`✅ Utilisateur trouvé: ${user.firstName} (${user.email})`);
            console.log(`   Token FCM: ${user.fcmToken.substring(0, 30)}...`);

            // Envoyer la notification
            console.log('\n4. Envoi de la notification...');
            const result = await sendPushNotification(
                user.fcmToken,
                '🧪 Test Notification',
                `Bonjour ${user.firstName}! Ceci est un test de notification push.`,
                {
                    type: 'test',
                    timestamp: new Date().toISOString(),
                }
            );

            if (result?.success) {
                console.log('✅ Notification envoyée avec succès!');
                console.log(`   Message ID: ${result.messageId}`);
            } else if (result?.invalidToken) {
                console.log('⚠️ Token invalide - l\'utilisateur doit se reconnecter');
            } else {
                console.log('❌ Erreur:', result?.error || 'Inconnue');
            }
        } else {
            // 3b. Envoyer à tous les clients via topic
            console.log('\n3. Envoi au topic "clients"...');

            const result = await sendTopicNotification(
                'clients',
                '🧪 Test Notification',
                'Ceci est un test de notification push pour tous les clients!',
                {
                    type: 'test',
                    timestamp: new Date().toISOString(),
                }
            );

            if (result?.success) {
                console.log('✅ Notification topic envoyée!');
                console.log(`   Message ID: ${result.messageId}`);
            } else {
                console.log('⚠️ Résultat:', result?.error || 'Aucun abonné au topic');
            }

            // Aussi envoyer au topic "all_users"
            console.log('\n4. Envoi au topic "all_users"...');
            const result2 = await sendTopicNotification(
                'all_users',
                '📢 Annonce Test',
                'Test de notification broadcast à tous les utilisateurs!',
                {
                    type: 'broadcast_test',
                    timestamp: new Date().toISOString(),
                }
            );

            if (result2?.success) {
                console.log('✅ Notification all_users envoyée!');
                console.log(`   Message ID: ${result2.messageId}`);
            } else {
                console.log('⚠️ Résultat:', result2?.error || 'Aucun abonné');
            }
        }

        console.log('\n' + '='.repeat(50));
        console.log('TEST TERMINÉ');
        console.log('='.repeat(50));
        console.log('\nVérifiez votre téléphone pour la notification!');

    } catch (error) {
        console.error('❌ Erreur:', error.message);
    } finally {
        await mongoose.disconnect();
        process.exit(0);
    }
}

testPushNotification();
