/**
 * Modèle Mongoose pour les transactions financières.
 * Enregistre les paiements, versements, remboursements, pourboires et commissions via Stripe.
 */

const mongoose = require('mongoose');

// --- Schéma principal ---

const transactionSchema = new mongoose.Schema({
    // Type de transaction
    type: {
        type: String,
        enum: [
            'payment',           // Paiement client
            'payout',            // Versement au déneigeur
            'refund',            // Remboursement client
            'tip',               // Pourboire
            'platform_fee',      // Commission plateforme
            'stripe_fee',        // Frais Stripe
        ],
        required: true,
    },

    // Statut
    status: {
        type: String,
        enum: ['pending', 'processing', 'succeeded', 'failed', 'cancelled'],
        default: 'pending',
    },

    // Montants (en dollars CAD)
    amount: {
        type: Number,
        required: true,
    },
    currency: {
        type: String,
        default: 'cad',
    },

    // Références
    reservationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reservation',
    },

    // Parties impliquées
    fromUserId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    toUserId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },

    // Stripe IDs
    stripePaymentIntentId: {
        type: String,
    },
    stripeTransferId: {
        type: String,
    },
    stripePayoutId: {
        type: String,
    },
    stripeRefundId: {
        type: String,
    },

    // Détails de la répartition
    breakdown: {
        grossAmount: Number,        // Montant brut payé par le client
        stripeFee: Number,          // Frais Stripe (~2.9% + 0.30$)
        platformFee: Number,        // Commission plateforme (25%)
        workerAmount: Number,       // Montant net pour le déneigeur (75%)
        tipAmount: Number,          // Pourboire (si applicable)
    },

    // Métadonnées
    description: {
        type: String,
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed,
    },

    // Erreur (si failed)
    errorMessage: {
        type: String,
    },
    errorCode: {
        type: String,
    },

    // Timestamps
    processedAt: {
        type: Date,
    },
}, {
    timestamps: true,
});

// --- Index ---

transactionSchema.index({ reservationId: 1, type: 1 });
transactionSchema.index({ fromUserId: 1, createdAt: -1 });
transactionSchema.index({ toUserId: 1, createdAt: -1 });
transactionSchema.index({ status: 1, type: 1 });
transactionSchema.index({ stripePaymentIntentId: 1 });

// --- Méthodes statiques ---

/**
 * Crée un ensemble de transactions pour un paiement complet (paiement client, commission, versement déneigeur).
 * @param {Object} data - Données du paiement (reservationId, clientId, workerId, montants, IDs Stripe)
 * @returns {Promise<Document>} La transaction de paiement principale
 */
transactionSchema.statics.createPaymentTransaction = async function(data) {
    const {
        reservationId,
        clientId,
        workerId,
        grossAmount,
        stripeFee,
        platformFeePercent = 0.25,
        stripePaymentIntentId,
        stripeTransferId,
    } = data;

    // Calculer la répartition
    const netAfterStripe = grossAmount - stripeFee;
    const platformFee = grossAmount * platformFeePercent;
    const workerAmount = grossAmount - platformFee - stripeFee;

    // Créer la transaction principale (paiement client)
    const paymentTransaction = await this.create({
        type: 'payment',
        status: 'succeeded',
        amount: grossAmount,
        reservationId,
        fromUserId: clientId,
        stripePaymentIntentId,
        breakdown: {
            grossAmount,
            stripeFee,
            platformFee,
            workerAmount,
        },
        description: `Paiement réservation #${reservationId}`,
        processedAt: new Date(),
    });

    // Créer la transaction de commission plateforme
    await this.create({
        type: 'platform_fee',
        status: 'succeeded',
        amount: platformFee,
        reservationId,
        fromUserId: clientId,
        description: `Commission 25% sur réservation #${reservationId}`,
        processedAt: new Date(),
    });

    // Créer la transaction de payout au déneigeur
    if (workerId && stripeTransferId) {
        await this.create({
            type: 'payout',
            status: 'succeeded',
            amount: workerAmount,
            reservationId,
            toUserId: workerId,
            stripeTransferId,
            breakdown: {
                grossAmount,
                stripeFee,
                platformFee,
                workerAmount,
            },
            description: `Versement pour réservation #${reservationId}`,
            processedAt: new Date(),
        });
    }

    return paymentTransaction;
};

/**
 * Calcule le résumé des gains d'un déneigeur sur une période donnée.
 * @param {ObjectId} workerId - Identifiant du déneigeur
 * @param {Date} [startDate] - Date de début de la période
 * @param {Date} [endDate] - Date de fin de la période
 * @returns {Promise<Object>} Résumé avec totalPayouts, totalTips et totalEarnings
 */
transactionSchema.statics.getWorkerEarningsSummary = async function(workerId, startDate, endDate) {
    const match = {
        toUserId: new mongoose.Types.ObjectId(workerId),
        type: { $in: ['payout', 'tip'] },
        status: 'succeeded',
    };

    if (startDate || endDate) {
        match.createdAt = {};
        if (startDate) match.createdAt.$gte = startDate;
        if (endDate) match.createdAt.$lte = endDate;
    }

    const result = await this.aggregate([
        { $match: match },
        {
            $group: {
                _id: '$type',
                total: { $sum: '$amount' },
                count: { $sum: 1 },
            },
        },
    ]);

    const summary = {
        totalPayouts: 0,
        totalTips: 0,
        payoutCount: 0,
        tipCount: 0,
    };

    result.forEach(r => {
        if (r._id === 'payout') {
            summary.totalPayouts = r.total;
            summary.payoutCount = r.count;
        } else if (r._id === 'tip') {
            summary.totalTips = r.total;
            summary.tipCount = r.count;
        }
    });

    summary.totalEarnings = summary.totalPayouts + summary.totalTips;
    return summary;
};

module.exports = mongoose.model('Transaction', transactionSchema);
