const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
    createConnectAccount,
    getConnectAccountStatus,
    getConnectDashboardLink,
    getConnectBalance,
    getPayoutHistory,
    getPlatformFeeConfig,
} = require('../controllers/stripeConnectController');

// @route   POST /api/stripe-connect/create-account
// @desc    Créer un compte Stripe Connect pour le déneigeur
// @access  Private (snowWorker only)
router.post('/create-account', protect, authorize('snowWorker'), createConnectAccount);

// @route   GET /api/stripe-connect/account-status
// @desc    Vérifier le statut du compte Connect
// @access  Private (snowWorker only)
router.get('/account-status', protect, authorize('snowWorker'), getConnectAccountStatus);

// @route   GET /api/stripe-connect/dashboard-link
// @desc    Obtenir le lien vers le dashboard Stripe Express
// @access  Private (snowWorker only)
router.get('/dashboard-link', protect, authorize('snowWorker'), getConnectDashboardLink);

// @route   GET /api/stripe-connect/balance
// @desc    Récupérer le solde du compte Connect
// @access  Private (snowWorker only)
router.get('/balance', protect, authorize('snowWorker'), getConnectBalance);

// @route   GET /api/stripe-connect/payout-history
// @desc    Récupérer l'historique des paiements reçus
// @access  Private (snowWorker only)
router.get('/payout-history', protect, authorize('snowWorker'), getPayoutHistory);

// @route   GET /api/stripe-connect/fee-config
// @desc    Obtenir la configuration des commissions
// @access  Private
router.get('/fee-config', protect, getPlatformFeeConfig);

module.exports = router;
