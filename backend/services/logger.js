/**
 * Service de logging structuré pour la production
 * Format JSON pour intégration avec services de monitoring
 */

const LOG_LEVELS = {
    ERROR: 0,
    WARN: 1,
    INFO: 2,
    DEBUG: 3,
};

const currentLevel = process.env.LOG_LEVEL
    ? LOG_LEVELS[process.env.LOG_LEVEL.toUpperCase()] || LOG_LEVELS.INFO
    : LOG_LEVELS.INFO;

/**
 * Formatte un log en JSON structuré
 */
const formatLog = (level, message, metadata = {}) => {
    const log = {
        timestamp: new Date().toISOString(),
        level,
        message,
        service: 'deneige-auto-api',
        environment: process.env.NODE_ENV || 'development',
        ...metadata,
    };

    // Ajouter le stack trace pour les erreurs
    if (metadata.error instanceof Error) {
        log.error = {
            name: metadata.error.name,
            message: metadata.error.message,
            stack: metadata.error.stack,
        };
        delete log.error; // Retirer l'objet Error brut
    }

    return log;
};

/**
 * Écrit un log dans la console
 */
const writeLog = (level, message, metadata) => {
    const log = formatLog(level, message, metadata);

    if (process.env.NODE_ENV === 'production') {
        // En production, format JSON pour parsing facile
        console.log(JSON.stringify(log));
    } else {
        // En développement, format lisible
        const emoji = {
            ERROR: '❌',
            WARN: '⚠️',
            INFO: '📝',
            DEBUG: '🔍',
        };

        const color = {
            ERROR: '\x1b[31m', // Red
            WARN: '\x1b[33m',  // Yellow
            INFO: '\x1b[36m',  // Cyan
            DEBUG: '\x1b[90m', // Gray
        };
        const reset = '\x1b[0m';

        console.log(
            `${color[level]}${emoji[level]} [${level}]${reset} ${log.timestamp} - ${message}`,
            Object.keys(metadata).length > 0 ? metadata : ''
        );
    }
};

const logger = {
    error: (message, metadata = {}) => {
        if (LOG_LEVELS.ERROR <= currentLevel) {
            writeLog('ERROR', message, metadata);
        }
    },

    warn: (message, metadata = {}) => {
        if (LOG_LEVELS.WARN <= currentLevel) {
            writeLog('WARN', message, metadata);
        }
    },

    info: (message, metadata = {}) => {
        if (LOG_LEVELS.INFO <= currentLevel) {
            writeLog('INFO', message, metadata);
        }
    },

    debug: (message, metadata = {}) => {
        if (LOG_LEVELS.DEBUG <= currentLevel) {
            writeLog('DEBUG', message, metadata);
        }
    },

    /**
     * Log une requête HTTP
     */
    request: (req, res, duration) => {
        const log = {
            method: req.method,
            path: req.path,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            ip: req.ip,
            userAgent: req.get('user-agent'),
            userId: req.user?.id,
        };

        if (res.statusCode >= 400) {
            logger.warn('HTTP Request Failed', log);
        } else {
            logger.info('HTTP Request', log);
        }
    },

    /**
     * Log une opération de paiement
     */
    payment: (action, data) => {
        logger.info(`Payment: ${action}`, {
            category: 'payment',
            action,
            ...data,
        });
    },

    /**
     * Log une opération de réservation
     */
    reservation: (action, data) => {
        logger.info(`Reservation: ${action}`, {
            category: 'reservation',
            action,
            ...data,
        });
    },

    /**
     * Log une opération d'authentification
     */
    auth: (action, data) => {
        logger.info(`Auth: ${action}`, {
            category: 'auth',
            action,
            ...data,
        });
    },

    /**
     * Log une alerte de sécurité
     */
    security: (action, data) => {
        logger.warn(`Security Alert: ${action}`, {
            category: 'security',
            action,
            ...data,
        });
    },
};

/**
 * Middleware Express pour logger les requêtes
 */
const requestLogger = (req, res, next) => {
    const startTime = Date.now();

    // Capturer la fin de la réponse
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        logger.request(req, res, duration);
    });

    next();
};

module.exports = { logger, requestLogger };
