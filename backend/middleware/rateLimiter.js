/**
 * Rate Limiting Middleware
 * Protection contre les attaques par force brute et DDoS
 */

const rateLimit = require('express-rate-limit');

// Message d'erreur en français
const rateLimitMessage = {
    success: false,
    message: 'Trop de requêtes. Veuillez réessayer plus tard.',
    retryAfter: null, // Sera rempli par le handler
};

/**
 * Rate limiter général pour toutes les API
 * 100 requêtes par minute par IP
 */
const generalLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 100,
    message: rateLimitMessage,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next, options) => {
        res.status(429).json({
            ...options.message,
            retryAfter: Math.ceil(options.windowMs / 1000),
        });
    },
});

/**
 * Rate limiter strict pour l'authentification
 * 5 tentatives par 15 minutes par IP
 */
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5,
    message: {
        success: false,
        message: 'Trop de tentatives de connexion. Veuillez réessayer dans 15 minutes.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: true, // Ne compte pas les requêtes réussies
    handler: (req, res, next, options) => {
        console.warn(`⚠️ Rate limit auth atteint pour IP: ${req.ip}`);
        res.status(429).json({
            success: false,
            message: 'Trop de tentatives de connexion. Veuillez réessayer dans 15 minutes.',
            retryAfter: 900, // 15 minutes
        });
    },
});

/**
 * Rate limiter pour la création de compte
 * 3 comptes par heure par IP
 */
const registrationLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 heure
    max: 3,
    message: {
        success: false,
        message: 'Trop de créations de compte. Veuillez réessayer dans une heure.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next, options) => {
        console.warn(`⚠️ Rate limit registration atteint pour IP: ${req.ip}`);
        res.status(429).json({
            success: false,
            message: 'Trop de créations de compte. Veuillez réessayer dans une heure.',
            retryAfter: 3600,
        });
    },
});

/**
 * Rate limiter pour les SMS/codes de vérification
 * 3 codes par 15 minutes par IP
 */
const smsLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 3,
    message: {
        success: false,
        message: 'Trop de demandes de code. Veuillez réessayer dans 15 minutes.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next, options) => {
        console.warn(`⚠️ Rate limit SMS atteint pour IP: ${req.ip}`);
        res.status(429).json({
            success: false,
            message: 'Trop de demandes de code. Veuillez réessayer dans 15 minutes.',
            retryAfter: 900,
        });
    },
});

/**
 * Rate limiter pour les paiements
 * 10 opérations par minute par IP
 */
const paymentLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 10,
    message: {
        success: false,
        message: 'Trop d\'opérations de paiement. Veuillez réessayer dans une minute.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next, options) => {
        console.warn(`⚠️ Rate limit payment atteint pour IP: ${req.ip}`);
        res.status(429).json({
            success: false,
            message: 'Trop d\'opérations de paiement. Veuillez réessayer dans une minute.',
            retryAfter: 60,
        });
    },
});

/**
 * Rate limiter pour le mot de passe oublié
 * 3 demandes par heure par IP
 */
const forgotPasswordLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 heure
    max: 3,
    message: {
        success: false,
        message: 'Trop de demandes de réinitialisation. Veuillez réessayer dans une heure.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res, next, options) => {
        console.warn(`⚠️ Rate limit forgot-password atteint pour IP: ${req.ip}`);
        res.status(429).json({
            success: false,
            message: 'Trop de demandes de réinitialisation. Veuillez réessayer dans une heure.',
            retryAfter: 3600,
        });
    },
});

/**
 * Rate limiter pour les réservations
 * 20 réservations par heure par utilisateur
 */
const reservationLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 heure
    max: 20,
    message: {
        success: false,
        message: 'Trop de réservations. Veuillez réessayer plus tard.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        // Utiliser l'ID utilisateur si authentifié, sinon l'IP
        return req.user?.id || req.ip;
    },
});

/**
 * Rate limiter pour les uploads de fichiers
 * 10 uploads par minute par utilisateur
 */
const uploadLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 10,
    message: {
        success: false,
        message: 'Trop d\'uploads. Veuillez réessayer dans une minute.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        return req.user?.id || req.ip;
    },
});

module.exports = {
    generalLimiter,
    authLimiter,
    registrationLimiter,
    smsLimiter,
    paymentLimiter,
    forgotPasswordLimiter,
    reservationLimiter,
    uploadLimiter,
};
