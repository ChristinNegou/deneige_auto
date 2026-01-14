/**
 * Rate Limiting Middleware
 * Protection contre les attaques par force brute et DDoS
 */

const rateLimit = require('express-rate-limit');
const { RATE_LIMITS } = require('../config/constants');

// Helper pour générer une clé à partir de l'IP (compatible IPv6)
const getClientIp = (req) => {
    // Utiliser x-forwarded-for pour les proxies (Railway, etc.)
    const forwarded = req.headers['x-forwarded-for'];
    if (forwarded) {
        // Prendre la première IP (client original)
        return forwarded.split(',')[0].trim();
    }
    // Fallback sur req.ip
    return req.ip || 'unknown';
};

// En mode test, désactiver le rate limiting
const isTestEnv = process.env.NODE_ENV === 'test';

// Middleware qui ne fait rien (pour les tests)
const noopMiddleware = (req, res, next) => next();

// Message d'erreur en français
const rateLimitMessage = {
    success: false,
    message: 'Trop de requêtes. Veuillez réessayer plus tard.',
    retryAfter: null, // Sera rempli par le handler
};

/**
 * Rate limiter général pour toutes les API
 * Configurable via RATE_LIMITS.GENERAL
 */
const generalLimiter = rateLimit({
    windowMs: RATE_LIMITS.GENERAL.WINDOW_MS,
    max: RATE_LIMITS.GENERAL.MAX_ATTEMPTS,
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
 * Configurable via RATE_LIMITS.AUTH
 */
const authLimiter = rateLimit({
    windowMs: RATE_LIMITS.AUTH.WINDOW_MS,
    max: RATE_LIMITS.AUTH.MAX_ATTEMPTS,
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
 * Configurable via RATE_LIMITS.SMS
 */
const smsLimiter = rateLimit({
    windowMs: RATE_LIMITS.SMS.WINDOW_MS,
    max: RATE_LIMITS.SMS.MAX_ATTEMPTS,
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
 * Configurable via RATE_LIMITS.PAYMENT
 */
const paymentLimiter = rateLimit({
    windowMs: RATE_LIMITS.PAYMENT.WINDOW_MS,
    max: RATE_LIMITS.PAYMENT.MAX_ATTEMPTS,
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
        return req.user?.id || getClientIp(req);
    },
    validate: { xForwardedForHeader: false },
});

/**
 * Rate limiter pour les uploads de fichiers
 * Configurable via RATE_LIMITS.UPLOAD
 */
const uploadLimiter = rateLimit({
    windowMs: RATE_LIMITS.UPLOAD.WINDOW_MS,
    max: RATE_LIMITS.UPLOAD.MAX_ATTEMPTS,
    message: {
        success: false,
        message: 'Trop d\'uploads. Veuillez réessayer dans une minute.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        return req.user?.id || getClientIp(req);
    },
    validate: { xForwardedForHeader: false },
});

/**
 * Rate limiter pour les mises à jour de localisation
 * 60 requêtes par minute par utilisateur (1 par seconde)
 */
const locationLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 60,
    message: {
        success: false,
        message: 'Trop de mises à jour de position. Veuillez réessayer.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        return req.user?.id || getClientIp(req);
    },
    validate: { xForwardedForHeader: false },
});

/**
 * Rate limiter pour les demandes de support
 * 5 requêtes par heure par utilisateur
 */
const supportLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 heure
    max: 5,
    message: {
        success: false,
        message: 'Trop de demandes de support. Veuillez réessayer plus tard.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        return req.user?.id || getClientIp(req);
    },
});

// Exporter les vrais limiters en production, ou noop en test
module.exports = isTestEnv ? {
    generalLimiter: noopMiddleware,
    authLimiter: noopMiddleware,
    registrationLimiter: noopMiddleware,
    smsLimiter: noopMiddleware,
    paymentLimiter: noopMiddleware,
    forgotPasswordLimiter: noopMiddleware,
    reservationLimiter: noopMiddleware,
    uploadLimiter: noopMiddleware,
    locationLimiter: noopMiddleware,
    supportLimiter: noopMiddleware,
} : {
    generalLimiter,
    authLimiter,
    registrationLimiter,
    smsLimiter,
    paymentLimiter,
    forgotPasswordLimiter,
    reservationLimiter,
    uploadLimiter,
    locationLimiter,
    supportLimiter,
};
