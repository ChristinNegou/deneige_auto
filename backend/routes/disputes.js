/**
 * Routes de gestion des litiges (création, signalement no-show, réponse, appel, résolution admin).
 * @module routes/disputes
 */

const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
    validateCreateDispute,
    validateReportNoShow,
    validateDisputeResponse,
    validateDisputeAppeal,
    validateResolveDispute,
    validateDisputePagination,
    validateMongoId,
} = require('../middleware/validators');
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
const { disputeEvidenceUpload, handleMulterError } = require('../middleware/fileUpload');
const { uploadFromBuffer } = require('../config/cloudinary');

// --- Routes publiques ---

/**
 * GET /api/disputes/types
 * Retourne les types de litiges disponibles.
 */
router.get('/types', getDisputeTypes);

/**
 * POST /api/disputes/upload-photos
 * Upload des photos pour un litige (preuves).
 * Retourne les URLs des photos uploadées.
 */
router.post('/upload-photos', protect, disputeEvidenceUpload.array('photos', 5), handleMulterError, async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Aucune photo fournie',
            });
        }

        const uploadPromises = req.files.map(file =>
            uploadFromBuffer(file.buffer, {
                folder: 'deneige-auto/disputes',
            })
        );

        const results = await Promise.all(uploadPromises);
        const urls = results.map(r => r.url);

        res.json({
            success: true,
            message: `${urls.length} photo(s) uploadée(s) avec succès`,
            urls,
        });
    } catch (error) {
        console.error('Error uploading dispute photos:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'upload des photos',
        });
    }
});

// --- Routes client et déneigeur ---

/**
 * POST /api/disputes/report-no-show/:reservationId
 * Signale un no-show (déneigeur absent) pour une réservation.
 */
router.post('/report-no-show/:reservationId', protect, authorize('client'), validateReportNoShow, reportNoShow);

/**
 * POST /api/disputes
 * Crée un nouveau litige lié à une réservation.
 * @param {string} req.body.reservationId - ID de la réservation
 * @param {string} req.body.type - Type de litige
 * @param {string} req.body.description - Description du problème
 */
router.post('/', protect, validateCreateDispute, createDispute);

/**
 * GET /api/disputes/my-disputes
 * Retourne les litiges de l'utilisateur (plaignant ou mis en cause).
 */
router.get('/my-disputes', protect, validateDisputePagination, getMyDisputes);

/**
 * GET /api/disputes/:id
 * Retourne les détails complets d'un litige.
 */
router.get('/:id', protect, validateMongoId(), getDisputeDetails);

/**
 * POST /api/disputes/:id/respond
 * Permet au mis en cause de répondre à un litige.
 */
router.post('/:id/respond', protect, validateDisputeResponse, respondToDispute);

/**
 * POST /api/disputes/:id/evidence
 * Ajoute des preuves (photos, documents) à un litige existant.
 */
router.post('/:id/evidence', protect, validateMongoId(), addEvidence);

/**
 * POST /api/disputes/:id/appeal
 * Fait appel d'une décision de litige résolu.
 */
router.post('/:id/appeal', protect, validateDisputeAppeal, appealDispute);

/**
 * POST /api/disputes/confirm-satisfaction/:reservationId
 * Le client confirme que le travail est satisfaisant (clôture le litige potentiel).
 */
router.post('/confirm-satisfaction/:reservationId', protect, authorize('client'), validateMongoId('reservationId'), confirmSatisfaction);

// --- Routes administrateur ---

/**
 * GET /api/disputes/admin/all
 * Liste tous les litiges avec filtres et pagination (admin).
 */
router.get('/admin/all', protect, authorize('admin'), validateDisputePagination, getAllDisputes);

/**
 * GET /api/disputes/admin/stats
 * Retourne les statistiques globales des litiges (admin).
 */
router.get('/admin/stats', protect, authorize('admin'), getDisputeStats);

/**
 * POST /api/disputes/:id/resolve
 * Résout un litige avec décision admin (remboursement, pénalité, etc.).
 * @param {string} req.body.decision - Décision (favor_claimant, partial_refund, etc.)
 * @param {number} [req.body.refundAmount] - Montant du remboursement
 */
router.post('/:id/resolve', protect, authorize('admin'), validateResolveDispute, resolveDispute);

/**
 * POST /api/disputes/:id/admin-note
 * Ajoute une note administrative interne à un litige.
 */
router.post('/:id/admin-note', protect, authorize('admin'), validateMongoId(), addAdminNote);

/**
 * POST /api/disputes/:id/resolve-appeal
 * Résout un appel de litige (admin).
 */
router.post('/:id/resolve-appeal', protect, authorize('admin'), validateMongoId(), resolveAppeal);

/**
 * POST /api/disputes/verify-quality/:reservationId
 * Vérifie la qualité d'un travail complété via les photos avant/après (admin).
 */
router.post('/verify-quality/:reservationId', protect, authorize('admin'), validateMongoId('reservationId'), verifyWorkQuality);

module.exports = router;
