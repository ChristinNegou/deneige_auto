/**
 * Routes pour les fonctionnalités IA avancées
 * Endpoints centralisés pour toutes les fonctions IA
 */

const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const rateLimit = require('express-rate-limit');
const mongoose = require('mongoose');

// Services IA
const photoAnalysisService = require('../services/photoAnalysisService');
const smartMatchingService = require('../services/smartMatchingService');
const demandPredictionService = require('../services/demandPredictionService');
const disputeAnalysisService = require('../services/disputeAnalysisService');

// Rate limiter pour les appels IA (10 requêtes par minute)
const aiRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: {
    success: false,
    message: 'Trop de requêtes IA. Veuillez réessayer dans une minute.',
  },
});

// Validation ObjectId
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

// ============== ANALYSE DE PHOTOS ==============

/**
 * @route   POST /api/ai/analyze-photos/:reservationId
 * @desc    Analyse les photos d'une réservation
 * @access  Worker, Admin
 */
router.post(
  '/analyze-photos/:reservationId',
  protect,
  authorize('worker', 'admin'),
  aiRateLimiter,
  async (req, res) => {
    try {
      const { reservationId } = req.params;

      if (!isValidObjectId(reservationId)) {
        return res.status(400).json({
          success: false,
          message: 'ID de réservation invalide',
        });
      }

      const analysis = await photoAnalysisService.analyzeJobPhotos(reservationId);

      res.json({
        success: true,
        data: analysis,
      });
    } catch (error) {
      console.error('Erreur analyse photos:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'analyse des photos',
        error: error.message,
      });
    }
  }
);

/**
 * @route   POST /api/ai/analyze-single-photo
 * @desc    Analyse rapide d'une seule photo
 * @access  Worker, Admin
 */
router.post(
  '/analyze-single-photo',
  protect,
  authorize('worker', 'admin'),
  aiRateLimiter,
  async (req, res) => {
    try {
      const { photoUrl, photoType } = req.body;

      if (!photoUrl) {
        return res.status(400).json({
          success: false,
          message: 'URL de photo requise',
        });
      }

      const analysis = await photoAnalysisService.analyzePhoto(photoUrl, photoType || 'after');

      res.json({
        success: true,
        data: analysis,
      });
    } catch (error) {
      console.error('Erreur analyse photo:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'analyse de la photo',
        error: error.message,
      });
    }
  }
);

// ============== MATCHING INTELLIGENT ==============

/**
 * @route   POST /api/ai/smart-match/:reservationId
 * @desc    Trouve les meilleurs workers pour une réservation
 * @access  Admin
 */
router.post(
  '/smart-match/:reservationId',
  protect,
  authorize('admin'),
  aiRateLimiter,
  async (req, res) => {
    try {
      const { reservationId } = req.params;
      const { limit } = req.body;

      if (!isValidObjectId(reservationId)) {
        return res.status(400).json({
          success: false,
          message: 'ID de réservation invalide',
        });
      }

      const matches = await smartMatchingService.findBestMatches(
        reservationId,
        limit || 3
      );

      res.json({
        success: true,
        data: matches,
      });
    } catch (error) {
      console.error('Erreur smart matching:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors du matching',
        error: error.message,
      });
    }
  }
);

/**
 * @route   POST /api/ai/auto-assign/:reservationId
 * @desc    Auto-assigne le meilleur worker
 * @access  Admin
 */
router.post(
  '/auto-assign/:reservationId',
  protect,
  authorize('admin'),
  aiRateLimiter,
  async (req, res) => {
    try {
      const { reservationId } = req.params;

      if (!isValidObjectId(reservationId)) {
        return res.status(400).json({
          success: false,
          message: 'ID de réservation invalide',
        });
      }

      const result = await smartMatchingService.autoAssignBestWorker(reservationId);

      res.json({
        success: result.success,
        message: result.success
          ? `Worker ${result.assignedWorker?.workerName} assigné avec succès`
          : result.message,
        data: result,
      });
    } catch (error) {
      console.error('Erreur auto-assign:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'assignation automatique',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/ai/matching-stats
 * @desc    Statistiques de matching
 * @access  Admin
 */
router.get('/matching-stats', protect, authorize('admin'), async (req, res) => {
  try {
    const stats = await smartMatchingService.getMatchingStats();
    res.json({ success: true, data: stats });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur récupération stats',
      error: error.message,
    });
  }
});

// ============== PRÉDICTION DE DEMANDE ==============

/**
 * @route   GET /api/ai/predict-demand/:zone
 * @desc    Prédit la demande pour une zone
 * @access  Admin
 */
router.get(
  '/predict-demand/:zone',
  protect,
  authorize('admin'),
  aiRateLimiter,
  async (req, res) => {
    try {
      const { zone } = req.params;
      const prediction = await demandPredictionService.predictDemand(zone);

      res.json({
        success: true,
        data: prediction,
      });
    } catch (error) {
      console.error('Erreur prédiction demande:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la prédiction',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/ai/predict-demand-all
 * @desc    Prédit la demande pour toutes les zones
 * @access  Admin
 */
router.get(
  '/predict-demand-all',
  protect,
  authorize('admin'),
  aiRateLimiter,
  async (req, res) => {
    try {
      const predictions = await demandPredictionService.predictAllZones();

      res.json({
        success: true,
        data: predictions,
      });
    } catch (error) {
      console.error('Erreur prédiction toutes zones:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de la prédiction',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/ai/demand-forecasts
 * @desc    Récupère les prédictions récentes
 * @access  Admin
 */
router.get('/demand-forecasts', protect, authorize('admin'), async (req, res) => {
  try {
    const { hours } = req.query;
    const forecasts = await demandPredictionService.getRecentPredictions(
      parseInt(hours) || 24
    );

    res.json({
      success: true,
      data: forecasts,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur récupération prédictions',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/ai/prediction-accuracy
 * @desc    Calcule la précision des prédictions
 * @access  Admin
 */
router.get('/prediction-accuracy', protect, authorize('admin'), async (req, res) => {
  try {
    const { days } = req.query;
    const accuracy = await demandPredictionService.calculatePredictionAccuracy(
      parseInt(days) || 7
    );

    res.json({
      success: true,
      data: accuracy,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur calcul précision',
      error: error.message,
    });
  }
});

// ============== ANALYSE DE LITIGES ==============

/**
 * @route   POST /api/ai/analyze-dispute/:disputeId
 * @desc    Analyse un litige avec IA
 * @access  Admin
 */
router.post(
  '/analyze-dispute/:disputeId',
  protect,
  authorize('admin'),
  aiRateLimiter,
  async (req, res) => {
    try {
      const { disputeId } = req.params;

      if (!isValidObjectId(disputeId)) {
        return res.status(400).json({
          success: false,
          message: 'ID de litige invalide',
        });
      }

      const analysis = await disputeAnalysisService.analyzeDispute(disputeId);

      res.json({
        success: true,
        data: analysis,
      });
    } catch (error) {
      console.error('Erreur analyse litige:', error);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'analyse du litige',
        error: error.message,
      });
    }
  }
);

/**
 * @route   GET /api/ai/pending-disputes
 * @desc    Liste les litiges en attente d'analyse
 * @access  Admin
 */
router.get('/pending-disputes', protect, authorize('admin'), async (req, res) => {
  try {
    const disputes = await disputeAnalysisService.getPendingDisputes();

    res.json({
      success: true,
      count: disputes.length,
      data: disputes,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur récupération litiges',
      error: error.message,
    });
  }
});

/**
 * @route   PUT /api/ai/dispute-reviewed/:disputeId
 * @desc    Marque une analyse comme revue par admin
 * @access  Admin
 */
router.put(
  '/dispute-reviewed/:disputeId',
  protect,
  authorize('admin'),
  async (req, res) => {
    try {
      const { disputeId } = req.params;
      const { decision } = req.body;

      if (!isValidObjectId(disputeId)) {
        return res.status(400).json({
          success: false,
          message: 'ID de litige invalide',
        });
      }

      const dispute = await disputeAnalysisService.markAsReviewed(
        disputeId,
        req.user._id,
        decision
      );

      res.json({
        success: true,
        message: 'Analyse marquée comme revue',
        data: dispute,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Erreur mise à jour',
        error: error.message,
      });
    }
  }
);

// ============== STATUT DES SERVICES IA ==============

/**
 * @route   GET /api/ai/status
 * @desc    Vérifie le statut des services IA
 * @access  Admin
 */
router.get('/status', protect, authorize('admin'), (req, res) => {
  const status = {
    photoAnalysis: process.env.AI_PHOTO_ANALYSIS_ENABLED === 'true',
    smartMatching: process.env.AI_SMART_MATCHING_ENABLED === 'true',
    demandPrediction: process.env.AI_DEMAND_PREDICTION_ENABLED === 'true',
    disputeAnalysis: process.env.AI_DISPUTE_ANALYSIS_ENABLED === 'true',
    anthropicConfigured: !!process.env.ANTHROPIC_API_KEY,
    model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
  };

  res.json({
    success: true,
    data: status,
  });
});

module.exports = router;
