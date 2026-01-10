const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
    reportNoShow,
    createDispute,
    getMyDisputes,
    getDisputeDetails,
    respondToDispute,
    addEvidence,
    appealDispute,
    getAllDisputes,
    resolveDispute,
    addAdminNote,
    resolveAppeal,
    getDisputeStats,
    verifyWorkQuality,
    confirmSatisfaction,
    getDisputeTypes,
} = require('../controllers/disputeController');

// ============== PUBLIC ==============

// @route   GET /api/disputes/types
// @desc    Obtenir les types de litiges disponibles
// @access  Public
router.get('/types', getDisputeTypes);

// ============== CLIENT & WORKER ROUTES ==============

// @route   POST /api/disputes/report-no-show/:reservationId
// @desc    Signaler un no-show (déneigeur pas venu)
// @access  Private (client only)
router.post('/report-no-show/:reservationId', protect, authorize('client'), reportNoShow);

// @route   POST /api/disputes
// @desc    Créer un litige général
// @access  Private
router.post('/', protect, createDispute);

// @route   GET /api/disputes/my-disputes
// @desc    Obtenir mes litiges
// @access  Private
router.get('/my-disputes', protect, getMyDisputes);

// @route   GET /api/disputes/:id
// @desc    Obtenir les détails d'un litige
// @access  Private
router.get('/:id', protect, getDisputeDetails);

// @route   POST /api/disputes/:id/respond
// @desc    Répondre à un litige (défendeur)
// @access  Private
router.post('/:id/respond', protect, respondToDispute);

// @route   POST /api/disputes/:id/evidence
// @desc    Ajouter des preuves à un litige
// @access  Private
router.post('/:id/evidence', protect, addEvidence);

// @route   POST /api/disputes/:id/appeal
// @desc    Faire appel d'une décision
// @access  Private
router.post('/:id/appeal', protect, appealDispute);

// @route   POST /api/disputes/confirm-satisfaction/:reservationId
// @desc    Client confirme que le travail est satisfaisant
// @access  Private (client only)
router.post('/confirm-satisfaction/:reservationId', protect, authorize('client'), confirmSatisfaction);

// ============== ADMIN ROUTES ==============

// @route   GET /api/disputes/admin/all
// @desc    Obtenir tous les litiges (admin)
// @access  Private (admin only)
router.get('/admin/all', protect, authorize('admin'), getAllDisputes);

// @route   GET /api/disputes/admin/stats
// @desc    Obtenir les statistiques des litiges (admin)
// @access  Private (admin only)
router.get('/admin/stats', protect, authorize('admin'), getDisputeStats);

// @route   POST /api/disputes/:id/resolve
// @desc    Résoudre un litige (admin)
// @access  Private (admin only)
router.post('/:id/resolve', protect, authorize('admin'), resolveDispute);

// @route   POST /api/disputes/:id/admin-note
// @desc    Ajouter une note admin
// @access  Private (admin only)
router.post('/:id/admin-note', protect, authorize('admin'), addAdminNote);

// @route   POST /api/disputes/:id/resolve-appeal
// @desc    Résoudre un appel (admin)
// @access  Private (admin only)
router.post('/:id/resolve-appeal', protect, authorize('admin'), resolveAppeal);

// @route   POST /api/disputes/verify-quality/:reservationId
// @desc    Vérifier la qualité d'un travail complété
// @access  Private (admin only)
router.post('/verify-quality/:reservationId', protect, authorize('admin'), verifyWorkQuality);

module.exports = router;
