const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const Reservation = require('../models/Reservation');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Notification = require('../models/Notification');
const { PLATFORM_FEE_PERCENT } = require('../config/constants');

// Webhook secrets - à configurer dans .env
const WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET;
const WEBHOOK_SECRET_CONNECT = process.env.STRIPE_WEBHOOK_SECRET_CONNECT;

/**
 * @route   POST /api/webhooks/stripe
 * @desc    Handle Stripe webhook events
 * @access  Public (verified by Stripe signature)
 */
router.post('/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
    const sig = req.headers['stripe-signature'];

    let event;

    try {
        // Vérifier la signature du webhook - OBLIGATOIRE en production
        if (!WEBHOOK_SECRET && !WEBHOOK_SECRET_CONNECT) {
            if (process.env.NODE_ENV === 'production') {
                console.error('❌ STRIPE_WEBHOOK_SECRET non configuré en production - webhook rejeté');
                return res.status(500).json({ error: 'Webhook configuration error' });
            }
            // Mode développement uniquement - afficher un avertissement
            console.warn('⚠️ STRIPE_WEBHOOK_SECRET non configuré - webhook non vérifié (dev mode only)');
            event = JSON.parse(req.body);
        } else {
            // Essayer de vérifier avec le secret principal d'abord
            let verified = false;

            if (WEBHOOK_SECRET) {
                try {
                    event = stripe.webhooks.constructEvent(req.body, sig, WEBHOOK_SECRET);
                    verified = true;
                } catch (e) {
                    // Échec avec le secret principal, essayer le secret Connect
                }
            }

            // Si non vérifié, essayer avec le secret Connect
            if (!verified && WEBHOOK_SECRET_CONNECT) {
                try {
                    event = stripe.webhooks.constructEvent(req.body, sig, WEBHOOK_SECRET_CONNECT);
                    verified = true;
                } catch (e) {
                    // Échec avec les deux secrets
                }
            }

            if (!verified) {
                throw new Error('Signature verification failed with all secrets');
            }
        }
    } catch (err) {
        console.error('❌ Webhook signature verification failed:', err.message);
        return res.status(400).json({ error: 'Webhook signature verification failed' });
    }

    console.log(`📥 Stripe webhook received: ${event.type}`);

    try {
        switch (event.type) {
            // ============================================
            // PAYMENT EVENTS
            // ============================================
            case 'payment_intent.succeeded':
                await handlePaymentIntentSucceeded(event.data.object);
                break;

            case 'payment_intent.payment_failed':
                await handlePaymentIntentFailed(event.data.object);
                break;

            // ============================================
            // STRIPE CONNECT EVENTS
            // ============================================
            case 'account.updated':
                await handleAccountUpdated(event.data.object);
                break;

            case 'account.external_account.created':
                await handleExternalAccountCreated(event.data.object);
                break;

            // ============================================
            // TRANSFER EVENTS
            // ============================================
            case 'transfer.created':
                await handleTransferCreated(event.data.object);
                break;

            case 'transfer.failed':
                await handleTransferFailed(event.data.object);
                break;

            // ============================================
            // DISPUTE EVENTS
            // ============================================
            case 'charge.dispute.created':
                await handleDisputeCreated(event.data.object);
                break;

            case 'charge.dispute.closed':
                await handleDisputeClosed(event.data.object);
                break;

            // ============================================
            // REFUND EVENTS
            // ============================================
            case 'charge.refunded':
                await handleChargeRefunded(event.data.object);
                break;

            default:
                console.log(`ℹ️ Unhandled event type: ${event.type}`);
        }

        res.json({ received: true });
    } catch (error) {
        console.error(`❌ Webhook handler error for ${event.type}:`, error);
        // Retourner 200 pour éviter les retries Stripe - ne jamais exposer les erreurs
        res.json({ received: true });
    }
});

// ============================================
// PAYMENT HANDLERS
// ============================================

async function handlePaymentIntentSucceeded(paymentIntent) {
    console.log(`✅ PaymentIntent succeeded: ${paymentIntent.id}`);

    const reservationId = paymentIntent.metadata?.reservationId;
    if (!reservationId) {
        console.log('ℹ️ No reservationId in metadata, skipping');
        return;
    }

    const reservation = await Reservation.findById(reservationId);
    if (!reservation) {
        console.error(`❌ Reservation not found: ${reservationId}`);
        return;
    }

    // Mettre à jour le statut de paiement si pas déjà fait
    if (reservation.paymentStatus !== 'paid') {
        reservation.paymentStatus = 'paid';
        reservation.paymentIntentId = paymentIntent.id;
        reservation.paidAt = new Date();
        await reservation.save();

        console.log(`✅ Reservation ${reservationId} marked as paid via webhook`);

        // Notifier le client
        if (reservation.userId) {
            await Notification.create({
                userId: reservation.userId,
                type: 'payment_success',
                title: 'Paiement confirmé',
                message: 'Votre paiement a été confirmé avec succès.',
                data: { reservationId: reservation._id },
            });
        }
    }
}

async function handlePaymentIntentFailed(paymentIntent) {
    console.log(`❌ PaymentIntent failed: ${paymentIntent.id}`);

    const reservationId = paymentIntent.metadata?.reservationId;
    if (!reservationId) return;

    const reservation = await Reservation.findById(reservationId);
    if (!reservation) return;

    reservation.paymentStatus = 'failed';
    await reservation.save();

    // Notifier le client
    if (reservation.userId) {
        await Notification.create({
            userId: reservation.userId,
            type: 'payment_failed',
            title: 'Échec du paiement',
            message: 'Votre paiement a échoué. Veuillez réessayer.',
            data: { reservationId: reservation._id },
        });
    }
}

// ============================================
// STRIPE CONNECT HANDLERS
// ============================================

async function handleAccountUpdated(account) {
    console.log(`📝 Stripe Connect account updated: ${account.id}`);

    const worker = await User.findOne({ 'workerProfile.stripeConnectId': account.id });
    if (!worker) {
        console.log(`ℹ️ No worker found for Stripe account: ${account.id}`);
        return;
    }

    // Mettre à jour le statut du compte Connect
    const wasReady = worker.workerProfile.stripeConnectReady;
    worker.workerProfile.stripeConnectReady = account.charges_enabled && account.payouts_enabled;
    worker.workerProfile.stripeConnectStatus = account.charges_enabled ? 'active' : 'pending';

    await worker.save();

    // Notifier si le compte vient d'être activé
    if (!wasReady && worker.workerProfile.stripeConnectReady) {
        console.log(`✅ Worker ${worker._id} Stripe Connect account is now active`);

        await Notification.create({
            userId: worker._id,
            type: 'stripe_connect_ready',
            title: 'Compte de paiement activé',
            message: 'Votre compte est maintenant prêt à recevoir des paiements!',
            data: { stripeConnectId: account.id },
        });
    }
}

async function handleExternalAccountCreated(externalAccount) {
    console.log(`🏦 External account added: ${externalAccount.id}`);
    // Log pour audit, pas d'action nécessaire
}

// ============================================
// TRANSFER HANDLERS
// ============================================

async function handleTransferCreated(transfer) {
    console.log(`💸 Transfer created: ${transfer.id}`);

    const reservationId = transfer.metadata?.reservationId;
    if (!reservationId) return;

    const reservation = await Reservation.findById(reservationId);
    if (!reservation) return;

    // Marquer le payout comme réussi
    if (reservation.payout?.status !== 'completed') {
        reservation.payout = {
            ...reservation.payout,
            status: 'completed',
            stripeTransferId: transfer.id,
            completedAt: new Date(),
        };
        await reservation.save();

        console.log(`✅ Payout marked as completed for reservation ${reservationId}`);
    }
}

async function handleTransferFailed(transfer) {
    console.log(`❌ Transfer failed: ${transfer.id}`);

    const reservationId = transfer.metadata?.reservationId;
    if (!reservationId) return;

    const reservation = await Reservation.findById(reservationId);
    if (!reservation) return;

    reservation.payout = {
        ...reservation.payout,
        status: 'failed',
        failedAt: new Date(),
        failureReason: transfer.failure_message || 'Unknown error',
    };
    await reservation.save();

    // Notifier le worker
    if (reservation.workerId) {
        await Notification.create({
            userId: reservation.workerId,
            type: 'payout_failed',
            title: 'Échec du transfert',
            message: 'Le transfert de vos gains a échoué. Notre équipe va investiguer.',
            data: { reservationId: reservation._id, transferId: transfer.id },
        });
    }
}

// ============================================
// DISPUTE HANDLERS
// ============================================

async function handleDisputeCreated(dispute) {
    console.log(`⚠️ Dispute created: ${dispute.id}`);

    const paymentIntentId = dispute.payment_intent;
    const reservation = await Reservation.findOne({ paymentIntentId });

    if (!reservation) {
        console.error(`❌ Reservation not found for dispute payment_intent: ${paymentIntentId}`);
        return;
    }

    // Marquer la réservation comme disputée
    reservation.isDisputed = true;
    reservation.disputeId = dispute.id;
    reservation.disputeStatus = dispute.status;
    reservation.disputeReason = dispute.reason;
    await reservation.save();

    // Bloquer le payout si pas encore effectué
    if (reservation.payout?.status === 'pending') {
        reservation.payout.status = 'held';
        reservation.payout.holdReason = 'dispute';
        await reservation.save();
    }

    // Notifier l'admin (créer une notification système)
    console.log(`🚨 DISPUTE ALERT: Reservation ${reservation._id}, Amount: ${dispute.amount / 100} ${dispute.currency}`);

    // Notifier le worker si applicable
    if (reservation.workerId) {
        await Notification.create({
            userId: reservation.workerId,
            type: 'dispute_created',
            title: 'Litige ouvert',
            message: 'Un litige a été ouvert sur une de vos réservations. Les paiements sont suspendus.',
            data: { reservationId: reservation._id, disputeId: dispute.id },
        });
    }
}

async function handleDisputeClosed(dispute) {
    console.log(`📋 Dispute closed: ${dispute.id}, status: ${dispute.status}`);

    const paymentIntentId = dispute.payment_intent;
    const reservation = await Reservation.findOne({ paymentIntentId });

    if (!reservation) return;

    reservation.disputeStatus = dispute.status;

    // Si le dispute est gagné (en faveur du marchand)
    if (dispute.status === 'won') {
        reservation.isDisputed = false;

        // Débloquer le payout si applicable
        if (reservation.payout?.status === 'held') {
            reservation.payout.status = 'pending';
            reservation.payout.holdReason = null;
        }

        // Notifier le worker
        if (reservation.workerId) {
            await Notification.create({
                userId: reservation.workerId,
                type: 'dispute_won',
                title: 'Litige résolu',
                message: 'Le litige a été résolu en votre faveur.',
                data: { reservationId: reservation._id },
            });
        }
    }
    // Si le dispute est perdu
    else if (dispute.status === 'lost') {
        // Annuler le payout
        if (reservation.payout) {
            reservation.payout.status = 'cancelled';
            reservation.payout.cancelledReason = 'dispute_lost';
        }

        // Notifier le worker
        if (reservation.workerId) {
            await Notification.create({
                userId: reservation.workerId,
                type: 'dispute_lost',
                title: 'Litige perdu',
                message: 'Le litige a été perdu. Le paiement a été annulé.',
                data: { reservationId: reservation._id },
            });
        }
    }

    await reservation.save();
}

// ============================================
// REFUND HANDLERS
// ============================================

async function handleChargeRefunded(charge) {
    console.log(`💰 Charge refunded: ${charge.id}`);

    const paymentIntentId = charge.payment_intent;
    const reservation = await Reservation.findOne({ paymentIntentId });

    if (!reservation) return;

    const totalRefunded = charge.amount_refunded / 100;
    const originalAmount = charge.amount / 100;

    if (totalRefunded >= originalAmount) {
        reservation.paymentStatus = 'refunded';
    } else {
        reservation.paymentStatus = 'partially_refunded';
    }

    reservation.refundedAmount = totalRefunded;
    reservation.refundedAt = new Date();
    await reservation.save();

    console.log(`✅ Reservation ${reservation._id} refund status updated: ${reservation.paymentStatus}`);
}

module.exports = router;
