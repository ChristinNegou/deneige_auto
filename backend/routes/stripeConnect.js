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
    regenerateOnboardingLink,
    checkAccountRequirements,
    listBankAccounts,
    addBankAccount,
    deleteBankAccount,
    setDefaultBankAccount,
    getCanadianBanks,
    deleteConnectAccount,
    listAllConnectAccounts,
    deleteOrphanConnectAccount,
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

// @route   POST /api/stripe-connect/regenerate-onboarding
// @desc    Régénérer le lien d'onboarding (si expiré)
// @access  Private (snowWorker only)
router.post('/regenerate-onboarding', protect, authorize('snowWorker'), regenerateOnboardingLink);

// @route   GET /api/stripe-connect/requirements
// @desc    Vérifier si des actions sont requises sur le compte
// @access  Private (snowWorker only)
router.get('/requirements', protect, authorize('snowWorker'), checkAccountRequirements);

// ============== GESTION DES COMPTES BANCAIRES ==============

// @route   GET /api/stripe-connect/bank-accounts
// @desc    Récupérer la liste de tous les comptes bancaires
// @access  Private (snowWorker only)
router.get('/bank-accounts', protect, authorize('snowWorker'), listBankAccounts);

// @route   POST /api/stripe-connect/bank-accounts
// @desc    Ajouter un nouveau compte bancaire
// @access  Private (snowWorker only)
router.post('/bank-accounts', protect, authorize('snowWorker'), addBankAccount);

// @route   DELETE /api/stripe-connect/bank-accounts/:bankAccountId
// @desc    Supprimer un compte bancaire
// @access  Private (snowWorker only)
router.delete('/bank-accounts/:bankAccountId', protect, authorize('snowWorker'), deleteBankAccount);

// @route   PUT /api/stripe-connect/bank-accounts/:bankAccountId/set-default
// @desc    Définir un compte bancaire comme compte par défaut
// @access  Private (snowWorker only)
router.put('/bank-accounts/:bankAccountId/set-default', protect, authorize('snowWorker'), setDefaultBankAccount);

// @route   GET /api/stripe-connect/canadian-banks
// @desc    Obtenir la liste des institutions bancaires canadiennes
// @access  Private (snowWorker only)
router.get('/canadian-banks', protect, authorize('snowWorker'), getCanadianBanks);

// ============== ADMIN: GESTION DES COMPTES CONNECT ==============

// @route   GET /api/stripe-connect/admin/accounts
// @desc    Lister tous les comptes Connect de la plateforme
// @access  Private (admin only)
router.get('/admin/accounts', protect, authorize('admin'), listAllConnectAccounts);

// @route   DELETE /api/stripe-connect/admin/accounts/:workerId
// @desc    Supprimer le compte Connect d'un déneigeur
// @access  Private (admin only)
router.delete('/admin/accounts/:workerId', protect, authorize('admin'), deleteConnectAccount);

// @route   DELETE /api/stripe-connect/admin/orphan-accounts/:stripeAccountId
// @desc    Supprimer un compte Connect orphelin (non lié à un worker)
// @access  Private (admin only)
router.delete('/admin/orphan-accounts/:stripeAccountId', protect, authorize('admin'), deleteOrphanConnectAccount);

module.exports = router;
