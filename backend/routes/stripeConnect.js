/**
 * Routes Stripe Connect : gestion des comptes de paiement des déneigeurs.
 * Inclut la création de compte, onboarding, comptes bancaires et administration.
 * @module routes/stripeConnect
 */

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

// --- Compte Connect du déneigeur ---

/**
 * POST /api/stripe-connect/create-account
 * Crée un compte Stripe Connect Express pour le déneigeur et retourne le lien d'onboarding.
 */
router.post('/create-account', protect, authorize('snowWorker'), createConnectAccount);

/**
 * GET /api/stripe-connect/account-status
 * Vérifie le statut du compte Connect (charges_enabled, payouts_enabled).
 */
router.get('/account-status', protect, authorize('snowWorker'), getConnectAccountStatus);

/**
 * GET /api/stripe-connect/dashboard-link
 * Génère un lien temporaire vers le dashboard Stripe Express du déneigeur.
 */
router.get('/dashboard-link', protect, authorize('snowWorker'), getConnectDashboardLink);

/**
 * GET /api/stripe-connect/balance
 * Récupère le solde disponible et en attente du compte Connect.
 */
router.get('/balance', protect, authorize('snowWorker'), getConnectBalance);

/**
 * GET /api/stripe-connect/payout-history
 * Retourne l'historique des versements reçus par le déneigeur.
 */
router.get('/payout-history', protect, authorize('snowWorker'), getPayoutHistory);

/**
 * GET /api/stripe-connect/fee-config
 * Retourne la configuration des commissions de la plateforme.
 */
router.get('/fee-config', protect, getPlatformFeeConfig);

/**
 * POST /api/stripe-connect/regenerate-onboarding
 * Régénère le lien d'onboarding Stripe si le précédent a expiré.
 */
router.post('/regenerate-onboarding', protect, authorize('snowWorker'), regenerateOnboardingLink);

/**
 * GET /api/stripe-connect/requirements
 * Vérifie si des actions sont requises sur le compte Connect (documents manquants, etc.).
 */
router.get('/requirements', protect, authorize('snowWorker'), checkAccountRequirements);

// --- Gestion des comptes bancaires ---

/**
 * GET /api/stripe-connect/bank-accounts
 * Liste tous les comptes bancaires liés au compte Connect.
 */
router.get('/bank-accounts', protect, authorize('snowWorker'), listBankAccounts);

/**
 * POST /api/stripe-connect/bank-accounts
 * Ajoute un nouveau compte bancaire au compte Connect.
 */
router.post('/bank-accounts', protect, authorize('snowWorker'), addBankAccount);

/**
 * DELETE /api/stripe-connect/bank-accounts/:bankAccountId
 * Supprime un compte bancaire du compte Connect.
 */
router.delete('/bank-accounts/:bankAccountId', protect, authorize('snowWorker'), deleteBankAccount);

/**
 * PUT /api/stripe-connect/bank-accounts/:bankAccountId/set-default
 * Définit un compte bancaire comme compte par défaut pour les versements.
 */
router.put('/bank-accounts/:bankAccountId/set-default', protect, authorize('snowWorker'), setDefaultBankAccount);

/**
 * GET /api/stripe-connect/canadian-banks
 * Retourne la liste des institutions bancaires canadiennes reconnues.
 */
router.get('/canadian-banks', protect, authorize('snowWorker'), getCanadianBanks);

// --- Administration des comptes Connect ---

/**
 * GET /api/stripe-connect/admin/accounts
 * Liste tous les comptes Connect de la plateforme (admin).
 */
router.get('/admin/accounts', protect, authorize('admin'), listAllConnectAccounts);

/**
 * DELETE /api/stripe-connect/admin/accounts/:workerId
 * Supprime le compte Connect d'un déneigeur (admin).
 */
router.delete('/admin/accounts/:workerId', protect, authorize('admin'), deleteConnectAccount);

/**
 * DELETE /api/stripe-connect/admin/orphan-accounts/:stripeAccountId
 * Supprime un compte Connect orphelin non lié à un déneigeur (admin).
 */
router.delete('/admin/orphan-accounts/:stripeAccountId', protect, authorize('admin'), deleteOrphanConnectAccount);

module.exports = router;
