/**
 * Script pour nettoyer les réservations de test
 * Supprime les réservations complétées sans paiement réel
 */

const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

async function cleanTestReservations() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connecté à MongoDB\n');

        const Reservation = require('../models/Reservation');

        // 1. Trouver les réservations de test (completed sans paiement)
        const testReservations = await Reservation.find({
            status: 'completed',
            paymentStatus: 'pending',
            $or: [
                { paymentIntentId: { $exists: false } },
                { paymentIntentId: null }
            ]
        }).select('_id totalPrice status paymentStatus createdAt userId');

        console.log('📋 Réservations de test trouvées:', testReservations.length);

        if (testReservations.length > 0) {
            console.log('\n📝 Détails des réservations à supprimer:');
            let totalAmount = 0;
            testReservations.forEach(r => {
                console.log(`   - ID: ${r._id} | Prix: $${r.totalPrice?.toFixed(2) || 0} | Date: ${r.createdAt?.toISOString().split('T')[0]}`);
                totalAmount += r.totalPrice || 0;
            });
            console.log(`\n💰 Montant total des réservations de test: $${totalAmount.toFixed(2)}`);

            // Supprimer
            const result = await Reservation.deleteMany({
                status: 'completed',
                paymentStatus: 'pending',
                $or: [
                    { paymentIntentId: { $exists: false } },
                    { paymentIntentId: null }
                ]
            });

            console.log(`\n✅ ${result.deletedCount} réservations de test supprimées`);
        } else {
            console.log('✅ Aucune réservation de test à nettoyer');
        }

        // 2. Vérifier les réservations restantes avec statut suspect
        const suspectReservations = await Reservation.find({
            status: 'completed',
            paymentStatus: { $ne: 'paid' }
        }).select('_id totalPrice paymentStatus paymentIntentId');

        if (suspectReservations.length > 0) {
            console.log(`\n⚠️  ${suspectReservations.length} réservation(s) avec statut suspect restantes:`);
            suspectReservations.forEach(r => {
                console.log(`   - ID: ${r._id} | PaymentStatus: ${r.paymentStatus} | PaymentIntent: ${r.paymentIntentId || 'N/A'}`);
            });
        }

        // 3. Stats après nettoyage
        const stats = await Reservation.aggregate([
            { $match: { status: 'completed' } },
            {
                $group: {
                    _id: '$paymentStatus',
                    count: { $sum: 1 },
                    total: { $sum: '$totalPrice' }
                }
            }
        ]);

        console.log('\n📊 Stats après nettoyage:');
        stats.forEach(s => {
            console.log(`   - ${s._id}: ${s.count} réservations ($${s.total?.toFixed(2) || 0})`);
        });

        await mongoose.disconnect();
        console.log('\n✅ Nettoyage terminé!');

    } catch (error) {
        console.error('❌ Erreur:', error.message);
        process.exit(1);
    }
}

cleanTestReservations();
