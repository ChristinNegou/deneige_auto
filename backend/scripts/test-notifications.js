/**
 * Script de test pour créer des notifications de démonstration
 *
 * Usage: node scripts/test-notifications.js <userId>
 *
 * Exemple: node scripts/test-notifications.js 6752a1234567890abcdef123
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Notification = require('../models/Notification');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/deneige-auto';

async function createTestNotifications(userId, reservationId = null) {
    try {
        // Connexion à MongoDB
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connecté à MongoDB');

        // Si pas de reservationId fourni, essayer d'en trouver une existante
        let testReservationId = reservationId;
        if (!testReservationId) {
            const Reservation = require('../models/Reservation');
            const existingReservation = await Reservation.findOne({ userId }).sort({ createdAt: -1 });
            if (existingReservation) {
                testReservationId = existingReservation._id.toString();
                console.log(`📋 Utilisation de la réservation existante: ${testReservationId}`);
            } else {
                console.log('⚠️ Aucune réservation trouvée - les notifications liées aux réservations n\'auront pas de reservationId');
            }
        }

        // Créer plusieurs notifications de test
        const notifications = [
            {
                userId,
                type: 'reservationAssigned',
                title: 'Déneigeur assigné',
                message: 'Jean Tremblay a accepté votre demande de déneigement',
                priority: 'high',
                reservationId: testReservationId,
            },
            {
                userId,
                type: 'workerEnRoute',
                title: 'Déneigeur en route',
                message: 'Jean est en route vers votre véhicule',
                priority: 'high',
                reservationId: testReservationId,
            },
            {
                userId,
                type: 'workStarted',
                title: 'Déneigement commencé',
                message: 'Jean a commencé le déneigement de votre véhicule',
                priority: 'normal',
                reservationId: testReservationId,
            },
            {
                userId,
                type: 'workCompleted',
                title: 'Déneigement terminé',
                message: 'Jean a terminé le déneigement. Votre véhicule est prêt!',
                priority: 'high',
                reservationId: testReservationId,
            },
            {
                userId,
                type: 'paymentSuccess',
                title: 'Paiement réussi',
                message: 'Votre paiement de 25.50 $ a été effectué avec succès',
                priority: 'normal',
                reservationId: testReservationId,
            },
            {
                userId,
                type: 'weatherAlert',
                title: 'Alerte météo',
                message: '15 cm de neige prévus demain. Planifiez votre déneigement!',
                priority: 'high',
                // Pas de reservationId pour les alertes météo
            },
            {
                userId,
                type: 'systemNotification',
                title: 'Bienvenue!',
                message: 'Merci d\'utiliser Déneige Auto. Votre première réservation est offerte à -20%!',
                priority: 'normal',
                // Pas de reservationId pour les notifications système
            },
        ];

        // Créer chaque notification avec un délai pour varier les timestamps
        for (let i = 0; i < notifications.length; i++) {
            const notification = await Notification.create(notifications[i]);
            console.log(`✅ Notification créée: ${notification.title}`);

            // Attendre 1 seconde entre chaque notification
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        console.log(`\n🎉 ${notifications.length} notifications de test créées avec succès!`);
        console.log(`\n📱 Ouvrez l'app et allez dans Menu > Notifications pour les voir`);

    } catch (error) {
        console.error('❌ Erreur:', error);
    } finally {
        await mongoose.connection.close();
        console.log('\n✅ Déconnecté de MongoDB');
        process.exit();
    }
}

// Récupérer l'ID utilisateur depuis les arguments
const userId = process.argv[2];

if (!userId) {
    console.error('❌ Erreur: userId requis');
    console.log('\nUsage: node scripts/test-notifications.js <userId>');
    console.log('Exemple: node scripts/test-notifications.js 6752a1234567890abcdef123');
    process.exit(1);
}

// Valider que c'est un ObjectId MongoDB valide
if (!mongoose.Types.ObjectId.isValid(userId)) {
    console.error('❌ Erreur: userId invalide (doit être un ObjectId MongoDB)');
    process.exit(1);
}

console.log(`🚀 Création de notifications de test pour l'utilisateur: ${userId}\n`);
createTestNotifications(userId);
