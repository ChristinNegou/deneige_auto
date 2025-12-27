/**
 * Script de simulation d'une réservation complète
 * Simule le workflow complet: création -> assignation -> en route -> travail -> terminé
 *
 * Usage: node scripts/simulate-reservation-workflow.js <clientUserId>
 *
 * Ce script va:
 * 1. Créer une réservation de test
 * 2. Simuler l'assignation d'un déneigeur (notification au client)
 * 3. Simuler le déneigeur en route (notification au client)
 * 4. Simuler le début du travail (notification au client)
 * 5. Simuler la fin du travail (notification au client)
 * 6. Simuler le paiement réussi (notification au client)
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const Reservation = require('../models/Reservation');
const User = require('../models/User');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/deneige-auto';

// Délais entre chaque étape (en secondes)
const DELAYS = {
    assignation: 5,      // 5 secondes après création
    enRoute: 10,         // 10 secondes après assignation
    travailCommence: 15, // 15 secondes après en route
    travailTermine: 20,  // 20 secondes après début travail
    paiement: 5,         // 5 secondes après fin travail
};

function sleep(seconds) {
    return new Promise(resolve => setTimeout(resolve, seconds * 1000));
}

function formatTime() {
    return new Date().toLocaleTimeString('fr-CA');
}

async function simulateReservationWorkflow(clientUserId) {
    try {
        // Connexion à MongoDB
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connecté à MongoDB\n');

        // Vérifier que l'utilisateur existe
        const client = await User.findById(clientUserId);
        if (!client) {
            throw new Error(`Client non trouvé avec l'ID: ${clientUserId}`);
        }
        console.log(`👤 Client: ${client.firstName} ${client.lastName} (${client.email})\n`);

        // Trouver ou créer un déneigeur de test
        let worker = await User.findOne({ role: 'snowWorker' });
        if (!worker) {
            console.log('⚠️ Aucun déneigeur trouvé, création d\'un déneigeur de test...');
            worker = await User.create({
                email: 'worker.test@deneige.com',
                password: 'Test123!',
                firstName: 'Jean',
                lastName: 'Tremblay',
                role: 'snowWorker',
                phoneNumber: '514-555-1234',
            });
        }
        console.log(`🔧 Déneigeur: ${worker.firstName} ${worker.lastName}\n`);

        // Trouver un véhicule du client
        const Vehicle = require('../models/Vehicle');
        let vehicle = await Vehicle.findOne({ userId: clientUserId });

        if (!vehicle) {
            console.log('⚠️ Aucun véhicule trouvé, création d\'un véhicule de test...');
            vehicle = await Vehicle.create({
                userId: clientUserId,
                make: 'Honda',
                model: 'Civic',
                color: 'Bleu',
                licensePlate: 'ABC 123',
                year: 2022,
            });
        }

        const vehicleData = {
            make: vehicle.make,
            model: vehicle.model,
            color: vehicle.color,
            licensePlate: vehicle.licensePlate,
        };

        console.log('═══════════════════════════════════════════════════════════');
        console.log('   🚗 SIMULATION DE RÉSERVATION COMPLÈTE');
        console.log('═══════════════════════════════════════════════════════════\n');

        // ÉTAPE 1: Créer la réservation
        console.log(`[${formatTime()}] 📝 ÉTAPE 1: Création de la réservation...`);

        const departureTime = new Date(Date.now() + 2 * 60 * 60 * 1000); // Dans 2 heures
        const deadlineTime = new Date(Date.now() + 3 * 60 * 60 * 1000); // Dans 3 heures

        const reservation = await Reservation.create({
            userId: clientUserId,
            vehicle: vehicle._id,
            parkingSpotNumber: 'A-42',
            customLocation: '1234 Rue Saint-Denis, Montréal, QC',
            departureTime: departureTime,
            deadlineTime: deadlineTime,
            serviceOptions: ['windowScraping'],
            basePrice: 15.00,
            totalPrice: 20.00,
            status: 'pending',
            isPriority: false,
            paymentMethod: 'card',
        });

        console.log(`   ✅ Réservation créée: ${reservation._id}`);
        console.log(`   📍 Adresse: 1234 Rue Saint-Denis, Montréal`);
        console.log(`   🚗 Véhicule: ${vehicleData.make} ${vehicleData.model} (${vehicleData.color})`);
        console.log(`   💰 Prix: ${reservation.totalPrice.toFixed(2)} $\n`);

        // ÉTAPE 2: Assignation du déneigeur
        console.log(`[${formatTime()}] ⏳ Attente de ${DELAYS.assignation} secondes avant assignation...`);
        await sleep(DELAYS.assignation);

        console.log(`[${formatTime()}] 👷 ÉTAPE 2: Assignation du déneigeur...`);

        reservation.status = 'assigned';
        reservation.assignedWorker = worker._id;
        reservation.assignedAt = new Date();
        await reservation.save();

        await Notification.createNotification({
            userId: clientUserId,
            type: 'reservationAssigned',
            title: 'Déneigeur assigné!',
            message: `${worker.firstName} ${worker.lastName} a accepté votre demande`,
            priority: 'high',
            reservationId: reservation._id,
            workerId: worker._id,
            metadata: {
                workerName: `${worker.firstName} ${worker.lastName}`,
                workerPhone: worker.phone,
            },
        });

        console.log(`   ✅ Déneigeur assigné: ${worker.firstName} ${worker.lastName}`);
        console.log(`   📱 Notification envoyée au client\n`);

        // ÉTAPE 3: Déneigeur en route
        console.log(`[${formatTime()}] ⏳ Attente de ${DELAYS.enRoute} secondes...`);
        await sleep(DELAYS.enRoute);

        console.log(`[${formatTime()}] 🚗 ÉTAPE 3: Déneigeur en route...`);

        reservation.status = 'enRoute';
        await reservation.save();

        await Notification.createNotification({
            userId: clientUserId,
            type: 'workerEnRoute',
            title: `${worker.firstName} est en route!`,
            message: 'Arrivée estimée dans environ 10 minutes',
            priority: 'high',
            reservationId: reservation._id,
            workerId: worker._id,
            metadata: {
                etaMinutes: 10,
                workerName: `${worker.firstName} ${worker.lastName}`,
            },
        });

        console.log(`   ✅ Statut: En route`);
        console.log(`   📱 Notification envoyée au client\n`);

        // ÉTAPE 4: Début du travail
        console.log(`[${formatTime()}] ⏳ Attente de ${DELAYS.travailCommence} secondes...`);
        await sleep(DELAYS.travailCommence);

        console.log(`[${formatTime()}] 🔧 ÉTAPE 4: Début du déneigement...`);

        reservation.status = 'inProgress';
        reservation.startedAt = new Date();
        await reservation.save();

        await Notification.createNotification({
            userId: clientUserId,
            type: 'workStarted',
            title: 'Déneigement commencé!',
            message: `${worker.firstName} a commencé le déneigement de votre ${vehicleData.make} ${vehicleData.model}`,
            priority: 'normal',
            reservationId: reservation._id,
            workerId: worker._id,
        });

        console.log(`   ✅ Travail commencé à ${formatTime()}`);
        console.log(`   📱 Notification envoyée au client\n`);

        // ÉTAPE 5: Fin du travail
        console.log(`[${formatTime()}] ⏳ Attente de ${DELAYS.travailTermine} secondes (simulation du travail)...`);
        await sleep(DELAYS.travailTermine);

        console.log(`[${formatTime()}] ✅ ÉTAPE 5: Déneigement terminé!`);

        reservation.status = 'completed';
        reservation.completedAt = new Date();
        await reservation.save();

        await Notification.createNotification({
            userId: clientUserId,
            type: 'workCompleted',
            title: 'Déneigement terminé!',
            message: `Votre ${vehicleData.make} ${vehicleData.model} est prêt. Merci d'utiliser Déneige Auto!`,
            priority: 'high',
            reservationId: reservation._id,
            workerId: worker._id,
            metadata: {
                completedAt: new Date().toISOString(),
                duration: Math.round((reservation.completedAt - reservation.startedAt) / 1000 / 60),
            },
        });

        console.log(`   ✅ Travail terminé à ${formatTime()}`);
        console.log(`   ⏱️ Durée: ${Math.round((reservation.completedAt - reservation.startedAt) / 1000)} secondes (simulation)`);
        console.log(`   📱 Notification envoyée au client\n`);

        // ÉTAPE 6: Paiement
        console.log(`[${formatTime()}] ⏳ Attente de ${DELAYS.paiement} secondes pour le paiement...`);
        await sleep(DELAYS.paiement);

        console.log(`[${formatTime()}] 💰 ÉTAPE 6: Paiement traité!`);

        await Notification.createNotification({
            userId: clientUserId,
            type: 'paymentSuccess',
            title: 'Paiement réussi!',
            message: `Votre paiement de ${reservation.totalPrice.toFixed(2)} $ a été traité avec succès`,
            priority: 'normal',
            reservationId: reservation._id,
            metadata: {
                amount: reservation.totalPrice,
                paymentMethod: 'Visa ****4242',
            },
        });

        console.log(`   ✅ Paiement de ${reservation.totalPrice.toFixed(2)} $ traité`);
        console.log(`   📱 Notification envoyée au client\n`);

        // Résumé final
        console.log('═══════════════════════════════════════════════════════════');
        console.log('   🎉 SIMULATION TERMINÉE AVEC SUCCÈS!');
        console.log('═══════════════════════════════════════════════════════════');
        console.log(`\n📋 Résumé:`);
        console.log(`   • Réservation ID: ${reservation._id}`);
        console.log(`   • Client: ${client.firstName} ${client.lastName}`);
        console.log(`   • Déneigeur: ${worker.firstName} ${worker.lastName}`);
        console.log(`   • Véhicule: ${vehicleData.make} ${vehicleData.model}`);
        console.log(`   • Prix total: ${reservation.totalPrice.toFixed(2)} $`);
        console.log(`   • Notifications envoyées: 5`);
        console.log(`\n📱 Ouvrez l'app client pour voir les notifications en temps réel!`);

    } catch (error) {
        console.error('\n❌ Erreur:', error.message);
        console.error(error.stack);
    } finally {
        await mongoose.connection.close();
        console.log('\n✅ Déconnecté de MongoDB');
        process.exit();
    }
}

// Récupérer l'ID utilisateur depuis les arguments
const clientUserId = process.argv[2];

if (!clientUserId) {
    console.error('❌ Erreur: clientUserId requis\n');
    console.log('Usage: node scripts/simulate-reservation-workflow.js <clientUserId>');
    console.log('Exemple: node scripts/simulate-reservation-workflow.js 6752a1234567890abcdef123');
    process.exit(1);
}

// Valider que c'est un ObjectId MongoDB valide
if (!mongoose.Types.ObjectId.isValid(clientUserId)) {
    console.error('❌ Erreur: clientUserId invalide (doit être un ObjectId MongoDB)');
    process.exit(1);
}

console.log('\n🚀 Démarrage de la simulation de réservation...\n');
simulateReservationWorkflow(clientUserId);
