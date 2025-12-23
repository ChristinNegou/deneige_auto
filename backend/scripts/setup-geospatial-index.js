/**
 * Script pour créer l'index géospatial sur les réservations
 * et vérifier que les réservations ont des coordonnées GPS valides
 *
 * Usage: node backend/scripts/setup-geospatial-index.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Reservation = require('../models/Reservation');

async function main() {
    try {
        // Connexion à MongoDB
        const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/deneige';
        console.log('🔌 Connexion à MongoDB...');
        await mongoose.connect(mongoUri);
        console.log('✅ Connecté à MongoDB');

        // Créer l'index géospatial
        console.log('\n📍 Création de l\'index géospatial 2dsphere sur location...');
        try {
            await Reservation.collection.createIndex({ 'location': '2dsphere' });
            console.log('✅ Index 2dsphere créé avec succès');
        } catch (err) {
            if (err.code === 85 || err.message.includes('already exists')) {
                console.log('ℹ️  Index 2dsphere existe déjà');
            } else {
                console.error('❌ Erreur lors de la création de l\'index:', err.message);
            }
        }

        // Vérifier les réservations pending
        console.log('\n📋 Vérification des réservations pending...');
        const pendingReservations = await Reservation.find({ status: 'pending' });
        console.log(`   Total réservations pending: ${pendingReservations.length}`);

        // Vérifier les coordonnées GPS
        let withValidCoords = 0;
        let withInvalidCoords = 0;

        for (const res of pendingReservations) {
            const coords = res.location?.coordinates;
            if (coords && coords.length === 2 && coords[0] !== 0 && coords[1] !== 0) {
                withValidCoords++;
                console.log(`   ✅ Réservation ${res._id}: [${coords[0]}, ${coords[1]}] (${res.location?.address || 'pas d\'adresse'})`);
            } else {
                withInvalidCoords++;
                console.log(`   ⚠️  Réservation ${res._id}: Coordonnées invalides ou [0,0]`);
            }
        }

        console.log(`\n📊 Résumé:`);
        console.log(`   Avec coordonnées valides: ${withValidCoords}`);
        console.log(`   Sans coordonnées valides: ${withInvalidCoords}`);

        // Vérifier les réservations dans les prochaines 24h
        const now = new Date();
        const next24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const upcomingPending = await Reservation.find({
            status: 'pending',
            departureTime: { $gte: now, $lte: next24Hours },
        });
        console.log(`\n⏰ Réservations pending dans les prochaines 24h: ${upcomingPending.length}`);

        for (const res of upcomingPending) {
            const coords = res.location?.coordinates;
            const hasValidCoords = coords && coords.length === 2 && coords[0] !== 0 && coords[1] !== 0;
            console.log(`   ${hasValidCoords ? '✅' : '⚠️'} ID: ${res._id}`);
            console.log(`      Départ: ${res.departureTime}`);
            console.log(`      Coords: [${coords?.[0] || 'N/A'}, ${coords?.[1] || 'N/A'}]`);
            console.log(`      Adresse: ${res.location?.address || 'N/A'}`);
        }

        console.log('\n✅ Script terminé');

    } catch (error) {
        console.error('❌ Erreur:', error);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Déconnecté de MongoDB');
    }
}

main();
