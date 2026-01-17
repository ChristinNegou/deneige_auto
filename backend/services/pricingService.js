/**
 * Service d'estimation de prix dynamique avec IA
 * Calcule les prix basés sur demande, météo, urgence et localisation
 */

const Anthropic = require('@anthropic-ai/sdk');
const Reservation = require('../models/Reservation');
const DemandForecast = require('../models/DemandForecast');
const { PRICING } = require('../config/constants');

// Client Anthropic (lazy init)
let anthropicClient = null;

function getAnthropicClient() {
  if (!anthropicClient && process.env.ANTHROPIC_API_KEY) {
    anthropicClient = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }
  return anthropicClient;
}

/**
 * Tarifs de base
 */
const BASE_PRICING = {
  basePrice: 15.0,
  snowPerCm: 0.5,
  options: {
    windowScraping: 5.0,
    doorDeicing: 3.0,
    wheelClearance: 4.0,
  },
  taxes: {
    tps: 0.05,
    tvq: 0.09975,
  },
};

/**
 * Calcule le prix de base avec options
 */
function calculateBasePrice(serviceOptions = [], snowDepthCm = 0) {
  let price = BASE_PRICING.basePrice;

  // Ajouter le coût des options
  for (const option of serviceOptions) {
    if (BASE_PRICING.options[option]) {
      price += BASE_PRICING.options[option];
    }
  }

  // Supplément neige (si > 5cm)
  if (snowDepthCm > 5) {
    price += (snowDepthCm - 5) * BASE_PRICING.snowPerCm;
  }

  return price;
}

/**
 * Calcule le multiplicateur d'urgence
 */
function calculateUrgencyMultiplier(timeUntilDepartureMinutes) {
  if (timeUntilDepartureMinutes <= 30) {
    return 1.5; // Très urgent
  } else if (timeUntilDepartureMinutes <= 45) {
    return PRICING.PRIORITY_MULTIPLIER; // 1.4
  } else if (timeUntilDepartureMinutes <= 60) {
    return 1.2;
  } else if (timeUntilDepartureMinutes <= 120) {
    return 1.1;
  }
  return 1.0;
}

/**
 * Calcule le multiplicateur météo basé sur les conditions
 */
function calculateWeatherMultiplier(weatherCondition, snowDepthCm) {
  let multiplier = 1.0;

  // Conditions difficiles
  if (snowDepthCm > 20) {
    multiplier += 0.3; // Tempête de neige
  } else if (snowDepthCm > 10) {
    multiplier += 0.15;
  }

  // Températures extrêmes (supposées via la condition)
  const condition = (weatherCondition || '').toLowerCase();
  if (condition.includes('blizzard') || condition.includes('tempête')) {
    multiplier += 0.2;
  } else if (condition.includes('verglas') || condition.includes('ice')) {
    multiplier += 0.15;
  }

  return Math.min(multiplier, 1.5); // Max 50% d'augmentation météo
}

/**
 * Récupère le multiplicateur de demande depuis les prévisions
 */
async function getDemandMultiplier(location, date = new Date()) {
  try {
    const forecast = await DemandForecast.findOne({
      date: {
        $gte: new Date(date.setHours(0, 0, 0, 0)),
        $lt: new Date(date.setHours(23, 59, 59, 999)),
      },
      location: {
        $near: {
          $geometry: location,
          $maxDistance: 20000, // 20km
        },
      },
    }).sort({ createdAt: -1 });

    if (forecast) {
      return forecast.demandMultiplier || 1.0;
    }
  } catch (error) {
    console.error('Erreur récupération prévision demande:', error.message);
  }

  return 1.0;
}

/**
 * Calcule le multiplicateur de zone (zones éloignées)
 */
function calculateLocationMultiplier(distanceKm) {
  if (distanceKm > 30) {
    return 1.3; // Zone très éloignée
  } else if (distanceKm > 20) {
    return 1.2;
  } else if (distanceKm > 10) {
    return 1.1;
  }
  return 1.0;
}

/**
 * Utilise Claude pour valider et affiner l'estimation
 */
async function getAIReasoning(params, calculatedPrice) {
  const client = getAnthropicClient();
  if (!client || process.env.AI_PRICING_ENABLED !== 'true') {
    return null;
  }

  try {
    const prompt = `Tu es un expert en tarification pour un service de déneigement au Québec.

Analyse cette estimation de prix et fournis un bref commentaire (2-3 phrases max) en français:

**Paramètres:**
- Options: ${params.serviceOptions.join(', ') || 'Aucune'}
- Neige: ${params.snowDepthCm} cm
- Urgence: ${params.timeUntilDepartureMinutes} minutes avant départ
- Conditions météo: ${params.weatherCondition || 'Normal'}
- Distance zone: ${params.distanceKm || 0} km

**Prix calculé:** ${calculatedPrice.toFixed(2)}$

**Multiplicateurs appliqués:**
- Urgence: x${params.urgencyMultiplier.toFixed(2)}
- Météo: x${params.weatherMultiplier.toFixed(2)}
- Demande: x${params.demandMultiplier.toFixed(2)}
- Zone: x${params.locationMultiplier.toFixed(2)}

Donne un bref commentaire sur ce prix et si des ajustements seraient recommandés.`;

    const response = await client.messages.create({
      model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
      max_tokens: 200,
      messages: [{ role: 'user', content: prompt }],
    });

    return response.content[0].text;
  } catch (error) {
    console.error('Erreur Claude pricing:', error.message);
    return null;
  }
}

/**
 * Estime le prix pour une réservation
 * @param {Object} params - Paramètres de la réservation
 * @returns {Object} - Estimation détaillée du prix
 */
async function estimatePrice(params) {
  const {
    serviceOptions = [],
    snowDepthCm = 0,
    timeUntilDepartureMinutes = 120,
    weatherCondition = '',
    location = null,
    distanceKm = 0,
  } = params;

  // 1. Prix de base
  const basePrice = calculateBasePrice(serviceOptions, snowDepthCm);

  // 2. Calculer les multiplicateurs
  const urgencyMultiplier = calculateUrgencyMultiplier(timeUntilDepartureMinutes);
  const weatherMultiplier = calculateWeatherMultiplier(weatherCondition, snowDepthCm);
  const locationMultiplier = calculateLocationMultiplier(distanceKm);

  // 3. Multiplicateur de demande (async)
  let demandMultiplier = 1.0;
  if (location) {
    demandMultiplier = await getDemandMultiplier(location);
  }

  // 4. Calculer le prix final
  const totalMultiplier = urgencyMultiplier * weatherMultiplier * demandMultiplier * locationMultiplier;
  const priceBeforeTax = basePrice * totalMultiplier;

  // 5. Calculer les taxes
  const tps = priceBeforeTax * BASE_PRICING.taxes.tps;
  const tvq = priceBeforeTax * BASE_PRICING.taxes.tvq;
  const totalPrice = priceBeforeTax + tps + tvq;

  // 6. Calculer la fourchette de prix
  const priceRange = {
    min: Math.round(totalPrice * 0.9 * 100) / 100,
    max: Math.round(totalPrice * 1.1 * 100) / 100,
  };

  // 7. Construire les ajustements
  const adjustments = [];

  if (urgencyMultiplier > 1) {
    adjustments.push({
      type: 'urgency',
      amount: basePrice * (urgencyMultiplier - 1),
      reason: `Service urgent (${timeUntilDepartureMinutes} min)`,
    });
  }

  if (weatherMultiplier > 1) {
    adjustments.push({
      type: 'weather',
      amount: basePrice * (weatherMultiplier - 1),
      reason: `Conditions météo difficiles`,
    });
  }

  if (demandMultiplier > 1) {
    adjustments.push({
      type: 'demand',
      amount: basePrice * (demandMultiplier - 1),
      reason: `Forte demande dans la zone`,
    });
  }

  if (locationMultiplier > 1) {
    adjustments.push({
      type: 'location',
      amount: basePrice * (locationMultiplier - 1),
      reason: `Zone éloignée (${distanceKm} km)`,
    });
  }

  // 8. Obtenir le raisonnement IA (optionnel)
  const reasoning = await getAIReasoning(
    {
      serviceOptions,
      snowDepthCm,
      timeUntilDepartureMinutes,
      weatherCondition,
      distanceKm,
      urgencyMultiplier,
      weatherMultiplier,
      demandMultiplier,
      locationMultiplier,
    },
    totalPrice
  );

  return {
    basePrice: Math.round(basePrice * 100) / 100,
    priceBeforeTax: Math.round(priceBeforeTax * 100) / 100,
    taxes: {
      tps: Math.round(tps * 100) / 100,
      tvq: Math.round(tvq * 100) / 100,
    },
    suggestedPrice: Math.round(totalPrice * 100) / 100,
    priceRange,
    multipliers: {
      urgency: urgencyMultiplier,
      weather: weatherMultiplier,
      demand: demandMultiplier,
      location: locationMultiplier,
      total: Math.round(totalMultiplier * 100) / 100,
    },
    adjustments,
    reasoning,
    calculatedAt: new Date(),
  };
}

/**
 * Met à jour le pricing d'une réservation existante
 */
async function updateReservationPricing(reservationId, pricingData) {
  try {
    const reservation = await Reservation.findByIdAndUpdate(
      reservationId,
      {
        $set: {
          'pricing.basePrice': pricingData.basePrice,
          'pricing.snowMultiplier': pricingData.multipliers.weather,
          'pricing.urgencyMultiplier': pricingData.multipliers.urgency,
          'pricing.demandMultiplier': pricingData.multipliers.demand,
          'pricing.locationMultiplier': pricingData.multipliers.location,
          'pricing.calculatedPrice': pricingData.suggestedPrice,
          'pricing.suggestedPrice': pricingData.suggestedPrice,
          'pricing.priceRange': pricingData.priceRange,
          'pricing.reasoning': pricingData.reasoning,
          'pricing.adjustments': pricingData.adjustments,
        },
      },
      { new: true }
    );
    return reservation;
  } catch (error) {
    console.error('Erreur mise à jour pricing:', error.message);
    throw error;
  }
}

module.exports = {
  estimatePrice,
  updateReservationPricing,
  calculateBasePrice,
  calculateUrgencyMultiplier,
  calculateWeatherMultiplier,
  calculateLocationMultiplier,
  BASE_PRICING,
};
