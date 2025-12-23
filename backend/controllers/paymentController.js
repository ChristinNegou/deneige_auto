const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const User = require('../models/User');
const Reservation = require('../models/Reservation');
const Notification = require('../models/Notification');

// Get payment methods from Stripe Customer
exports.getPaymentMethods = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user.stripeCustomerId) {
      return res.json({ success: true, paymentMethods: [] });
    }

    const paymentMethods = await stripe.paymentMethods.list({
      customer: user.stripeCustomerId,
      type: 'card',
    });

    // Get customer to find default payment method
    const customer = await stripe.customers.retrieve(user.stripeCustomerId);
    const defaultPaymentMethodId = customer.invoice_settings?.default_payment_method;

    // Mark default payment method
    const methodsWithDefault = paymentMethods.data.map(pm => ({
      ...pm,
      isDefault: pm.id === defaultPaymentMethodId,
    }));

    res.json({ success: true, paymentMethods: methodsWithDefault });
  } catch (error) {
    console.error('Error fetching payment methods:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Save new payment method
exports.savePaymentMethod = async (req, res) => {
  try {
    const { paymentMethodId, setAsDefault } = req.body;
    const user = await User.findById(req.user.id);

    // Create Stripe customer if doesn't exist
    if (!user.stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        name: `${user.firstName} ${user.lastName}`,
        metadata: {
          userId: user._id.toString(),
        },
      });
      user.stripeCustomerId = customer.id;
      await user.save();
    }

    // Attach payment method to customer
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: user.stripeCustomerId,
    });

    if (setAsDefault) {
      await stripe.customers.update(user.stripeCustomerId, {
        invoice_settings: {
          default_payment_method: paymentMethodId,
        },
      });
    }

    res.json({ success: true, message: 'Méthode de paiement ajoutée' });
  } catch (error) {
    console.error('Error saving payment method:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Delete payment method
exports.deletePaymentMethod = async (req, res) => {
  try {
    await stripe.paymentMethods.detach(req.params.id);
    res.json({ success: true, message: 'Méthode de paiement supprimée' });
  } catch (error) {
    console.error('Error deleting payment method:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Set default payment method
exports.setDefaultPaymentMethod = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user.stripeCustomerId) {
      return res.status(400).json({
        success: false,
        message: 'Aucun client Stripe trouvé'
      });
    }

    await stripe.customers.update(user.stripeCustomerId, {
      invoice_settings: {
        default_payment_method: req.params.id,
      },
    });

    res.json({ success: true, message: 'Méthode par défaut mise à jour' });
  } catch (error) {
    console.error('Error setting default payment method:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Create refund
exports.createRefund = async (req, res) => {
  try {
    const { reservationId, amount, reason } = req.body;

    const reservation = await Reservation.findById(reservationId);

    if (!reservation) {
      return res.status(404).json({
        success: false,
        message: 'Réservation non trouvée'
      });
    }

    if (reservation.userId.toString() !== req.user.id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Non autorisé'
      });
    }

    if (!reservation.paymentIntentId) {
      return res.status(400).json({
        success: false,
        message: 'Aucun paiement à rembourser'
      });
    }

    // Create refund in Stripe
    const refundParams = {
      payment_intent: reservation.paymentIntentId,
      reason: reason || 'requested_by_customer',
    };

    // Partial refund if amount specified
    if (amount) {
      refundParams.amount = Math.round(amount * 100); // Convert to cents
    }

    const refund = await stripe.refunds.create(refundParams);

    // Update reservation status
    if (refund.status === 'succeeded') {
      const refundedAmount = refund.amount / 100;

      if (refundedAmount < reservation.totalPrice) {
        reservation.paymentStatus = 'partially_refunded';
      } else {
        reservation.paymentStatus = 'refunded';
      }

      await reservation.save();

      // Créer notification de remboursement
      await Notification.createNotification({
        userId: reservation.userId,
        type: 'refundProcessed',
        title: 'Remboursement effectué',
        message: `Votre remboursement de ${refundedAmount.toFixed(2)} $ a été traité avec succès`,
        priority: 'normal',
        reservationId: reservation._id,
        metadata: {
          amount: refundedAmount,
          refundId: refund.id,
        },
      });
    }

    res.json({ success: true, refund });
  } catch (error) {
    console.error('Error creating refund:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get refund status
exports.getRefundStatus = async (req, res) => {
  try {
    const refund = await stripe.refunds.retrieve(req.params.id);
    res.json({ success: true, refund });
  } catch (error) {
    console.error('Error fetching refund:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
