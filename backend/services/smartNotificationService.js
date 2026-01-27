/**
 * Service de notifications intelligentes pour le suivi en temps réel.
 * Génère des messages contextuels (ETA, alertes météo, rappels) et les envoie via FCM.
 */

const { sendPushNotification } = require('./firebaseService');
const Reservation = require('../models/Reservation');
const User = require('../models/User');
const axios = require('axios');

// --- Configuration ---

/** Temps de base estimé par type de véhicule (en minutes). */
const BASE_TIME_BY_VEHICLE = {
  compact: 8,
  sedan: 10,
  suv: 12,
  truck: 15,
  minivan: 12,
  unknown: 10,
};

/**
 * Calcule le temps estimé pour un travail de déneigement
 * @param {Object} params - Paramètres du travail
 * @param {string} params.vehicleType - Type de véhicule
 * @param {number} params.snowDepthCm - Profondeur de neige en cm
 * @param {Array} params.serviceOptions - Options de service sélectionnées
 * @returns {Object} - { estimatedMinutes, breakdown }
 */
function calculateEstimatedTime({ vehicleType = 'sedan', snowDepthCm = 5, serviceOptions = [] }) {
  // Temps de base selon le type de véhicule
  let baseMinutes = BASE_TIME_BY_VEHICLE[vehicleType] || BASE_TIME_BY_VEHICLE.sedan;

  // Ajout selon la profondeur de neige
  const snowMultiplier = 1 + (snowDepthCm / 20); // +50% pour 10cm, +100% pour 20cm
  baseMinutes = Math.round(baseMinutes * snowMultiplier);

  // Temps supplémentaire pour les options
  let optionsTime = 0;
  if (serviceOptions.includes('windowScraping')) optionsTime += 3;
  if (serviceOptions.includes('doorDeicing')) optionsTime += 2;
  if (serviceOptions.includes('wheelClearance')) optionsTime += 4;

  const totalMinutes = baseMinutes + optionsTime;

  return {
    estimatedMinutes: totalMinutes,
    breakdown: {
      baseTime: BASE_TIME_BY_VEHICLE[vehicleType] || 10,
      snowAdjustment: Math.round((snowMultiplier - 1) * 100),
      optionsTime,
    },
  };
}

/** Types de notifications intelligentes supportés. */
const NOTIFICATION_TYPES = {
  ETA_UPDATE: 'eta_update',
  WORKER_ASSIGNED: 'worker_assigned',
  WORKER_EN_ROUTE: 'worker_en_route',
  WORKER_ARRIVED: 'worker_arrived',
  JOB_STARTED: 'job_started',
  JOB_COMPLETED: 'job_completed',
  WEATHER_ALERT: 'weather_alert',
  DELAY_RISK: 'delay_risk',
  REMINDER: 'reminder',
};

// --- Calculs utilitaires ---

/**
 * Calcule l'ETA basé sur la position du déneigeur et la destination (Haversine, 30 km/h en hiver).
 * @param {Object} workerLocation - Position du déneigeur { lat, lng }
 * @param {Object} destinationLocation - Position de destination { lat, lng }
 * @returns {Promise<Object>} { etaMinutes, distanceKm }
 */
async function calculateETA(workerLocation, destinationLocation) {
  try {
    // Calcul simple avec Haversine (peut être remplacé par Google Maps API)
    const R = 6371;
    const dLat = ((destinationLocation.lat - workerLocation.lat) * Math.PI) / 180;
    const dLon = ((destinationLocation.lng - workerLocation.lng) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((workerLocation.lat * Math.PI) / 180) *
        Math.cos((destinationLocation.lat * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distanceKm = R * c;

    // Estimation: 30 km/h en ville en hiver
    const avgSpeedKmh = 30;
    const etaMinutes = Math.round((distanceKm / avgSpeedKmh) * 60);

    return {
      etaMinutes,
      distanceKm: Math.round(distanceKm * 10) / 10,
    };
  } catch (error) {
    console.error('Erreur calcul ETA:', error.message);
    return { etaMinutes: 15, distanceKm: 5 }; // Valeurs par défaut
  }
}

// --- Génération de messages ---

/**
 * Génère le titre et le corps d'une notification intelligente selon le type et le contexte.
 * @param {string} type - Type de notification (voir NOTIFICATION_TYPES)
 * @param {Object} context - Données contextuelles (workerName, etaMinutes, etc.)
 * @returns {Object} { title, body }
 */
function generateNotificationMessage(type, context) {
  const {
    etaMinutes,
    workerName,
    vehicleType,
    estimatedJobMinutes,
    weatherCondition,
    delayMinutes,
    completionTime,
  } = context;

  switch (type) {
    case NOTIFICATION_TYPES.ETA_UPDATE:
      if (etaMinutes <= 5) {
        return {
          title: '🚗 Arrivée imminente!',
          body: `${workerName} arrive dans moins de 5 minutes.`,
        };
      } else if (etaMinutes <= 10) {
        return {
          title: '🚗 Bientôt là!',
          body: `Votre déneigeur ${workerName} arrive dans environ ${etaMinutes} minutes.`,
        };
      }
      return {
        title: '📍 En route vers vous',
        body: `${workerName} sera là dans environ ${etaMinutes} minutes.`,
      };

    case NOTIFICATION_TYPES.WORKER_ASSIGNED:
      return {
        title: '✅ Déneigeur assigné!',
        body: `${workerName} s'occupera de votre ${vehicleType || 'véhicule'}. Temps estimé: ~${estimatedJobMinutes} min.`,
      };

    case NOTIFICATION_TYPES.WORKER_EN_ROUTE:
      return {
        title: '🚗 Déneigeur en route',
        body: `${workerName} est parti et arrivera dans ~${etaMinutes} minutes.`,
      };

    case NOTIFICATION_TYPES.WORKER_ARRIVED:
      return {
        title: '📍 Déneigeur arrivé!',
        body: `${workerName} est arrivé et commence le déneigement de votre véhicule.`,
      };

    case NOTIFICATION_TYPES.JOB_STARTED:
      return {
        title: '❄️ Déneigement en cours',
        body: `Votre véhicule est en cours de déneigement. Durée estimée: ~${estimatedJobMinutes} min.`,
      };

    case NOTIFICATION_TYPES.JOB_COMPLETED:
      return {
        title: '✨ Déneigement terminé!',
        body: `Votre véhicule est prêt! Durée totale: ${completionTime} min. Bonne route!`,
      };

    case NOTIFICATION_TYPES.WEATHER_ALERT:
      return {
        title: '⚠️ Alerte météo',
        body: `Conditions difficiles (${weatherCondition}). Possible délai de ${delayMinutes} min sur votre service.`,
      };

    case NOTIFICATION_TYPES.DELAY_RISK:
      return {
        title: '⏰ Risque de retard',
        body: `En raison de la forte demande, un délai de ~${delayMinutes} min est possible.`,
      };

    case NOTIFICATION_TYPES.REMINDER:
      return {
        title: '🔔 Rappel',
        body: `Votre déneigement est prévu dans ${etaMinutes} minutes. Votre déneigeur est prêt!`,
      };

    default:
      return {
        title: 'Deneige-Auto',
        body: 'Mise à jour de votre réservation.',
      };
  }
}

// --- Envoi de notifications ---

/**
 * Envoie une notification intelligente push (FCM) à un utilisateur.
 * @param {ObjectId} userId - Identifiant de l'utilisateur destinataire
 * @param {string} type - Type de notification
 * @param {Object} context - Données contextuelles pour le message
 * @returns {Promise<Object>} Résultat de l'envoi
 */
async function sendSmartNotification(userId, type, context) {
  try {
    const user = await User.findById(userId);
    if (!user || !user.fcmToken) {
      console.log('Pas de token FCM pour l\'utilisateur:', userId);
      return { success: false, reason: 'no_fcm_token' };
    }

    const message = generateNotificationMessage(type, context);

    const result = await sendPushNotification(
      user.fcmToken,
      message.title,
      message.body,
      {
        type,
        reservationId: context.reservationId || '',
        ...context,
      }
    );

    // Logger la notification
    console.log(`📱 Notification [${type}] envoyée à ${user.firstName}: ${message.title}`);

    return result;
  } catch (error) {
    console.error('Erreur envoi notification intelligente:', error.message);
    return { success: false, error: error.message };
  }
}

// --- Notifications par événement ---

/**
 * Notifie le client de l'ETA du déneigeur en calculant la distance et le temps estimé.
 * @param {ObjectId} reservationId - Identifiant de la réservation
 * @returns {Promise<Object>} Résultat de l'envoi
 */
async function notifyClientETA(reservationId) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken')
      .populate('worker', 'firstName workerProfile');

    if (!reservation || !reservation.worker || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    const workerLocation = reservation.worker.workerProfile?.currentLocation;
    const jobLocation = reservation.location;

    if (!workerLocation || !jobLocation) {
      return { success: false, reason: 'missing_location' };
    }

    // Calculer l'ETA
    const eta = await calculateETA(
      { lat: workerLocation.coordinates[1], lng: workerLocation.coordinates[0] },
      { lat: jobLocation.coordinates[1], lng: jobLocation.coordinates[0] }
    );

    // Calculer le temps de travail estimé
    const timeEstimation = calculateEstimatedTime({
      vehicleType: reservation.vehicleType || 'sedan',
      snowDepthCm: reservation.snowDepthCm || 5,
      serviceOptions: reservation.serviceOptions || [],
    });

    // Envoyer la notification
    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.ETA_UPDATE,
      {
        reservationId: reservationId.toString(),
        etaMinutes: eta.etaMinutes,
        workerName: reservation.worker.firstName,
        estimatedJobMinutes: timeEstimation.estimatedMinutes,
      }
    );
  } catch (error) {
    console.error('Erreur notification ETA:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Notifie le client que le worker est assigné
 */
async function notifyWorkerAssigned(reservationId) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken')
      .populate('worker', 'firstName workerProfile');

    if (!reservation || !reservation.worker || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    const timeEstimation = calculateEstimatedTime({
      vehicleType: reservation.vehicleType || 'sedan',
      snowDepthCm: reservation.snowDepthCm || 5,
      serviceOptions: reservation.serviceOptions || [],
    });

    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.WORKER_ASSIGNED,
      {
        reservationId: reservationId.toString(),
        workerName: reservation.worker.firstName,
        vehicleType: getVehicleTypeLabel(reservation.vehicleType),
        estimatedJobMinutes: timeEstimation.estimatedMinutes,
      }
    );
  } catch (error) {
    console.error('Erreur notification worker assigné:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Notifie le client que le worker est en route
 */
async function notifyWorkerEnRoute(reservationId) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken')
      .populate('worker', 'firstName workerProfile');

    if (!reservation || !reservation.worker || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    const workerLocation = reservation.worker.workerProfile?.currentLocation;
    const jobLocation = reservation.location;

    let etaMinutes = 15; // Par défaut
    if (workerLocation && jobLocation) {
      const eta = await calculateETA(
        { lat: workerLocation.coordinates[1], lng: workerLocation.coordinates[0] },
        { lat: jobLocation.coordinates[1], lng: jobLocation.coordinates[0] }
      );
      etaMinutes = eta.etaMinutes;
    }

    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.WORKER_EN_ROUTE,
      {
        reservationId: reservationId.toString(),
        workerName: reservation.worker.firstName,
        etaMinutes,
      }
    );
  } catch (error) {
    console.error('Erreur notification en route:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Notifie le client que le worker est arrivé
 */
async function notifyWorkerArrived(reservationId) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken')
      .populate('worker', 'firstName');

    if (!reservation || !reservation.worker || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.WORKER_ARRIVED,
      {
        reservationId: reservationId.toString(),
        workerName: reservation.worker.firstName,
      }
    );
  } catch (error) {
    console.error('Erreur notification arrivée:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Notifie le client que le travail a commencé
 */
async function notifyJobStarted(reservationId) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken');

    if (!reservation || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    const timeEstimation = calculateEstimatedTime({
      vehicleType: reservation.vehicleType || 'sedan',
      snowDepthCm: reservation.snowDepthCm || 5,
      serviceOptions: reservation.serviceOptions || [],
    });

    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.JOB_STARTED,
      {
        reservationId: reservationId.toString(),
        estimatedJobMinutes: timeEstimation.estimatedMinutes,
      }
    );
  } catch (error) {
    console.error('Erreur notification job started:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Notifie le client que le travail est terminé
 */
async function notifyJobCompleted(reservationId, actualDurationMinutes) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken');

    if (!reservation || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.JOB_COMPLETED,
      {
        reservationId: reservationId.toString(),
        completionTime: actualDurationMinutes || '~',
      }
    );
  } catch (error) {
    console.error('Erreur notification job completed:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Notifie le client d'une alerte météo
 */
async function notifyWeatherAlert(reservationId, weatherCondition, delayMinutes) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken');

    if (!reservation || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.WEATHER_ALERT,
      {
        reservationId: reservationId.toString(),
        weatherCondition,
        delayMinutes,
      }
    );
  } catch (error) {
    console.error('Erreur notification météo:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Notifie le client d'un risque de retard
 */
async function notifyDelayRisk(reservationId, delayMinutes, reason) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken');

    if (!reservation || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.DELAY_RISK,
      {
        reservationId: reservationId.toString(),
        delayMinutes,
        reason,
      }
    );
  } catch (error) {
    console.error('Erreur notification retard:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Envoie un rappel au client
 */
async function sendReminder(reservationId, minutesUntilService) {
  try {
    const reservation = await Reservation.findById(reservationId)
      .populate('client', 'firstName fcmToken');

    if (!reservation || !reservation.client) {
      return { success: false, reason: 'missing_data' };
    }

    return await sendSmartNotification(
      reservation.client._id,
      NOTIFICATION_TYPES.REMINDER,
      {
        reservationId: reservationId.toString(),
        etaMinutes: minutesUntilService,
      }
    );
  } catch (error) {
    console.error('Erreur notification rappel:', error.message);
    return { success: false, error: error.message };
  }
}

// --- Fonctions utilitaires ---

/**
 * Convertit le type de véhicule en libellé français.
 * @param {string} vehicleType - Type technique (ex: 'suv', 'truck')
 * @returns {string} Libellé en français (ex: 'VUS', 'camion')
 */
function getVehicleTypeLabel(vehicleType) {
  const labels = {
    compact: 'voiture compacte',
    sedan: 'berline',
    suv: 'VUS',
    truck: 'camion',
    minivan: 'fourgonnette',
    unknown: 'véhicule',
  };
  return labels[vehicleType] || labels.unknown;
}

// --- Vérification météo ---

/**
 * Vérifie les conditions météo actuelles et envoie des alertes aux réservations concernées.
 * Peut être appelé par un CRON job pour surveillance continue.
 * @param {ObjectId[]} reservationIds - Identifiants des réservations à vérifier
 * @returns {Promise<Object>} { checked, alertsSent }
 */
async function checkWeatherAndNotify(reservationIds) {
  // Cette fonction peut être appelée par un CRON job
  // pour vérifier la météo et notifier les clients concernés
  try {
    // Récupérer la météo actuelle
    const weatherResponse = await axios.get(
      `https://api.openweathermap.org/data/2.5/weather`,
      {
        params: {
          q: 'Trois-Rivières,CA',
          appid: process.env.OPENWEATHER_API_KEY,
          units: 'metric',
          lang: 'fr',
        },
      }
    );

    const weather = weatherResponse.data;
    const isSnowing = weather.weather?.some(w =>
      w.main.toLowerCase().includes('snow') ||
      w.description.toLowerCase().includes('neige')
    );
    const isBlizzard = weather.wind?.speed > 50; // km/h

    if (isBlizzard || (isSnowing && weather.snow?.['1h'] > 5)) {
      // Conditions difficiles - notifier les réservations concernées
      for (const resId of reservationIds) {
        await notifyWeatherAlert(
          resId,
          isBlizzard ? 'Blizzard' : 'Forte neige',
          isBlizzard ? 30 : 15
        );
      }
    }

    return { checked: true, alertsSent: isBlizzard || isSnowing };
  } catch (error) {
    console.error('Erreur vérification météo:', error.message);
    return { checked: false, error: error.message };
  }
}

module.exports = {
  NOTIFICATION_TYPES,
  calculateETA,
  sendSmartNotification,
  notifyClientETA,
  notifyWorkerAssigned,
  notifyWorkerEnRoute,
  notifyWorkerArrived,
  notifyJobStarted,
  notifyJobCompleted,
  notifyWeatherAlert,
  notifyDelayRisk,
  sendReminder,
  checkWeatherAndNotify,
  getVehicleTypeLabel,
};
