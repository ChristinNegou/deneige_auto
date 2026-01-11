/**
 * Utilitaire de gestion des erreurs sécurisé
 * Empêche l'exposition de détails sensibles aux clients
 */

// Messages d'erreur génériques par catégorie
const ERROR_MESSAGES = {
    validation: 'Données invalides',
    authentication: 'Erreur d\'authentification',
    authorization: 'Accès non autorisé',
    notFound: 'Ressource non trouvée',
    payment: 'Erreur lors du traitement du paiement',
    database: 'Erreur de base de données',
    external: 'Erreur de service externe',
    server: 'Une erreur est survenue',
};

/**
 * Retourne un message d'erreur sécurisé pour le client
 * Ne jamais exposer error.message en production
 *
 * @param {Error} error - L'erreur capturée
 * @param {string} fallbackMessage - Message par défaut à retourner
 * @param {string} category - Catégorie d'erreur (optional)
 * @returns {string} Message sécurisé
 */
function getClientErrorMessage(error, fallbackMessage = ERROR_MESSAGES.server, category = null) {
    // En développement, on peut voir les vrais messages pour debugger
    if (process.env.NODE_ENV === 'development') {
        return error?.message || fallbackMessage;
    }

    // En production, retourner uniquement des messages génériques
    if (category && ERROR_MESSAGES[category]) {
        return ERROR_MESSAGES[category];
    }

    return fallbackMessage;
}

/**
 * Log l'erreur côté serveur avec tous les détails
 *
 * @param {string} context - Contexte de l'erreur (nom de la route, etc.)
 * @param {Error} error - L'erreur à logger
 * @param {Object} additionalInfo - Infos supplémentaires (userId, etc.)
 */
function logError(context, error, additionalInfo = {}) {
    const errorLog = {
        timestamp: new Date().toISOString(),
        context,
        message: error?.message,
        stack: error?.stack,
        ...additionalInfo,
    };

    console.error(`❌ [${context}]`, JSON.stringify(errorLog, null, 2));
}

/**
 * Gère une erreur et retourne une réponse standardisée
 *
 * @param {Response} res - Express response object
 * @param {Error} error - L'erreur capturée
 * @param {string} context - Contexte pour le logging
 * @param {string} clientMessage - Message à afficher au client
 * @param {number} statusCode - Code HTTP (default 500)
 */
function handleError(res, error, context, clientMessage = ERROR_MESSAGES.server, statusCode = 500) {
    logError(context, error);

    return res.status(statusCode).json({
        success: false,
        message: getClientErrorMessage(error, clientMessage),
    });
}

/**
 * Wrapper pour exécuter une fonction avec gestion d'erreur silencieuse
 * Utile pour les opérations non-critiques comme les notifications
 *
 * @param {Function} fn - Fonction async à exécuter
 * @param {string} context - Contexte pour le logging en cas d'erreur
 * @returns {Promise<any>} Résultat ou null si erreur
 */
async function safeExecute(fn, context) {
    try {
        return await fn();
    } catch (error) {
        logError(context, error);
        return null;
    }
}

/**
 * Wrapper pour les notifications - ne doit jamais faire échouer la requête principale
 *
 * @param {Function} notificationFn - Fonction de notification async
 * @param {string} notificationType - Type de notification pour le log
 */
async function safeNotify(notificationFn, notificationType) {
    try {
        await notificationFn();
    } catch (error) {
        // Log l'erreur mais ne propage pas - les notifications ne doivent pas bloquer
        logError(`Notification:${notificationType}`, error);
    }
}

module.exports = {
    ERROR_MESSAGES,
    getClientErrorMessage,
    logError,
    handleError,
    safeExecute,
    safeNotify,
};
