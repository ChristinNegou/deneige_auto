/**
 * Modèle Mongoose pour les prédictions de demande de déneigement.
 * Stocke les prévisions météo, le niveau de demande par zone et la précision des prédictions.
 */

const mongoose = require('mongoose');

// --- Schéma principal ---

const demandForecastSchema = new mongoose.Schema(
  {
    // Date de la prédiction
    date: {
      type: Date,
      required: true,
      index: true,
    },

    // Localisation (pour requêtes géospatiales)
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },

    // Zone de service
    zone: {
      type: String,
      required: true,
      enum: ['montreal', 'laval', 'longueuil', 'quebec', 'gatineau'],
      index: true,
    },

    // Conditions météo
    weatherCondition: {
      type: String,
      default: '',
    },

    // Neige prévue (cm sur 24h)
    snowDepthForecast: {
      type: Number,
      default: 0,
    },

    // Niveau de demande prédit
    predictedDemand: {
      type: String,
      enum: ['low', 'medium', 'high', 'urgent'],
      default: 'low',
    },

    // Multiplicateur de demande (1.0 - 2.0)
    demandMultiplier: {
      type: Number,
      default: 1.0,
      min: 1.0,
      max: 2.0,
    },

    // Confiance dans la prédiction (0-1)
    confidence: {
      type: Number,
      default: 0.5,
      min: 0,
      max: 1,
    },

    // Raisonnement IA
    reasoning: {
      type: String,
      default: '',
    },

    // Réservations réelles (pour calcul de précision)
    actualReservations: {
      type: Number,
      default: null,
    },

    // Précision de la prédiction (calculée après coup)
    accuracy: {
      type: Number,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// --- Index ---

demandForecastSchema.index({ location: '2dsphere' });

// Index composé pour recherches par date et zone
demandForecastSchema.index({ date: 1, zone: 1 });

// TTL: supprimer après 30 jours
demandForecastSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

// --- Méthodes statiques ---

/**
 * Récupère la prédiction la plus récente pour une zone donnée.
 * @param {string} zone - Nom de la zone (ex: 'montreal', 'laval')
 * @returns {Promise<Document|null>} Dernière prédiction ou null
 */
demandForecastSchema.statics.getLatestForZone = async function (zone) {
  return this.findOne({ zone })
    .sort({ createdAt: -1 })
    .limit(1);
};

/**
 * Récupère toutes les prédictions de la journée courante.
 * @returns {Promise<Array>} Prédictions triées par zone
 */
demandForecastSchema.statics.getTodayForecasts = async function () {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  return this.find({
    date: { $gte: today, $lt: tomorrow },
  }).sort({ zone: 1 });
};

// --- Méthodes d'instance ---

/**
 * Calcule la précision de la prédiction en comparant avec les réservations réelles.
 * @returns {number|null} Précision entre 0 et 1, ou null si pas de données réelles
 */
demandForecastSchema.methods.calculateAccuracy = function () {
  if (this.actualReservations === null) return null;

  // Mapper le niveau prédit à un nombre attendu
  const expectedRanges = {
    low: { min: 0, max: 10 },
    medium: { min: 10, max: 30 },
    high: { min: 30, max: 60 },
    urgent: { min: 60, max: Infinity },
  };

  const range = expectedRanges[this.predictedDemand];
  const actual = this.actualReservations;

  if (actual >= range.min && actual <= range.max) {
    return 1.0; // Prédiction exacte
  }

  // Calculer l'écart relatif
  const midpoint = (range.min + Math.min(range.max, 100)) / 2;
  const deviation = Math.abs(actual - midpoint) / midpoint;

  return Math.max(0, 1 - deviation);
};

module.exports = mongoose.model('DemandForecast', demandForecastSchema);
