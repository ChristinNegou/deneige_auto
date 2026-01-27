/**
 * Service de matching intelligent déneigeur-réservation.
 * Attribue le meilleur déneigeur selon un scoring multi-critères (distance, note, équipement)
 * avec validation optionnelle par IA (Claude).
 */

const Anthropic = require('@anthropic-ai/sdk');
const User = require('../models/User');
const Reservation = require('../models/Reservation');

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

// --- Configuration des poids de scoring ---

/**
 * Poids des critères de scoring (total = 1.0).
 */
const SCORING_WEIGHTS = {
  distance: 0.20,
  availability: 0.25,
  rating: 0.20,
  equipment: 0.15,
  experience: 0.10,
  specialization: 0.10,
};

// --- Fonctions utilitaires ---

/**
 * Détermine l'équipement requis selon les options de service et la profondeur de neige.
 * @param {Object} reservation - Réservation avec serviceOptions et snowDepthCm
 * @returns {string[]} Liste des équipements requis
 */
function getRequiredEquipment(reservation) {
  const required = ['shovel', 'brush'];

  if (reservation.serviceOptions?.includes('windowScraping')) {
    required.push('ice_scraper');
  }

  if (reservation.snowDepthCm > 15) {
    required.push('snow_blower');
  }

  return required;
}

/**
 * Vérifie si le déneigeur possède tout l'équipement requis.
 * @param {string[]} workerEquipment - Équipement du déneigeur
 * @param {string[]} requiredEquipment - Équipement requis
 * @returns {boolean} true si tout l'équipement est disponible
 */
function hasRequiredEquipment(workerEquipment, requiredEquipment) {
  return requiredEquipment.every((eq) => workerEquipment.includes(eq));
}

/**
 * Calcule la distance entre deux points géographiques (formule de Haversine).
 * @param {number} lat1 - Latitude du point 1
 * @param {number} lon1 - Longitude du point 1
 * @param {number} lat2 - Latitude du point 2
 * @param {number} lon2 - Longitude du point 2
 * @returns {number} Distance en kilomètres
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Rayon de la Terre en km
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

// --- Fonctions de scoring ---

/**
 * Score de distance (0-100). Plus le déneigeur est proche, plus le score est élevé.
 * @param {number} distanceKm - Distance en km
 * @param {number} [maxDistance=50] - Distance maximale considérée
 * @returns {number} Score entre 0 et 100
 */
function scoreDistance(distanceKm, maxDistance = 50) {
  if (distanceKm > maxDistance) return 0;
  return Math.round(100 * (1 - distanceKm / maxDistance));
}

/**
 * Score de disponibilité (0-100)
 */
function scoreAvailability(activeJobs, maxActiveJobs) {
  if (activeJobs >= maxActiveJobs) return 0;
  const usageRatio = activeJobs / maxActiveJobs;
  return Math.round(100 * (1 - usageRatio));
}

/**
 * Score de rating (0-100)
 */
function scoreRating(rating, totalJobs) {
  if (!rating || totalJobs < 3) return 50; // Nouveau worker = score neutre
  return Math.round(rating * 20); // Note sur 5 → score sur 100
}

/**
 * Score d'équipement (0 ou 100)
 */
function scoreEquipment(workerEquipment, requiredEquipment) {
  return hasRequiredEquipment(workerEquipment, requiredEquipment) ? 100 : 0;
}

/**
 * Score d'expérience (0-100)
 */
function scoreExperience(totalJobs, cancellations) {
  const completionRate = totalJobs > 0 ? (totalJobs - cancellations) / totalJobs : 1;
  const experiencePoints = Math.min(totalJobs / 50, 1); // Max à 50 jobs
  return Math.round(50 * completionRate + 50 * experiencePoints);
}

/**
 * Score de spécialisation (0-100)
 */
async function scoreSpecialization(workerId, zone) {
  try {
    // Compter les jobs complétés dans la zone
    const jobsInZone = await Reservation.countDocuments({
      worker: workerId,
      status: 'completed',
      'location.zone': zone,
    });

    return Math.min(jobsInZone * 10, 100); // 10 jobs max pour score 100
  } catch {
    return 0;
  }
}

// --- Calcul du score global ---

/**
 * Calcule le score global de compatibilité d'un déneigeur pour une réservation.
 * @param {Document} worker - Profil complet du déneigeur
 * @param {Document} reservation - Réservation à assigner
 * @returns {Promise<Object>} Résultat avec score, facteurs détaillés et distance
 */
async function calculateWorkerScore(worker, reservation) {
  const workerProfile = worker.workerProfile || {};
  const requiredEquipment = getRequiredEquipment(reservation);

  // Calculer la distance
  let distanceKm = 50; // Par défaut, distance max
  if (workerProfile.currentLocation?.coordinates && reservation.location?.coordinates) {
    const [workerLon, workerLat] = workerProfile.currentLocation.coordinates;
    const [jobLon, jobLat] = reservation.location.coordinates;
    distanceKm = calculateDistance(workerLat, workerLon, jobLat, jobLon);
  }

  // Calculer les scores individuels
  const factors = {
    distance: {
      value: distanceKm,
      score: scoreDistance(distanceKm),
    },
    availability: {
      value: workerProfile.activeJobsCount || 0,
      score: scoreAvailability(
        workerProfile.activeJobsCount || 0,
        workerProfile.maxActiveJobs || 3
      ),
    },
    rating: {
      value: workerProfile.averageRating || 0,
      score: scoreRating(workerProfile.averageRating, workerProfile.totalJobsCompleted),
    },
    equipment: {
      value: hasRequiredEquipment(workerProfile.equipmentList || [], requiredEquipment),
      score: scoreEquipment(workerProfile.equipmentList || [], requiredEquipment),
    },
    experience: {
      value: workerProfile.totalJobsCompleted || 0,
      score: scoreExperience(
        workerProfile.totalJobsCompleted || 0,
        workerProfile.totalCancellations || 0
      ),
    },
    specialization: {
      value: 0,
      score: await scoreSpecialization(worker._id, reservation.location?.zone),
    },
  };

  // Calculer le score pondéré
  let totalScore = 0;
  for (const [factor, weight] of Object.entries(SCORING_WEIGHTS)) {
    totalScore += factors[factor].score * weight;
  }

  return {
    workerId: worker._id,
    workerName: `${worker.firstName} ${worker.lastName}`,
    score: Math.round(totalScore),
    factors,
    distanceKm: Math.round(distanceKm * 10) / 10,
  };
}

// --- Intégration IA ---

/**
 * Obtient un raisonnement IA (Claude) pour justifier les recommandations de matching.
 * @param {Object[]} topCandidates - Top candidats avec leurs scores
 * @param {Document} reservation - Réservation concernée
 * @returns {Promise<string|null>} Texte de raisonnement ou null si IA désactivée
 */
async function getAIReasoning(topCandidates, reservation) {
  const client = getAnthropicClient();
  if (!client || process.env.AI_SMART_MATCHING_ENABLED !== 'true') {
    return null;
  }

  try {
    const candidatesSummary = topCandidates
      .map(
        (c, i) => `${i + 1}. ${c.workerName}
   - Score global: ${c.score}/100
   - Distance: ${c.distanceKm} km
   - Note: ${c.factors.rating.value || 'N/A'}/5
   - Équipement OK: ${c.factors.equipment.value ? 'Oui' : 'Non'}
   - Jobs complétés: ${c.factors.experience.value}`
      )
      .join('\n\n');

    const prompt = `Tu es un expert en gestion de déneigeurs pour Deneige-Auto.

**Réservation:**
- Adresse: ${reservation.displayAddress || 'Non spécifiée'}
- Heure de départ: ${reservation.departureTime}
- Options: ${reservation.serviceOptions?.join(', ') || 'Standard'}
- Priorité: ${reservation.isPriority ? 'Oui' : 'Non'}

**Top 3 candidats:**
${candidatesSummary}

Fournis une brève recommandation (3-4 phrases) expliquant pourquoi le candidat #1 est le meilleur choix, et mentionne les alternatives si pertinent.`;

    const response = await client.messages.create({
      model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
      max_tokens: 300,
      messages: [{ role: 'user', content: prompt }],
    });

    return response.content[0].text;
  } catch (error) {
    console.error('Erreur Claude matching:', error.message);
    return null;
  }
}

// --- Fonctions principales ---

/**
 * Trouve les meilleurs déneigeurs disponibles pour une réservation et sauvegarde le résultat.
 * @param {ObjectId} reservationId - Identifiant de la réservation
 * @param {number} [limit=3] - Nombre maximum de candidats à retourner
 * @returns {Promise<Object>} Résultat avec suggestedWorkers, reasoning et statistiques
 */
async function findBestMatches(reservationId, limit = 3) {
  // Récupérer la réservation
  const reservation = await Reservation.findById(reservationId);
  if (!reservation) {
    throw new Error('Réservation non trouvée');
  }

  // Récupérer les workers disponibles
  const requiredEquipment = getRequiredEquipment(reservation);

  const workers = await User.find({
    role: 'worker',
    'workerProfile.isAvailable': true,
    'workerProfile.isSuspended': { $ne: true },
    'workerProfile.equipmentList': { $all: requiredEquipment },
  });

  if (workers.length === 0) {
    return {
      success: false,
      message: 'Aucun déneigeur disponible avec l\'équipement requis',
      suggestedWorkers: [],
    };
  }

  // Calculer les scores pour chaque worker
  const scoredWorkers = await Promise.all(
    workers.map((worker) => calculateWorkerScore(worker, reservation))
  );

  // Trier par score décroissant
  scoredWorkers.sort((a, b) => b.score - a.score);

  // Prendre les top N
  const topCandidates = scoredWorkers.slice(0, limit);

  // Ajouter le ranking
  topCandidates.forEach((candidate, index) => {
    candidate.ranking = index + 1;
  });

  // Obtenir le raisonnement IA
  const reasoning = await getAIReasoning(topCandidates, reservation);

  // Construire le résultat
  const result = {
    success: true,
    reservationId,
    suggestedWorkers: topCandidates.map((c) => ({
      workerId: c.workerId,
      workerName: c.workerName,
      score: c.score,
      ranking: c.ranking,
      factors: c.factors,
      distanceKm: c.distanceKm,
    })),
    reasoning,
    matchedAt: new Date(),
    totalCandidatesEvaluated: scoredWorkers.length,
  };

  // Sauvegarder dans la réservation
  await Reservation.findByIdAndUpdate(reservationId, {
    $set: {
      matchDetails: {
        suggestedWorkers: result.suggestedWorkers,
        matchedAt: result.matchedAt,
        autoAssigned: false,
      },
    },
  });

  return result;
}

/**
 * Auto-assigne le meilleur déneigeur disponible à une réservation.
 * @param {ObjectId} reservationId - Identifiant de la réservation
 * @returns {Promise<Object>} Résultat avec le déneigeur assigné ou message d'erreur
 */
async function autoAssignBestWorker(reservationId) {
  const matchResult = await findBestMatches(reservationId, 1);

  if (!matchResult.success || matchResult.suggestedWorkers.length === 0) {
    return {
      success: false,
      message: matchResult.message || 'Aucun worker disponible',
    };
  }

  const bestWorker = matchResult.suggestedWorkers[0];

  // Assigner le worker
  const reservation = await Reservation.findByIdAndUpdate(
    reservationId,
    {
      $set: {
        worker: bestWorker.workerId,
        status: 'assigned',
        'matchDetails.autoAssigned': true,
      },
    },
    { new: true }
  );

  return {
    success: true,
    assignedWorker: bestWorker,
    reservation,
  };
}

/**
 * Récupère les statistiques agrégées du matching (total, auto-assignés, score moyen).
 * @returns {Promise<Object>} Statistiques de matching
 */
async function getMatchingStats() {
  const stats = await Reservation.aggregate([
    { $match: { 'matchDetails.matchedAt': { $exists: true } } },
    {
      $group: {
        _id: null,
        totalMatched: { $sum: 1 },
        autoAssigned: {
          $sum: { $cond: ['$matchDetails.autoAssigned', 1, 0] },
        },
        avgScore: { $avg: { $arrayElemAt: ['$matchDetails.suggestedWorkers.score', 0] } },
      },
    },
  ]);

  return stats[0] || { totalMatched: 0, autoAssigned: 0, avgScore: 0 };
}

module.exports = {
  findBestMatches,
  autoAssignBestWorker,
  calculateWorkerScore,
  getMatchingStats,
  SCORING_WEIGHTS,
};
