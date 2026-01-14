const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const User = require('../models/User');
const Reservation = require('../models/Reservation');
const Notification = require('../models/Notification');
const Transaction = require('../models/Transaction');
const { PLATFORM_FEE_PERCENT, WORKER_PERCENT } = require('../config/constants');

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
    return res.status(500).json({ success: false, message: 'Erreur lors de la récupération des méthodes de paiement' });
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
    return res.status(500).json({ success: false, message: 'Erreur lors de l\'ajout de la méthode de paiement' });
  }
};

// Delete payment method
exports.deletePaymentMethod = async (req, res) => {
  try {
    await stripe.paymentMethods.detach(req.params.id);
    res.json({ success: true, message: 'Méthode de paiement supprimée' });
  } catch (error) {
    console.error('Error deleting payment method:', error);
    return res.status(500).json({ success: false, message: 'Erreur lors de la suppression de la méthode de paiement' });
  }
};

// Set default payment method
exports.setDefaultPaymentMethod = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user.stripeCustomerId) {
      return res.status(400).json({
        success: false,
        message: 'Aucune méthode de paiement configurée. Veuillez ajouter une carte.'
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
    return res.status(500).json({ success: false, message: 'Erreur lors de la mise à jour de la méthode par défaut' });
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
    return res.status(500).json({ success: false, message: 'Erreur lors de la création du remboursement' });
  }
};

// Get refund status
exports.getRefundStatus = async (req, res) => {
  try {
    const refund = await stripe.refunds.retrieve(req.params.id);
    res.json({ success: true, refund });
  } catch (error) {
    console.error('Error fetching refund:', error);
    return res.status(500).json({ success: false, message: 'Erreur lors de la récupération du remboursement' });
  }
};

// ============================================
// PAYOUT FUNCTIONS (Versement aux déneigeurs)
// ============================================

/**
 * Créer un transfert manuel vers un déneigeur
 * Utilisé quand le paiement a été fait avant l'assignation du déneigeur
 */
exports.createWorkerPayout = async (req, res) => {
  try {
    const { reservationId } = req.body;

    const reservation = await Reservation.findById(reservationId)
      .populate('workerId')
      .populate('userId');

    if (!reservation) {
      return res.status(404).json({
        success: false,
        message: 'Réservation non trouvée',
      });
    }

    // Vérifier que le paiement a été effectué
    if (reservation.paymentStatus !== 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Le paiement n\'a pas encore été effectué',
      });
    }

    // Vérifier qu'un déneigeur est assigné
    if (!reservation.workerId) {
      return res.status(400).json({
        success: false,
        message: 'Aucun déneigeur assigné à cette réservation',
      });
    }

    // Vérifier que le payout n'a pas déjà été fait
    if (reservation.payout?.status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Le versement a déjà été effectué',
      });
    }

    // Récupérer le déneigeur avec son compte Connect
    const worker = await User.findById(reservation.workerId);
    const workerConnectId = worker?.workerProfile?.stripeConnectId;

    if (!workerConnectId) {
      return res.status(400).json({
        success: false,
        message: 'Le déneigeur n\'a pas configuré son compte de paiement',
      });
    }

    // Calculer les montants
    const grossAmount = reservation.totalPrice;
    const platformFee = grossAmount * PLATFORM_FEE_PERCENT;
    const stripeFee = (grossAmount * 0.029) + 0.30;
    const workerAmount = grossAmount - platformFee;

    // Créer le transfert vers le compte Connect du déneigeur
    const transfer = await stripe.transfers.create(
      {
        amount: Math.round(workerAmount * 100), // En cents
        currency: 'cad',
        destination: workerConnectId,
        description: `Versement pour réservation #${reservation._id}`,
        metadata: {
          reservationId: reservation._id.toString(),
          workerId: worker._id.toString(),
          clientId: reservation.userId.toString(),
        },
      },
      {
        idempotencyKey: `admin_payout_${reservation._id}`, // Empêche les doubles paiements
      }
    );

    // Mettre à jour la réservation
    reservation.payout = {
      status: 'paid',
      workerAmount: workerAmount,
      platformFee: platformFee,
      stripeFee: stripeFee,
      stripeTransferId: transfer.id,
      paidAt: new Date(),
    };
    await reservation.save();

    // Créer la transaction
    await Transaction.create({
      type: 'payout',
      status: 'succeeded',
      amount: workerAmount,
      reservationId: reservation._id,
      toUserId: worker._id,
      stripeTransferId: transfer.id,
      breakdown: {
        grossAmount,
        stripeFee,
        platformFee,
        workerAmount,
      },
      description: `Versement manuel pour réservation #${reservation._id}`,
      processedAt: new Date(),
    });

    // Mettre à jour les stats du déneigeur
    await User.findByIdAndUpdate(worker._id, {
      $inc: {
        'workerProfile.totalEarnings': workerAmount,
      },
    });

    console.log('✅ Transfert créé:', transfer.id);

    res.json({
      success: true,
      message: 'Versement effectué avec succès',
      payout: {
        transferId: transfer.id,
        workerAmount: workerAmount,
        platformFee: platformFee,
      },
    });
  } catch (error) {
    console.error('Error creating worker payout:', error);
    return res.status(500).json({ success: false, message: 'Erreur lors du versement au déneigeur' });
  }
};

/**
 * Obtenir les réservations en attente de paiement pour un déneigeur
 */
exports.getPendingPayouts = async (req, res) => {
  try {
    const reservations = await Reservation.find({
      workerId: req.user.id,
      paymentStatus: 'paid',
      status: 'completed',
      'payout.status': { $ne: 'paid' },
    })
      .populate('userId', 'firstName lastName')
      .populate('vehicle')
      .sort({ completedAt: -1 });

    const pendingPayouts = reservations.map(r => ({
      reservationId: r._id,
      client: `${r.userId.firstName} ${r.userId.lastName}`,
      totalPrice: r.totalPrice,
      expectedAmount: r.totalPrice * (1 - PLATFORM_FEE_PERCENT),
      completedAt: r.completedAt,
      status: r.payout?.status || 'pending',
    }));

    res.json({
      success: true,
      pendingPayouts,
      count: pendingPayouts.length,
    });
  } catch (error) {
    console.error('Error fetching pending payouts:', error);
    return res.status(500).json({ success: false, message: 'Erreur lors de la récupération des paiements en attente' });
  }
};

/**
 * Obtenir l'historique des paiements reçus par un déneigeur
 */
exports.getWorkerPayoutHistory = async (req, res) => {
  try {
    const transactions = await Transaction.find({
      toUserId: req.user.id,
      type: { $in: ['payout', 'tip'] },
      status: 'succeeded',
    })
      .populate('reservationId', 'departureTime')
      .sort({ createdAt: -1 })
      .limit(50);

    const history = transactions.map(t => ({
      id: t._id,
      type: t.type,
      amount: t.amount,
      date: t.createdAt,
      reservationId: t.reservationId?._id,
      reservationDate: t.reservationId?.departureTime,
      breakdown: t.breakdown,
    }));

    // Calculer le total
    const totalEarnings = transactions.reduce((sum, t) => sum + t.amount, 0);

    res.json({
      success: true,
      history,
      totalEarnings,
      count: history.length,
    });
  } catch (error) {
    console.error('Error fetching payout history:', error);
    return res.status(500).json({ success: false, message: 'Erreur lors de la récupération de l\'historique des paiements' });
  }
};

/**
 * Obtenir le résumé des gains d'un déneigeur
 */
exports.getWorkerEarningsSummary = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : null;

    const summary = await Transaction.getWorkerEarningsSummary(
      req.user.id,
      start,
      end
    );

    // Récupérer aussi le solde Stripe si disponible
    const user = await User.findById(req.user.id);
    let stripeBalance = null;

    if (user.workerProfile?.stripeConnectId) {
      try {
        const balance = await stripe.balance.retrieve({
          stripeAccount: user.workerProfile.stripeConnectId,
        });

        stripeBalance = {
          available: balance.available.reduce((acc, b) =>
            b.currency === 'cad' ? acc + (b.amount / 100) : acc, 0),
          pending: balance.pending.reduce((acc, b) =>
            b.currency === 'cad' ? acc + (b.amount / 100) : acc, 0),
        };
      } catch (e) {
        console.log('Note: Impossible de récupérer le solde Stripe');
      }
    }

    res.json({
      success: true,
      summary: {
        ...summary,
        stripeBalance,
      },
    });
  } catch (error) {
    console.error('Error fetching earnings summary:', error);
    return res.status(500).json({ success: false, message: 'Erreur lors de la récupération du résumé des gains' });
  }
};
