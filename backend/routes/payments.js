const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { protect } = require('../middleware/auth');

// @route   POST /api/payments/create-intent
// @desc    Créer un Payment Intent Stripe
// @access  Private
router.post('/create-intent', protect, async (req, res) => {
    try {
        const { amount, reservationId } = req.body;

        console.log('💳 Création Payment Intent:', {
            amount,
            reservationId,
            userId: req.user.id,
        });

        // Créer le Payment Intent
        const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(amount * 100), // Stripe utilise les cents
            currency: 'cad',
            automatic_payment_methods: {
                enabled: true,
            },
            metadata: {
                userId: req.user.id.toString(),
                reservationId: reservationId || 'temp',
                userEmail: req.user.email,
            },
        });

        console.log('✅ Payment Intent créé:', paymentIntent.id);

        res.status(200).json({
            success: true,
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
        });
    } catch (error) {
        console.error('❌ Erreur Stripe:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
});

// @route   POST /api/payments/confirm
// @desc    Confirmer un paiement et mettre à jour la réservation
// @access  Private
router.post('/confirm', protect, async (req, res) => {
    try {
        const { paymentIntentId, reservationId } = req.body;

        console.log('✅ Confirmation paiement:', {
            paymentIntentId,
            reservationId,
        });

        // Récupérer le Payment Intent pour vérifier le statut
        const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

        if (paymentIntent.status === 'succeeded') {
            // Mettre à jour la réservation
            const Reservation = require('../models/Reservation');
            await Reservation.findByIdAndUpdate(reservationId, {
                paymentStatus: 'paid',
                paymentIntentId: paymentIntentId,
            });

            res.status(200).json({
                success: true,
                message: 'Paiement confirmé',
            });
        } else {
            res.status(400).json({
                success: false,
                message: 'Le paiement n\'a pas réussi',
                status: paymentIntent.status,
            });
        }
    } catch (error) {
        console.error('❌ Erreur confirmation paiement:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
});

module.exports = router;