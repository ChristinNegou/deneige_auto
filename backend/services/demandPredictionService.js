/**
 * Service de prédiction de demande de déneigement basé sur la météo.
 * Combine les prévisions météo (OpenWeather), l'historique des réservations
 * et l'analyse IA (Claude) pour prédire les pics de demande par zone au Québec.
 */

const Anthropic = require('@anthropic-ai/sdk');
const axios = require('axios');
const Reservation = require('../models/Reservation');
const DemandForecast = require('../models/DemandForecast');

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

// --- Configuration des zones ---

/**
 * Zones de service au Québec avec leurs coordonnées géographiques.
 */
const SERVICE_ZONES = {
  montreal: { lat: 45.5017, lon: -73.5673, name: 'Montréal' },
  laval: { lat: 45.6066, lon: -73.7124, name: 'Laval' },
  longueuil: { lat: 45.5312, lon: -73.5185, name: 'Longueuil' },
  quebec: { lat: 46.8139, lon: -71.208, name: 'Québec' },
  gatineau: { lat: 45.4765, lon: -75.7013, name: 'Gatineau' },
};

// --- Données météo ---

/**
 * Récupère les prévisions météo sur 5 jours depuis l'API OpenWeather.
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @returns {Promise<Object[]|null>} Prévisions formatées ou null en cas d'erreur
 */
async function getWeatherForecast(lat, lon) {
  const apiKey = process.env.OPENWEATHER_API_KEY;
  if (!apiKey) {
    console.warn('OPENWEATHER_API_KEY non configurée');
    return null;
  }

  try {
    const response = await axios.get(
      `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric&lang=fr`,
      { timeout: 10000 }
    );

    return response.data.list.map((item) => ({
      datetime: new Date(item.dt * 1000),
      temp: item.main.temp,
      description: item.weather[0].description,
      snowDepth: item.snow?.['3h'] || 0,
      rain: item.rain?.['3h'] || 0,
      windSpeed: item.wind.speed,
    }));
  } catch (error) {
    console.error('Erreur API météo:', error.message);
    return null;
  }
}

// --- Analyse historique ---

/**
 * Récupère l'historique agrégé des réservations par jour et par heure pour une zone.
 * @param {string} zone - Nom de la zone
 * @param {number} [daysBack=30] - Nombre de jours à analyser
 * @returns {Promise<Array>} Données agrégées { date, heure, count, avgPrice }
 */
async function getHistoricalData(zone, daysBack = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysBack);

  const reservations = await Reservation.aggregate([
    {
      $match: {
        createdAt: { $gte: startDate },
        'location.zone': zone,
        status: { $in: ['completed', 'assigned', 'inProgress'] },
      },
    },
    {
      $group: {
        _id: {
          date: { $dateToString: { format: '%Y-%m-%d', date: '$departureTime' } },
          hour: { $hour: '$departureTime' },
        },
        count: { $sum: 1 },
        avgPrice: { $avg: '$totalPrice' },
      },
    },
    { $sort: { '_id.date': 1 } },
  ]);

  return reservations;
}

/**
 * Analyse les patterns historiques pour dégager les tendances (moyenne quotidienne, heures de pointe).
 * @param {Array} historicalData - Données agrégées de getHistoricalData
 * @returns {Object} Patterns avec avgDaily, peakHours, totalReservations, daysAnalyzed
 */
function analyzeHistoricalPatterns(historicalData) {
  if (!historicalData || historicalData.length === 0) {
    return { avgDaily: 0, peakHours: [], trends: [] };
  }

  // Grouper par jour
  const dailyCounts = {};
  const hourlyCounts = Array(24).fill(0);
  const hourlyTotals = Array(24).fill(0);

  for (const entry of historicalData) {
    const date = entry._id.date;
    const hour = entry._id.hour;

    dailyCounts[date] = (dailyCounts[date] || 0) + entry.count;
    hourlyCounts[hour] += entry.count;
    hourlyTotals[hour]++;
  }

  // Moyenne quotidienne
  const dailyValues = Object.values(dailyCounts);
  const avgDaily = dailyValues.reduce((a, b) => a + b, 0) / dailyValues.length || 0;

  // Heures de pointe
  const avgHourly = hourlyCounts.map((count, i) =>
    hourlyTotals[i] > 0 ? count / hourlyTotals[i] : 0
  );

  const peakHours = avgHourly
    .map((avg, hour) => ({ hour, avg }))
    .sort((a, b) => b.avg - a.avg)
    .slice(0, 3)
    .map((p) => p.hour);

  return {
    avgDaily: Math.round(avgDaily * 10) / 10,
    peakHours,
    totalReservations: dailyValues.reduce((a, b) => a + b, 0),
    daysAnalyzed: dailyValues.length,
  };
}

// --- Calcul de la demande ---

/**
 * Calcule le niveau de demande prévu selon la neige, l'historique et les conditions météo.
 * @param {number} snowForecast - Neige prévue en cm sur 24h
 * @param {Object} historicalPatterns - Résultat de analyzeHistoricalPatterns
 * @param {string} weatherConditions - Description météo courante
 * @returns {Object} { level: 'low'|'medium'|'high'|'urgent', multiplier: number }
 */
function calculateDemandLevel(snowForecast, historicalPatterns, weatherConditions) {
  let demandScore = 0;

  // Score basé sur la neige prévue
  if (snowForecast > 20) {
    demandScore += 40; // Tempête majeure
  } else if (snowForecast > 10) {
    demandScore += 30;
  } else if (snowForecast > 5) {
    demandScore += 20;
  } else if (snowForecast > 0) {
    demandScore += 10;
  }

  // Score basé sur l'historique
  if (historicalPatterns.avgDaily > 50) {
    demandScore += 30;
  } else if (historicalPatterns.avgDaily > 20) {
    demandScore += 20;
  } else if (historicalPatterns.avgDaily > 10) {
    demandScore += 10;
  }

  // Conditions météo défavorables
  const condition = (weatherConditions || '').toLowerCase();
  if (condition.includes('blizzard') || condition.includes('tempête')) {
    demandScore += 20;
  } else if (condition.includes('verglas') || condition.includes('freezing')) {
    demandScore += 15;
  }

  // Déterminer le niveau
  if (demandScore >= 70) {
    return { level: 'urgent', multiplier: 1.8 };
  } else if (demandScore >= 50) {
    return { level: 'high', multiplier: 1.5 };
  } else if (demandScore >= 30) {
    return { level: 'medium', multiplier: 1.2 };
  }
  return { level: 'low', multiplier: 1.0 };
}

// --- Intégration IA ---

/**
 * Obtient un raisonnement IA (Claude) expliquant la prédiction de demande.
 * @param {string} zone - Nom de la zone
 * @param {Object[]} weatherForecast - Prévisions météo
 * @param {Object} historicalPatterns - Patterns historiques
 * @param {Object} demand - Niveau de demande calculé
 * @returns {Promise<string|null>} Texte d'analyse ou null si IA désactivée
 */
async function getAIPredictionReasoning(zone, weatherForecast, historicalPatterns, demand) {
  const client = getAnthropicClient();
  if (!client || process.env.AI_DEMAND_PREDICTION_ENABLED !== 'true') {
    return null;
  }

  try {
    const weatherSummary = weatherForecast
      ? weatherForecast.slice(0, 8).map((w) => `${w.datetime.toLocaleDateString()}: ${w.description}, ${w.snowDepth}cm neige`).join('\n')
      : 'Données météo non disponibles';

    const prompt = `Tu es un analyste de données pour Deneige-Auto, un service de déneigement au Québec.

**Zone:** ${zone}

**Prévisions météo (24h):**
${weatherSummary}

**Historique (30 jours):**
- Moyenne quotidienne: ${historicalPatterns.avgDaily} réservations
- Heures de pointe: ${historicalPatterns.peakHours.map((h) => `${h}h`).join(', ')}
- Total analysé: ${historicalPatterns.totalReservations} réservations

**Prédiction calculée:**
- Niveau de demande: ${demand.level}
- Multiplicateur suggéré: x${demand.multiplier}

Fournis une brève analyse (3-4 phrases) expliquant cette prédiction et les facteurs clés.`;

    const response = await client.messages.create({
      model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
      max_tokens: 300,
      messages: [{ role: 'user', content: prompt }],
    });

    return response.content[0].text;
  } catch (error) {
    console.error('Erreur Claude prédiction:', error.message);
    return null;
  }
}

// --- Fonctions principales ---

/**
 * Prédit la demande pour une zone donnée en combinant météo, historique et IA.
 * Sauvegarde la prédiction dans la collection DemandForecast.
 * @param {string} zoneName - Nom de la zone (ex: 'montreal')
 * @returns {Promise<Object>} Prédiction complète avec contexte et raisonnement
 */
async function predictDemand(zoneName) {
  const zone = SERVICE_ZONES[zoneName.toLowerCase()];
  if (!zone) {
    throw new Error(`Zone non reconnue: ${zoneName}`);
  }

  // Récupérer les données
  const [weatherForecast, historicalData] = await Promise.all([
    getWeatherForecast(zone.lat, zone.lon),
    getHistoricalData(zoneName),
  ]);

  // Analyser l'historique
  const historicalPatterns = analyzeHistoricalPatterns(historicalData);

  // Calculer la neige prévue sur 24h
  let snowForecast24h = 0;
  let weatherCondition = '';
  if (weatherForecast && weatherForecast.length > 0) {
    snowForecast24h = weatherForecast
      .slice(0, 8)
      .reduce((sum, w) => sum + (w.snowDepth || 0), 0);
    weatherCondition = weatherForecast[0].description;
  }

  // Calculer le niveau de demande
  const demand = calculateDemandLevel(snowForecast24h, historicalPatterns, weatherCondition);

  // Obtenir le raisonnement IA
  const reasoning = await getAIPredictionReasoning(
    zone.name,
    weatherForecast,
    historicalPatterns,
    demand
  );

  // Construire le résultat
  const result = {
    zone: zoneName,
    zoneName: zone.name,
    date: new Date(),
    weatherCondition,
    snowDepthForecast: Math.round(snowForecast24h * 10) / 10,
    predictedDemand: demand.level,
    demandMultiplier: demand.multiplier,
    confidence: weatherForecast ? 0.8 : 0.5,
    reasoning,
    historicalContext: historicalPatterns,
    weatherForecast: weatherForecast?.slice(0, 8) || null,
  };

  // Sauvegarder la prédiction
  await DemandForecast.create({
    date: new Date(),
    location: {
      type: 'Point',
      coordinates: [zone.lon, zone.lat],
    },
    zone: zoneName,
    weatherCondition,
    snowDepthForecast: snowForecast24h,
    predictedDemand: demand.level,
    demandMultiplier: demand.multiplier,
    confidence: result.confidence,
    reasoning,
  });

  return result;
}

/**
 * Prédit la demande pour toutes les zones de service du Québec.
 * @returns {Promise<Object>} Prédictions par zone { zoneName: prediction }
 */
async function predictAllZones() {
  const results = {};

  for (const zoneName of Object.keys(SERVICE_ZONES)) {
    try {
      results[zoneName] = await predictDemand(zoneName);
    } catch (error) {
      console.error(`Erreur prédiction ${zoneName}:`, error.message);
      results[zoneName] = { error: error.message };
    }
  }

  return results;
}

/**
 * Récupère les prédictions récentes des dernières heures.
 * @param {number} [hoursBack=24] - Nombre d'heures à remonter
 * @returns {Promise<Array>} Prédictions triées par date décroissante
 */
async function getRecentPredictions(hoursBack = 24) {
  const since = new Date();
  since.setHours(since.getHours() - hoursBack);

  return DemandForecast.find({
    createdAt: { $gte: since },
  })
    .sort({ createdAt: -1 })
    .limit(50);
}

/**
 * Calcule la précision des prédictions passées en comparant avec les réservations réelles.
 * @param {number} [daysBack=7] - Nombre de jours à évaluer
 * @returns {Promise<Array>} Résultats de précision par prédiction
 */
async function calculatePredictionAccuracy(daysBack = 7) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysBack);

  const forecasts = await DemandForecast.find({
    createdAt: { $gte: startDate },
  });

  const results = [];

  for (const forecast of forecasts) {
    // Compter les réservations réelles pour cette date/zone
    const forecastDate = new Date(forecast.date);
    const nextDay = new Date(forecastDate);
    nextDay.setDate(nextDay.getDate() + 1);

    const actualReservations = await Reservation.countDocuments({
      'location.zone': forecast.zone,
      departureTime: { $gte: forecastDate, $lt: nextDay },
      status: { $in: ['completed', 'assigned', 'inProgress'] },
    });

    // Mettre à jour la prédiction avec les données réelles
    forecast.actualReservations = actualReservations;
    await forecast.save();

    results.push({
      zone: forecast.zone,
      predicted: forecast.predictedDemand,
      actualCount: actualReservations,
    });
  }

  return results;
}

module.exports = {
  predictDemand,
  predictAllZones,
  getRecentPredictions,
  calculatePredictionAccuracy,
  SERVICE_ZONES,
};
