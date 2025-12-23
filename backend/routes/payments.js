const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { protect } = require('../middleware/auth');
const Notification = require('../models/Notification');
const Reservation = require('../models/Reservation');
const {
  getPaymentMethods,
  savePaymentMethod,
  deletePaymentMethod,
  setDefaultPaymentMethod,
  createRefund,
  getRefundStatus,
} = require('../controllers/paymentController');

// @route   POST /api/payments/create-intent
// @desc    Créer un Payment Intent Stripe
// @access  Private
router.post('/create-intent', protect, async (req, res) => {
    try {
        const { amount, reservationId } = req.body;
        const User = require('../models/User');

        console.log('💳 Création Payment Intent:', {
            amount,
            reservationId,
            userId: req.user.id,
        });

        // Récupérer l'utilisateur pour obtenir son stripeCustomerId
        const user = await User.findById(req.user.id);

        // Créer le Payment Intent
        const paymentIntentParams = {
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
        };

        // Si l'utilisateur a un Stripe Customer ID, l'inclure
        if (user.stripeCustomerId) {
            paymentIntentParams.customer = user.stripeCustomerId;
            console.log('✅ Customer ID ajouté:', user.stripeCustomerId);
        }

        const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);

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
            const reservation = await Reservation.findByIdAndUpdate(
                reservationId,
                {
                    paymentStatus: 'paid',
                    paymentIntentId: paymentIntentId,
                },
                { new: true }
            );

            // Envoyer notification de paiement réussi
            if (reservation) {
                await Notification.notifyPaymentSuccess(reservation);
            }

            res.status(200).json({
                success: true,
                message: 'Paiement confirmé',
            });
        } else {
            // Paiement échoué - envoyer notification
            if (reservationId) {
                const reservation = await Reservation.findById(reservationId);
                if (reservation) {
                    await Notification.notifyPaymentFailed(
                        reservation,
                        paymentIntent.last_payment_error?.message || 'Paiement refusé'
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
        console.error('❌ Erreur confirmation paiement:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
});

// Payment Methods Management Routes
// @route   GET /api/payments/payment-methods
// @desc    Récupérer les méthodes de paiement du client
// @access  Private
router.get('/payment-methods', protect, getPaymentMethods);

// @route   POST /api/payments/payment-methods
// @desc    Ajouter une nouvelle méthode de paiement
// @access  Private
router.post('/payment-methods', protect, savePaymentMethod);

// @route   DELETE /api/payments/payment-methods/:id
// @desc    Supprimer une méthode de paiement
// @access  Private
router.delete('/payment-methods/:id', protect, deletePaymentMethod);

// @route   PATCH /api/payments/payment-methods/:id/default
// @desc    Définir une méthode de paiement par défaut
// @access  Private
router.patch('/payment-methods/:id/default', protect, setDefaultPaymentMethod);

// Refund Routes
// @route   POST /api/payments/refunds
// @desc    Créer un remboursement
// @access  Private
router.post('/refunds', protect, createRefund);

// @route   GET /api/payments/refunds/:id
// @desc    Récupérer le statut d'un remboursement
// @access  Private
router.get('/refunds/:id', protect, getRefundStatus);

module.exports = router;