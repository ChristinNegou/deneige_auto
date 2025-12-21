
/**
 * Script de migration pour renommer les champs vehicleId et parkingSpotId
 * en vehicle et parkingSpot dans la collection Reservations
 *
 * Exécution: node scripts/migrate-reservation-fields.js
 */

const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

async function migrateReservationFields() {
    try {
        // Vérifier que la variable d'environnement existe
        if (!process.env.MONGODB_URI) {
            throw new Error('MONGODB_URI n\'est pas défini dans le fichier .env');
        }

        console.log('📡 Connexion à:', process.env.MONGODB_URI.replace(/\/\/.*@/, '//<credentials>@'));

        // Connexion à MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connecté à MongoDB');

        const db = mongoose.connection.db;
        const reservationsCollection = db.collection('reservations');

        // Compter le nombre de documents à migrer
        const count = await reservationsCollection.countDocuments({});
        console.log(`📊 Nombre total de réservations: ${count}`);

        // Renommer vehicleId en vehicle
        const vehicleResult = await reservationsCollection.updateMany(
            { vehicleId: { $exists: true } },
            { $rename: { vehicleId: 'vehicle' } }
        );
        console.log(`✅ Renommage vehicleId → vehicle: ${vehicleResult.modifiedCount} documents modifiés`);

        // Renommer parkingSpotId en parkingSpot
        const parkingResult = await reservationsCollection.updateMany(
            { parkingSpotId: { $exists: true } },
            { $rename: { parkingSpotId: 'parkingSpot' } }
        );
        console.log(`✅ Renommage parkingSpotId → parkingSpot: ${parkingResult.modifiedCount} documents modifiés`);

        console.log('🎉 Migration terminée avec succès !');

        // Vérification
        const sampleDoc = await reservationsCollection.findOne({});
        console.log('\n📋 Exemple de document après migration:');
        console.log({
            _id: sampleDoc._id,
            userId: sampleDoc.userId,
            vehicle: sampleDoc.vehicle,
            parkingSpot: sampleDoc.parkingSpot,
            status: sampleDoc.status,
        });

    } catch (error) {
        console.error('❌ Erreur lors de la migration:', error);
        process.exit(1);
    } finally {
        await mongoose.disconnect();
        console.log('\n✅ Déconnecté de MongoDB');
        process.exit(0);
    }
}

// Exécuter la migration
migrateReservationFields();
