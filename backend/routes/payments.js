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
  createRefund,
  getRefundStatus,
  createWorkerPayout,
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

/**
 * POST /api/payments/confirm
 * Confirme un paiement Stripe, met à jour la réservation et les statistiques du déneigeur.
 * Enregistre les transactions et notifie le client.
 * @param {string} req.body.paymentIntentId - ID du Payment Intent Stripe
 * @param {string} req.body.reservationId - ID de la réservation
 */
router.post('/confirm', protect, paymentLimiter, validateConfirmPayment, async (req, res) => {
    try {
        const { paymentIntentId, reservationId } = req.body;

        console.log('✅ Confirmation paiement:', {
            paymentIntentId,
            reservationId,
        });

        // Récupérer le Payment Intent pour vérifier le statut
        const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

        if (paymentIntent.status === 'succeeded') {
            // Extraire les métadonnées
            const metadata = paymentIntent.metadata;
            const platformFee = parseInt(metadata.platformFee || 0) / 100;
            const workerAmount = parseInt(metadata.workerAmount || 0) / 100;
            const workerId = metadata.workerId;
            const grossAmount = paymentIntent.amount / 100;

            // Estimer les frais Stripe (~2.9% + 0.30$)
            const stripeFee = (grossAmount * 0.029) + 0.30;

            // Mettre à jour la réservation avec les infos de payout
            const updateData = {
                paymentStatus: 'paid',
                paymentIntentId: paymentIntentId,
            };

            // Si un déneigeur est assigné, mettre à jour les infos de payout
            if (workerId) {
                updateData['payout.status'] = paymentIntent.transfer_data ? 'paid' : 'pending';
                updateData['payout.workerAmount'] = workerAmount;
                updateData['payout.platformFee'] = platformFee;
                updateData['payout.stripeFee'] = stripeFee;
                updateData['payout.paidAt'] = paymentIntent.transfer_data ? new Date() : null;

                // Récupérer l'ID du transfert si disponible
                if (paymentIntent.transfer_data) {
                    try {
                        const transfers = await stripe.transfers.list({
                            transfer_group: paymentIntent.transfer_group,
                            limit: 1,
                        });
                        if (transfers.data.length > 0) {
                            updateData['payout.stripeTransferId'] = transfers.data[0].id;
                        }
                    } catch (e) {
                        console.log('Note: Impossible de récupérer l\'ID du transfert');
                    }
                }
            }

            const reservation = await Reservation.findByIdAndUpdate(
                reservationId,
                updateData,
                { new: true }
            );

            // Créer les transactions dans notre système
            if (reservation) {
                try {
                    await Transaction.createPaymentTransaction({
                        reservationId: reservation._id,
                        clientId: reservation.userId,
                        workerId: workerId || null,
                        grossAmount: grossAmount,
                        stripeFee: stripeFee,
                        platformFeePercent: PLATFORM_FEE_PERCENT,
                        stripePaymentIntentId: paymentIntentId,
                        stripeTransferId: updateData['payout.stripeTransferId'] || null,
                    });
                    console.log('✅ Transactions enregistrées');
                } catch (txError) {
                    console.error('⚠️ Erreur enregistrement transactions:', txError);
                    // Ne pas échouer le paiement pour ça
                }

                // Mettre à jour les stats du déneigeur si applicable
                if (workerId) {
                    try {
                        await User.findByIdAndUpdate(workerId, {
                            $inc: {
                                'workerProfile.totalEarnings': workerAmount,
                                'workerProfile.totalJobsCompleted': 1,
                            },
                        });
                        console.log('✅ Stats déneigeur mises à jour');
                    } catch (statsError) {
                        console.error('⚠️ Erreur mise à jour stats:', statsError);
                    }
                }

                // Envoyer notification de paiement réussi
                await safeNotify(
                    () => Notification.notifyPaymentSuccess(reservation),
                    'PaymentSuccess'
                );
            }

            res.status(200).json({
                success: true,
                message: 'Paiement confirmé',
                breakdown: {
                    total: grossAmount,
                    platformFee: platformFee,
                    workerAmount: workerAmount,
                    stripeFee: stripeFee,
                },
            });
        } else {
            // Paiement échoué - envoyer notification
            if (reservationId) {
                const reservation = await Reservation.findById(reservationId);
                if (reservation) {
                    await safeNotify(
                        () => Notification.notifyPaymentFailed(reservation, 'Paiement refusé'),
                        'PaymentFailed'
                    );
                }
            }

            res.status(400).json({
                success: false,
                message: 'Le paiement n\'a pas réussi',
                status: paymentIntent.status,
            });
        }
    } catch (error) {
        return handleError(res, error, 'payments:confirm', 'Erreur lors de la confirmation du paiement');
    }
});

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

/**
 * POST /api/payments/refunds
 * Crée un remboursement Stripe pour une réservation.
 */
router.post('/refunds', protect, paymentLimiter, validateRefund, createRefund);

/**
 * GET /api/payments/refunds/:id
 * Récupère le statut d'un remboursement par son ID.
 */
router.get('/refunds/:id', protect, getRefundStatus);

// --- Versements aux déneigeurs ---

/**
 * POST /api/payments/payouts
 * Crée un versement manuel au déneigeur (admin uniquement).
 */
router.post('/payouts', protect, createWorkerPayout);

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