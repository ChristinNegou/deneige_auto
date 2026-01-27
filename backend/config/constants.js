/**
 * Constantes de configuration métier de l'application Deneige Auto.
 * Centralise les frais de plateforme, politiques d'annulation, limites de débit,
 * tarification, géolocalisation et paramètres Stripe.
 * @module config/constants
 */

module.exports = {
    // ============== FRAIS DE PLATEFORME ==============
    PLATFORM_FEE_PERCENT: 0.25, // 25% commission plateforme
    WORKER_PERCENT: 0.75, // 75% pour le déneigeur

    // ============== POLITIQUE D'ANNULATION ==============
    CANCELLATION_POLICY: {
        // Fenêtre de temps pour annulation gratuite (en minutes avant départ)
        FREE_CANCELLATION_WINDOW_MINUTES: 60,
        // Frais si déneigeur en route
        EN_ROUTE_FEE_PERCENT: 50,
        // Frais si travail commencé
        IN_PROGRESS_FEE_PERCENT: 100,
        // Frais minimum en cents
        MIN_CANCELLATION_FEE_CENTS: 500,
        // Seuils pour déneigeurs
        WARNING_THRESHOLD: 2,        // Nombre d'annulations avant avertissement
        SUSPENSION_THRESHOLD: 5,     // Nombre d'annulations avant suspension
        SUSPENSION_DAYS: 7,          // Durée de suspension en jours
    },

    // ============== UPLOAD DE FICHIERS ==============
    FILE_UPLOAD: {
        MAX_FILE_SIZE: 10 * 1024 * 1024, // 10 MB
        MAX_PHOTO_SIZE: 5 * 1024 * 1024, // 5 MB pour les photos de profil
        ALLOWED_PHOTO_TYPES: ['image/jpeg', 'image/png', 'image/webp'],
        MAX_JOB_PHOTOS: 10,
    },

    // ============== VÉRIFICATION TÉLÉPHONE ==============
    PHONE_VERIFICATION: {
        CODE_EXPIRY_MINUTES: 15,
        RESEND_WAIT_SECONDS: 60,
        MAX_ATTEMPTS: 5,
    },

    // ============== GÉOLOCALISATION ==============
    GEOLOCATION: {
        DEFAULT_SEARCH_RADIUS_KM: 50,
        MAX_SEARCH_RADIUS_KM: 100,
        EARTH_RADIUS_METERS: 6371e3,
    },

    // ============== DÉLAIS ET TIMEOUTS ==============
    TIMING: {
        // Grace period after departure time for no-show (minutes)
        NO_SHOW_GRACE_MINUTES: 30,
        // Durée minimum attendue pour un travail (minutes)
        MIN_WORK_DURATION_MINUTES: 15,
        // Temps estimé avant arrivée (minutes)
        DEFAULT_ETA_MINUTES: 15,
        // Seuil d'urgence (heures avant départ)
        URGENCY_THRESHOLD_HOURS: 4,
    },

    // ============== TARIFICATION ==============
    PRICING: {
        // Multiplicateur pour les réservations prioritaires
        PRIORITY_MULTIPLIER: 1.4, // +40%
        // Prix minimum en CAD
        MIN_PRICE_CAD: 15,
        // Pourboire minimum
        MIN_TIP_CAD: 1,
    },

    // ============== RATE LIMITING ==============
    RATE_LIMITS: {
        AUTH: {
            WINDOW_MS: 15 * 60 * 1000, // 15 minutes
            MAX_ATTEMPTS: 5,
        },
        SMS: {
            WINDOW_MS: 15 * 60 * 1000, // 15 minutes
            MAX_ATTEMPTS: 3,
        },
        PAYMENT: {
            WINDOW_MS: 60 * 1000, // 1 minute
            MAX_ATTEMPTS: 10,
        },
        UPLOAD: {
            WINDOW_MS: 60 * 1000, // 1 minute
            MAX_ATTEMPTS: 20,
        },
        GENERAL: {
            WINDOW_MS: 60 * 1000, // 1 minute
            MAX_ATTEMPTS: 100,
        },
    },

    // ============== STRIPE ==============
    STRIPE: {
        // Frais Stripe estimés (2.9% + 0.30$)
        FEE_PERCENT: 0.029,
        FEE_FIXED_CENTS: 30,
        // Montant minimum pour paiement en cents
        MIN_PAYMENT_CENTS: 50,
    },

    // ============== NOTIFICATIONS ==============
    NOTIFICATIONS: {
        // TTL des notifications en jours
        TTL_DAYS: 90,
        // Limite par page
        DEFAULT_PAGE_SIZE: 20,
        MAX_PAGE_SIZE: 100,
    },

    // ============== PAGINATION ==============
    PAGINATION: {
        DEFAULT_PAGE_SIZE: 20,
        MAX_PAGE_SIZE: 100,
    },
};
