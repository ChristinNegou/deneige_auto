/**
 * Service d'analyse de litiges avec IA (Claude).
 * Évalue la force des preuves, l'historique des parties et recommande des décisions
 * équitables (remboursement, pénalité) pour la résolution des litiges.
 */

const Anthropic = require('@anthropic-ai/sdk');
const Dispute = require('../models/Dispute');
const Reservation = require('../models/Reservation');
const User = require('../models/User');

// --- Initialisation du client Anthropic ---

let anthropicClient = null;

function getAnthropicClient() {
  if (!anthropicClient && process.env.ANTHROPIC_API_KEY) {
    anthropicClient = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }
  return anthropicClient;
}

// --- Configuration des types de litiges ---

/**
 * Types de litiges avec leurs caractéristiques (preuves requises, résolution typique).
 */
const DISPUTE_TYPES = {
  no_show: {
    label: 'Absence du déneigeur',
    evidenceRequired: ['gps', 'timestamps'],
    typicalResolution: 'favor_claimant',
  },
  incomplete_work: {
    label: 'Travail incomplet',
    evidenceRequired: ['photos', 'client_statement'],
    typicalResolution: 'partial_refund',
  },
  quality_issue: {
    label: 'Problème de qualité',
    evidenceRequired: ['photos', 'comparison'],
    typicalResolution: 'partial_refund',
  },
  late_arrival: {
    label: 'Arrivée en retard',
    evidenceRequired: ['timestamps', 'gps'],
    typicalResolution: 'partial_refund',
  },
  damage: {
    label: 'Dommages causés',
    evidenceRequired: ['photos', 'description'],
    typicalResolution: 'favor_claimant',
  },
  wrong_location: {
    label: 'Mauvais emplacement',
    evidenceRequired: ['gps', 'photos'],
    typicalResolution: 'favor_claimant',
  },
  overcharge: {
    label: 'Surfacturation',
    evidenceRequired: ['payment_records'],
    typicalResolution: 'partial_refund',
  },
  unprofessional: {
    label: 'Comportement non professionnel',
    evidenceRequired: ['description', 'witnesses'],
    typicalResolution: 'warning',
  },
  payment_issue: {
    label: 'Problème de paiement',
    evidenceRequired: ['payment_records'],
    typicalResolution: 'investigation',
  },
};

// --- Constantes de décision ---

/** Décisions possibles pour la résolution d'un litige. */
const POSSIBLE_DECISIONS = [
  'favor_claimant',
  'favor_respondent',
  'partial_refund',
  'full_refund',
  'warning_only',
  'no_action',
  'investigation_required',
];

/** Pénalités possibles à appliquer suite à un litige. */
const POSSIBLE_PENALTIES = [
  'none',
  'warning',
  'suspension_24h',
  'suspension_3days',
  'suspension_7days',
  'suspension_permanent',
  'fee_deduction',
];

// --- Analyse des preuves ---

/**
 * Analyse la force des preuves d'un litige (photos, GPS, timestamps, réponse).
 * @param {Document} dispute - Le litige avec ses preuves
 * @param {Document} reservation - La réservation associée
 * @returns {Object} { score: number (0-100), factors: Array }
 */
function analyzeEvidenceStrength(dispute, reservation) {
  let score = 0;
  const factors = [];

  // Photos disponibles
  const evidence = dispute.evidence || {};
  const photos = evidence.photos || [];
  if (photos.length >= 2) {
    score += 20;
    factors.push({ category: 'photos', finding: `${photos.length} photos fournies`, impact: 'neutral' });
  } else if (photos.length === 1) {
    score += 10;
    factors.push({ category: 'photos', finding: '1 seule photo fournie', impact: 'neutral' });
  } else {
    factors.push({ category: 'photos', finding: 'Aucune photo', impact: 'favorable_respondent' });
  }

  // Données GPS
  if (evidence.gpsData) {
    score += 25;
    const distance = calculateGpsDistance(
      evidence.gpsData.claimantLocation,
      reservation.location?.coordinates
    );
    if (distance !== null) {
      if (distance < 0.1) {
        factors.push({
          category: 'gps',
          finding: `Position confirmée (${distance.toFixed(2)} km du site)`,
          impact: 'favorable_respondent',
        });
      } else if (distance > 1) {
        factors.push({
          category: 'gps',
          finding: `Position éloignée (${distance.toFixed(2)} km du site)`,
          impact: 'favorable_claimant',
        });
        score += 10;
      }
    }
  }

  // Timestamps cohérents
  const timestamps = evidence.timestamps || {};
  if (timestamps.workStarted && timestamps.workCompleted) {
    score += 15;
    const duration = (new Date(timestamps.workCompleted) - new Date(timestamps.workStarted)) / 60000;
    if (duration < 5) {
      factors.push({
        category: 'timestamps',
        finding: `Durée suspectement courte (${duration.toFixed(0)} min)`,
        impact: 'favorable_claimant',
      });
      score += 10;
    } else if (duration > 60) {
      factors.push({
        category: 'timestamps',
        finding: `Durée longue (${duration.toFixed(0)} min)`,
        impact: 'neutral',
      });
    } else {
      factors.push({
        category: 'timestamps',
        finding: `Durée normale (${duration.toFixed(0)} min)`,
        impact: 'favorable_respondent',
      });
    }
  }

  // Réponse du défendeur
  if (dispute.response?.text) {
    score += 10;
    factors.push({
      category: 'response',
      finding: 'Réponse du défendeur reçue',
      impact: 'neutral',
    });
  } else {
    factors.push({
      category: 'response',
      finding: 'Aucune réponse du défendeur',
      impact: 'favorable_claimant',
    });
    score += 5;
  }

  // Photos de la réservation
  const reservationPhotos = reservation.photos || [];
  const beforePhotos = reservationPhotos.filter((p) => p.type === 'before').length;
  const afterPhotos = reservationPhotos.filter((p) => p.type === 'after').length;

  if (afterPhotos > 0) {
    score += 15;
    factors.push({
      category: 'job_photos',
      finding: `${afterPhotos} photo(s) après déneigement`,
      impact: 'neutral',
    });
  } else {
    factors.push({
      category: 'job_photos',
      finding: 'Pas de photos après déneigement',
      impact: 'favorable_claimant',
    });
  }

  return { score: Math.min(score, 100), factors };
}

/**
 * Calcule la distance GPS entre deux coordonnées (Haversine).
 * @param {Object|Array} coords1 - Premières coordonnées [lon, lat] ou { lat, lng }
 * @param {Object|Array} coords2 - Secondes coordonnées
 * @returns {number|null} Distance en km ou null si données manquantes
 */
function calculateGpsDistance(coords1, coords2) {
  if (!coords1 || !coords2) return null;

  const R = 6371;
  const lat1 = coords1[1] || coords1.lat;
  const lon1 = coords1[0] || coords1.lng;
  const lat2 = coords2[1] || coords2.lat;
  const lon2 = coords2[0] || coords2.lng;

  if (!lat1 || !lon1 || !lat2 || !lon2) return null;

  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// --- Historique des parties ---

/**
 * Récupère l'historique d'un utilisateur impliqué dans un litige (litiges passés, ancienneté, etc.).
 * @param {ObjectId} userId - Identifiant de l'utilisateur
 * @param {string} role - Rôle ('client' ou 'worker')
 * @returns {Promise<Object|null>} Historique de l'utilisateur ou null
 */
async function getPartyHistory(userId, role) {
  const user = await User.findById(userId);
  if (!user) return null;

  // Compter les litiges passés
  const pastDisputes = await Dispute.countDocuments({
    $or: [{ 'claimant.user': userId }, { 'respondent.user': userId }],
    'resolution.resolvedAt': { $exists: true },
  });

  // Compter les litiges gagnés/perdus
  const disputesWon = await Dispute.countDocuments({
    [`${role === 'client' ? 'claimant' : 'respondent'}.user`]: userId,
    'resolution.decision': { $in: ['favor_claimant', 'partial_refund', 'full_refund'] },
  });

  return {
    name: `${user.firstName} ${user.lastName}`,
    role,
    rating: user.workerProfile?.averageRating || null,
    totalJobs: user.workerProfile?.totalJobsCompleted || 0,
    pastDisputes,
    disputesWon,
    accountAge: Math.floor((Date.now() - user.createdAt) / (1000 * 60 * 60 * 24)),
  };
}

// --- Recommandation initiale ---

/**
 * Détermine la recommandation de résolution initiale basée sur le type de litige et la force des preuves.
 * @param {Document} dispute - Le litige
 * @param {Object} evidenceAnalysis - Résultat de analyzeEvidenceStrength
 * @returns {string} Décision recommandée (ex: 'partial_refund', 'investigation_required')
 */
function getInitialRecommendation(dispute, evidenceAnalysis) {
  const disputeType = DISPUTE_TYPES[dispute.type];
  const typicalResolution = disputeType?.typicalResolution || 'investigation_required';

  // Ajuster selon la force des preuves
  if (evidenceAnalysis.score >= 70) {
    // Preuves solides - suivre la résolution typique
    return typicalResolution;
  } else if (evidenceAnalysis.score >= 40) {
    // Preuves moyennes - compromis
    return 'partial_refund';
  } else {
    // Preuves faibles - investigation
    return 'investigation_required';
  }
}

// --- Analyse IA principale ---

/**
 * Analyse un litige complet avec Claude : évalue les preuves, l'historique des parties,
 * et fournit une recommandation détaillée (décision, remboursement, pénalité).
 * @param {ObjectId} disputeId - Identifiant du litige à analyser
 * @returns {Promise<Object>} Résultat de l'analyse IA avec recommandations
 */
async function analyzeDispute(disputeId) {
  const client = getAnthropicClient();
  if (!client) {
    throw new Error('Claude API non configurée');
  }

  if (process.env.AI_DISPUTE_ANALYSIS_ENABLED !== 'true') {
    throw new Error('Analyse de litiges IA désactivée');
  }

  // Récupérer le litige avec toutes les données
  const dispute = await Dispute.findById(disputeId)
    .populate('claimant.user', 'firstName lastName email')
    .populate('respondent.user', 'firstName lastName email')
    .populate('reservation');

  if (!dispute) {
    throw new Error('Litige non trouvé');
  }

  const reservation = await Reservation.findById(dispute.reservation);

  // Analyser les preuves
  const evidenceAnalysis = analyzeEvidenceStrength(dispute, reservation);

  // Récupérer l'historique des parties
  const [claimantHistory, respondentHistory] = await Promise.all([
    getPartyHistory(dispute.claimant.user._id, dispute.claimant.role),
    getPartyHistory(dispute.respondent.user._id, dispute.respondent.role),
  ]);

  // Déterminer la recommandation initiale
  const initialRecommendation = getInitialRecommendation(dispute, evidenceAnalysis);

  // Construire le prompt pour Claude
  const prompt = `Tu es un médiateur expert pour Deneige-Auto, un service de déneigement au Québec.

## Litige à analyser

**Type:** ${DISPUTE_TYPES[dispute.type]?.label || dispute.type}
**Description:** ${dispute.description}
**Montant en jeu:** ${reservation?.totalPrice || 'N/A'}$

### Demandeur (${dispute.claimant.role})
- Nom: ${claimantHistory?.name}
- Ancienneté: ${claimantHistory?.accountAge} jours
- Litiges passés: ${claimantHistory?.pastDisputes}

### Défendeur (${dispute.respondent.role})
- Nom: ${respondentHistory?.name}
- Note moyenne: ${respondentHistory?.rating || 'N/A'}/5
- Jobs complétés: ${respondentHistory?.totalJobs}
- Litiges passés: ${respondentHistory?.pastDisputes}

### Preuves disponibles
Force des preuves: ${evidenceAnalysis.score}/100

${evidenceAnalysis.factors.map((f) => `- ${f.category}: ${f.finding} (${f.impact})`).join('\n')}

### Réponse du défendeur
${dispute.response?.text || 'Aucune réponse'}

### Recommandation initiale
${initialRecommendation}

## Instructions

Analyse ce litige et fournis:
1. Un score de confiance (0-100) pour ta recommandation
2. Une décision recommandée parmi: ${POSSIBLE_DECISIONS.join(', ')}
3. Un pourcentage de remboursement suggéré (0-100)
4. Une pénalité suggérée parmi: ${POSSIBLE_PENALTIES.join(', ')}
5. Les facteurs de risque identifiés
6. Un raisonnement détaillé (3-5 phrases)

Réponds en JSON:
{
  "confidence": 75,
  "recommendedDecision": "partial_refund",
  "suggestedRefundPercent": 50,
  "suggestedPenalty": "warning",
  "riskFactors": ["client_récidiviste", "preuves_insuffisantes"],
  "reasoning": "Explication détaillée..."
}`;

  try {
    const response = await client.messages.create({
      model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
      max_tokens: 800,
      messages: [{ role: 'user', content: prompt }],
    });

    const responseText = response.content[0].text;

    // Parser la réponse
    let aiAnalysis;
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        aiAnalysis = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('Pas de JSON dans la réponse');
      }
    } catch (parseError) {
      console.error('Erreur parsing JSON:', parseError.message);
      aiAnalysis = {
        confidence: 50,
        recommendedDecision: initialRecommendation,
        suggestedRefundPercent: 50,
        suggestedPenalty: 'warning',
        riskFactors: ['analyse_incomplète'],
        reasoning: responseText.slice(0, 500),
      };
    }

    // Construire le résultat final
    const result = {
      evidenceStrength: evidenceAnalysis.score,
      recommendedDecision: aiAnalysis.recommendedDecision,
      confidence: aiAnalysis.confidence / 100,
      reasoning: aiAnalysis.reasoning,
      riskFactors: aiAnalysis.riskFactors || [],
      suggestedRefundPercent: aiAnalysis.suggestedRefundPercent,
      suggestedPenalty: aiAnalysis.suggestedPenalty,
      keyFindings: evidenceAnalysis.factors,
      analyzedAt: new Date(),
      reviewedByAdmin: false,
      claimantHistory,
      respondentHistory,
    };

    // Mettre à jour le litige
    await Dispute.findByIdAndUpdate(disputeId, {
      $set: { aiAnalysis: result },
    });

    return result;
  } catch (error) {
    console.error('Erreur analyse Claude:', error.message);
    throw error;
  }
}

// --- Fonctions de gestion ---

/**
 * Récupère les litiges non résolus et non encore analysés par l'IA ou non revus par un admin.
 * @returns {Promise<Array>} Litiges en attente, triés par date de création
 */
async function getPendingDisputes() {
  return Dispute.find({
    'resolution.resolvedAt': { $exists: false },
    $or: [
      { aiAnalysis: { $exists: false } },
      { 'aiAnalysis.reviewedByAdmin': false },
    ],
  })
    .populate('claimant.user', 'firstName lastName')
    .populate('respondent.user', 'firstName lastName')
    .sort({ createdAt: 1 });
}

/**
 * Marque l'analyse IA d'un litige comme revue par un administrateur.
 * @param {ObjectId} disputeId - Identifiant du litige
 * @param {ObjectId} adminId - Identifiant de l'administrateur
 * @param {string} decision - Décision finale de l'admin
 * @returns {Promise<Document>} Le litige mis à jour
 */
async function markAsReviewed(disputeId, adminId, decision) {
  return Dispute.findByIdAndUpdate(
    disputeId,
    {
      $set: {
        'aiAnalysis.reviewedByAdmin': true,
        'aiAnalysis.reviewedBy': adminId,
        'aiAnalysis.reviewedAt': new Date(),
        'aiAnalysis.adminDecision': decision,
      },
    },
    { new: true }
  );
}

module.exports = {
  analyzeDispute,
  getPendingDisputes,
  markAsReviewed,
  analyzeEvidenceStrength,
  DISPUTE_TYPES,
  POSSIBLE_DECISIONS,
  POSSIBLE_PENALTIES,
};
