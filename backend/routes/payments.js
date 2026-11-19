/**
 * Routes de paiement Stripe : création d'intentions, confirmation, méthodes de paiement, remboursements et versements.
 * @module routes/payments
 */

const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { protect } = require('../middleware/auth');
const Notification = require('../models/Notification');
const Reservation = require('../models/Reservation');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const {
  getPaymentMethods,
  savePaymentMethod,
  deletePaymentMethod,
  setDefaultPaymentMethod,
  getPendingPayouts,
  getWorkerPayoutHistory,
  getWorkerEarningsSummary,
} = require('../controllers/paymentController');
const { paymentLimiter } = require('../middleware/rateLimiter');
const { validatePaymentMethodId, validateCreatePaymentIntent, validateConfirmPayment, validateTip, validateRefund, validateReservationId } = require('../middleware/validators');
const { PLATFORM_FEE_PERCENT } = require('../config/constants');
const { handleError, safeNotify } = require('../utils/errorHandler');

// --- Création et confirmation de paiement ---

/**
 * POST /api/payments/create-intent
 * Crée un Payment Intent Stripe avec transfert automatique au déneigeur via Connect.
 * Inclut une clé d'idempotence pour éviter les doubles charges.
 * @param {number} req.body.amount - Montant en dollars CAD
 * @param {string} [req.body.reservationId] - ID de la réservation liée
 * @returns {Object} clientSecret, paymentIntentId et ventilation des montants
 */
router.post('/create-intent', protect, paymentLimiter, validateCreatePaymentIntent, async (req, res) => {
    try {
        const { amount, reservationId } = req.body;

        console.log('💳 Création Payment Intent:', {
            amount,
            reservationId,
            userId: req.user.id,
        });

        // Récupérer l'utilisateur client
        const user = await User.findById(req.user.id);

        // Récupérer la réservation et le déneigeur assigné
        let reservation = null;
        let worker = null;
        let workerConnectId = null;

        if (reservationId && reservationId !== 'temp') {
            reservation = await Reservation.findById(reservationId).populate('workerId');
            if (reservation?.workerId) {
                worker = await User.findById(reservation.workerId);
                workerConnectId = worker?.workerProfile?.stripeConnectId;
            }
        }

        // Calculer les montants
        const amountInCents = Math.round(amount * 100);
        const platformFeeInCents = Math.round(amountInCents * PLATFORM_FEE_PERCENT);
        const workerAmountInCents = amountInCents - platformFeeInCents;

        // Générer une clé d'idempotence unique pour éviter les doubles charges
        // Basée sur l'utilisateur, la réservation et le montant
        const idempotencyKey = `payment_${req.user.id}_${reservationId || 'temp'}_${amountInCents}_${Date.now()}`;

        // Paramètres du Payment Intent
        const paymentIntentParams = {
            amount: amountInCents,
            currency: 'cad',
            automatic_payment_methods: {
                enabled: true,
            },
            metadata: {
                userId: req.user.id.toString(),
                reservationId: reservationId || 'temp',
                userEmail: req.user.email,
                platformFee: platformFeeInCents,
                workerAmount: workerAmountInCents,
                idempotencyKey: idempotencyKey,
            },
        };

        // Si l'utilisateur a un Stripe Customer ID, l'inclure
        if (user.stripeCustomerId) {
            paymentIntentParams.customer = user.stripeCustomerId;
            console.log('✅ Customer ID ajouté:', user.stripeCustomerId);
        }

        // Si un déneigeur avec compte Connect est assigné, configurer le transfert
        if (workerConnectId) {
            paymentIntentParams.transfer_data = {
                destination: workerConnectId,
                amount: workerAmountInCents, // Le déneigeur reçoit 75%
            };
            paymentIntentParams.metadata.workerId = worker._id.toString();
            paymentIntentParams.metadata.workerConnectId = workerConnectId;

            console.log('✅ Transfert configuré:', {
                destination: workerConnectId,
                workerAmount: workerAmountInCents / 100,
                platformFee: platformFeeInCents / 100,
            });
        }

        const paymentIntent = await stripe.paymentIntents.create(
            paymentIntentParams,
            { idempotencyKey: idempotencyKey }
        );

        console.log('✅ Payment Intent créé:', paymentIntent.id);

        res.status(200).json({
            success: true,
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
            breakdown: {
                total: amount,
                platformFee: platformFeeInCents / 100,
                workerAmount: workerAmountInCents / 100,
                hasWorkerTransfer: !!workerConnectId,
            },
        });
    } catch (error) {
        return handleError(res, error, 'payments:create-intent', 'Erreur lors de la création du paiement');
    }
});

// Paiement d'une reservation : verifie a la creation (POST /api/reservations)
// et par le webhook payment_intent.succeeded.

// --- Gestion des méthodes de paiement ---

/**
 * GET /api/payments/payment-methods
 * Récupère les méthodes de paiement enregistrées du client.
 */
router.get('/payment-methods', protect, getPaymentMethods);

/**
 * POST /api/payments/payment-methods
 * Ajoute une nouvelle méthode de paiement au client.
 */
router.post('/payment-methods', protect, savePaymentMethod);

/**
 * DELETE /api/payments/payment-methods/:id
 * Supprime une méthode de paiement.
 */
router.delete('/payment-methods/:id', protect, deletePaymentMethod);

/**
 * PATCH /api/payments/payment-methods/:id/default
 * Définit une méthode de paiement comme méthode par défaut.
 */
router.patch('/payment-methods/:id/default', protect, setDefaultPaymentMethod);

// --- Remboursements ---

// Les remboursements passent par l'annulation (regles d'annulation), les
// litiges ou l'admin (POST /api/admin/reservations/:id/refund) : un client
// ne peut pas se rembourser lui-meme.


// --- Versements aux déneigeurs ---

// Les versements passent tous par services/payoutService (fin du
// deneigement, activation du compte Stripe, bouton de l'admin).

/**
 * GET /api/payments/payouts/pending
 * Récupère les versements en attente du déneigeur.
 */
router.get('/payouts/pending', protect, getPendingPayouts);

/**
 * GET /api/payments/payouts/history
 * Retourne l'historique des versements reçus par le déneigeur.
 */
router.get('/payouts/history', protect, getWorkerPayoutHistory);

/**
 * GET /api/payments/payouts/summary
 * Retourne le résumé des gains du déneigeur (total, en attente, transféré).
 */
router.get('/payouts/summary', protect, getWorkerEarningsSummary);

// --- Webhook Stripe (chargebacks/disputes) ---

/**
 * POST /api/payments/webhook
 * Gère les webhooks Stripe (chargebacks, remboursements, échecs de paiement).
 * La signature est vérifiée via STRIPE_WEBHOOK_SECRET.
 * Ce endpoint reçoit le raw body, configuré dans server.js.
 */
router.post('/webhook', async (req, res) => {
    const sig = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;

    try {
        // Vérifier la signature Stripe
        event = stripe.webhooks.constructEvent(req.rawBody || req.body, sig, webhookSecret);
    } catch (err) {
        console.error('⚠️ Webhook signature verification failed:', err.message);
        return res.status(400).json({ success: false, message: 'Webhook validation failed' });
    }

    console.log(`📩 Webhook Stripe reçu: ${event.type}`);

    // Gérer les différents types d'événements
    try {
        switch (event.type) {
            case 'charge.dispute.created': {
                // Un client a ouvert un chargeback
                const dispute = event.data.object;
                console.log('⚠️ CHARGEBACK CRÉÉ:', dispute.id);

                const { handleStripeDispute } = require('../controllers/disputeController');
                await handleStripeDispute(dispute);
                break;
            }

            case 'charge.dispute.updated': {
                // Mise à jour du statut du chargeback
                const dispute = event.data.object;
                console.log('📝 Chargeback mis à jour:', dispute.id, dispute.status);

                const { handleStripeDispute } = require('../controllers/disputeController');
                await handleStripeDispute(dispute);
                break;
            }

            case 'charge.dispute.closed': {
                // Chargeback résolu (gagné ou perdu)
                const dispute = event.data.object;
                console.log(`✅ Chargeback fermé: ${dispute.id} - Statut: ${dispute.status}`);

                const { handleStripeDispute } = require('../controllers/disputeController');
                await handleStripeDispute(dispute);
                break;
            }

            case 'charge.refunded': {
                // Remboursement effectué
                const charge = event.data.object;
                console.log('💸 Remboursement effectué:', charge.id);

                // Mettre à jour la réservation si applicable
                if (charge.payment_intent) {
                    const reservation = await Reservation.findOne({
                        paymentIntentId: charge.payment_intent,
                    });

                    if (reservation) {
                        const refundedAmount = charge.amount_refunded / 100;
                        reservation.refundAmount = refundedAmount;
                        reservation.refundedAt = new Date();

                        if (refundedAmount >= reservation.totalPrice) {
                            reservation.paymentStatus = 'refunded';
                        } else {
                            reservation.paymentStatus = 'partially_refunded';
                        }

                        await reservation.save();
                        console.log('✅ Réservation mise à jour après remboursement');
                    }
                }
                break;
            }

            case 'payment_intent.payment_failed': {
                // Paiement échoué
                const paymentIntent = event.data.object;
                console.log('❌ Paiement échoué:', paymentIntent.id);

                // Mettre à jour la réservation
                if (paymentIntent.metadata?.reservationId) {
                    await Reservation.findByIdAndUpdate(
                        paymentIntent.metadata.reservationId,
                        { paymentStatus: 'failed' }
                    );
                }
                break;
            }

            default:
                console.log(`Webhook non géré: ${event.type}`);
        }

        res.json({ received: true });
    } catch (error) {
        console.error('❌ Erreur traitement webhook:', error);
        // Ne jamais exposer les erreurs dans les webhooks - retourner toujours 200
        res.json({ received: true });
    }
});

module.exports = router;