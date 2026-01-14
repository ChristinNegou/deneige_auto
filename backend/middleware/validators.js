/**
 * Validation Middleware
 * Validation des entrées utilisateur avec express-validator
 */

const { body, param, query, validationResult } = require('express-validator');

/**
 * Middleware pour gérer les erreurs de validation
 */
const handleValidationErrors = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Données invalides',
            errors: errors.array().map(err => ({
                field: err.path,
                message: err.msg,
            })),
        });
    }
    next();
};

// ============================================
// VALIDATIONS AUTHENTIFICATION
// ============================================

const validateRegister = [
    body('email')
        .trim()
        .isEmail()
        .withMessage('Email invalide')
        .normalizeEmail(),
    body('password')
        .isLength({ min: 6 })
        .withMessage('Le mot de passe doit contenir au moins 6 caractères')
        .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre'),
    body('firstName')
        .trim()
        .notEmpty()
        .withMessage('Le prénom est requis')
        .isLength({ min: 2, max: 50 })
        .withMessage('Le prénom doit contenir entre 2 et 50 caractères')
        .matches(/^[a-zA-ZÀ-ÿ\s-]+$/)
        .withMessage('Le prénom contient des caractères invalides'),
    body('lastName')
        .trim()
        .notEmpty()
        .withMessage('Le nom est requis')
        .isLength({ min: 2, max: 50 })
        .withMessage('Le nom doit contenir entre 2 et 50 caractères')
        .matches(/^[a-zA-ZÀ-ÿ\s-]+$/)
        .withMessage('Le nom contient des caractères invalides'),
    body('phoneNumber')
        .trim()
        .notEmpty()
        .withMessage('Le numéro de téléphone est requis')
        .matches(/^\+?1?\s*\(?[0-9]{3}\)?[\s.-]?[0-9]{3}[\s.-]?[0-9]{4}$/)
        .withMessage('Format de numéro de téléphone invalide'),
    body('role')
        .optional()
        .isIn(['client', 'snowWorker'])
        .withMessage('Rôle invalide'),
    handleValidationErrors,
];

const validateLogin = [
    body('email')
        .trim()
        .isEmail()
        .withMessage('Email invalide')
        .normalizeEmail(),
    body('password')
        .notEmpty()
        .withMessage('Le mot de passe est requis'),
    handleValidationErrors,
];

const validateForgotPassword = [
    body('email')
        .trim()
        .isEmail()
        .withMessage('Email invalide')
        .normalizeEmail(),
    handleValidationErrors,
];

const validateResetPassword = [
    param('resetToken')
        .notEmpty()
        .withMessage('Token de réinitialisation requis')
        .isHexadecimal()
        .withMessage('Token invalide'),
    body('password')
        .isLength({ min: 6 })
        .withMessage('Le mot de passe doit contenir au moins 6 caractères'),
    handleValidationErrors,
];

const validateUpdateProfile = [
    body('firstName')
        .optional()
        .trim()
        .isLength({ min: 2, max: 50 })
        .withMessage('Le prénom doit contenir entre 2 et 50 caractères')
        .matches(/^[a-zA-ZÀ-ÿ\s-]+$/)
        .withMessage('Le prénom contient des caractères invalides'),
    body('lastName')
        .optional()
        .trim()
        .isLength({ min: 2, max: 50 })
        .withMessage('Le nom doit contenir entre 2 et 50 caractères')
        .matches(/^[a-zA-ZÀ-ÿ\s-]+$/)
        .withMessage('Le nom contient des caractères invalides'),
    body('phoneNumber')
        .optional()
        .trim()
        .matches(/^\+?1?\s*\(?[0-9]{3}\)?[\s.-]?[0-9]{3}[\s.-]?[0-9]{4}$/)
        .withMessage('Format de numéro de téléphone invalide'),
    body('photoUrl')
        .optional()
        .isURL()
        .withMessage('URL de photo invalide'),
    handleValidationErrors,
];

// ============================================
// VALIDATIONS TÉLÉPHONE
// ============================================

const validateSendCode = [
    body('phoneNumber')
        .trim()
        .notEmpty()
        .withMessage('Le numéro de téléphone est requis')
        .matches(/^\+?1?\s*\(?[0-9]{3}\)?[\s.-]?[0-9]{3}[\s.-]?[0-9]{4}$/)
        .withMessage('Format de numéro de téléphone invalide'),
    body('email')
        .optional()
        .trim()
        .isEmail()
        .withMessage('Email invalide')
        .normalizeEmail(),
    body('password')
        .optional()
        .isLength({ min: 6 })
        .withMessage('Le mot de passe doit contenir au moins 6 caractères'),
    body('firstName')
        .optional()
        .trim()
        .isLength({ min: 2, max: 50 })
        .withMessage('Le prénom doit contenir entre 2 et 50 caractères'),
    body('lastName')
        .optional()
        .trim()
        .isLength({ min: 2, max: 50 })
        .withMessage('Le nom doit contenir entre 2 et 50 caractères'),
    handleValidationErrors,
];

const validateVerifyCode = [
    body('phoneNumber')
        .trim()
        .notEmpty()
        .withMessage('Le numéro de téléphone est requis'),
    body('code')
        .trim()
        .notEmpty()
        .withMessage('Le code est requis')
        .isLength({ min: 6, max: 6 })
        .withMessage('Le code doit contenir 6 chiffres')
        .isNumeric()
        .withMessage('Le code doit contenir uniquement des chiffres'),
    handleValidationErrors,
];

// ============================================
// VALIDATIONS RÉSERVATIONS
// ============================================

const validateCreateReservation = [
    body('vehicleId')
        .notEmpty()
        .withMessage('Le véhicule est requis')
        .isMongoId()
        .withMessage('ID de véhicule invalide'),
    body('parkingSpotId')
        .optional()
        .isMongoId()
        .withMessage('ID de place de parking invalide'),
    body('departureTime')
        .notEmpty()
        .withMessage('L\'heure de départ est requise')
        .isISO8601()
        .withMessage('Format de date invalide'),
    body('notes')
        .optional()
        .trim()
        .isLength({ max: 500 })
        .withMessage('Les notes ne peuvent pas dépasser 500 caractères'),
    body('latitude')
        .optional()
        .isFloat({ min: -90, max: 90 })
        .withMessage('Latitude invalide'),
    body('longitude')
        .optional()
        .isFloat({ min: -180, max: 180 })
        .withMessage('Longitude invalide'),
    handleValidationErrors,
];

const validateReservationId = [
    param('id')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    handleValidationErrors,
];

// ============================================
// VALIDATIONS VÉHICULES
// ============================================

const validateCreateVehicle = [
    body('brand')
        .trim()
        .notEmpty()
        .withMessage('La marque est requise')
        .isLength({ max: 50 })
        .withMessage('La marque ne peut pas dépasser 50 caractères'),
    body('model')
        .trim()
        .notEmpty()
        .withMessage('Le modèle est requis')
        .isLength({ max: 50 })
        .withMessage('Le modèle ne peut pas dépasser 50 caractères'),
    body('color')
        .trim()
        .notEmpty()
        .withMessage('La couleur est requise')
        .isLength({ max: 30 })
        .withMessage('La couleur ne peut pas dépasser 30 caractères'),
    body('licensePlate')
        .trim()
        .notEmpty()
        .withMessage('La plaque d\'immatriculation est requise')
        .isLength({ max: 10 })
        .withMessage('La plaque ne peut pas dépasser 10 caractères')
        .matches(/^[A-Z0-9\s-]+$/i)
        .withMessage('Format de plaque invalide'),
    body('size')
        .optional()
        .isIn(['small', 'medium', 'large', 'suv', 'truck'])
        .withMessage('Taille de véhicule invalide'),
    handleValidationErrors,
];

const validateVehicleId = [
    param('id')
        .isMongoId()
        .withMessage('ID de véhicule invalide'),
    handleValidationErrors,
];

// ============================================
// VALIDATIONS PAIEMENTS
// ============================================

const validatePaymentMethodId = [
    body('paymentMethodId')
        .notEmpty()
        .withMessage('L\'ID de la méthode de paiement est requis')
        .matches(/^pm_/)
        .withMessage('Format d\'ID de méthode de paiement invalide'),
    handleValidationErrors,
];

const validateCreatePaymentIntent = [
    body('amount')
        .notEmpty()
        .withMessage('Le montant est requis')
        .isFloat({ min: 0.50, max: 10000 })
        .withMessage('Le montant doit être entre 0.50$ et 10,000$')
        .custom((value) => {
            if (isNaN(value) || !Number.isFinite(parseFloat(value))) {
                throw new Error('Le montant doit être un nombre valide');
            }
            return true;
        }),
    body('reservationId')
        .optional()
        .custom((value) => {
            // Allow 'temp' or valid MongoDB ObjectId
            if (value === 'temp' || /^[0-9a-fA-F]{24}$/.test(value)) {
                return true;
            }
            throw new Error('ID de réservation invalide');
        }),
    handleValidationErrors,
];

const validateConfirmPayment = [
    body('paymentIntentId')
        .notEmpty()
        .withMessage('L\'ID du Payment Intent est requis')
        .matches(/^pi_/)
        .withMessage('Format de Payment Intent invalide'),
    body('reservationId')
        .notEmpty()
        .withMessage('L\'ID de la réservation est requis')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    handleValidationErrors,
];

const validateTip = [
    body('reservationId')
        .notEmpty()
        .withMessage('L\'ID de la réservation est requis')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    body('amount')
        .notEmpty()
        .withMessage('Le montant est requis')
        .isFloat({ min: 1, max: 1000 })
        .withMessage('Le montant doit être entre 1$ et 1000$'),
    handleValidationErrors,
];

const validateRefund = [
    body('reservationId')
        .notEmpty()
        .withMessage('L\'ID de la réservation est requis')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    body('amount')
        .optional()
        .isFloat({ min: 0.01 })
        .withMessage('Le montant de remboursement doit être positif'),
    body('reason')
        .optional()
        .isIn(['requested_by_customer', 'duplicate', 'fraudulent'])
        .withMessage('Raison de remboursement invalide'),
    handleValidationErrors,
];

// ============================================
// VALIDATIONS MESSAGES/CHAT
// ============================================

const validateSendMessage = [
    body('reservationId')
        .notEmpty()
        .withMessage('L\'ID de la réservation est requis')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    body('content')
        .trim()
        .notEmpty()
        .withMessage('Le message ne peut pas être vide')
        .isLength({ max: 1000 })
        .withMessage('Le message ne peut pas dépasser 1000 caractères'),
    handleValidationErrors,
];

// ============================================
// VALIDATIONS DISPUTES
// ============================================

const validateCreateDispute = [
    body('reservationId')
        .notEmpty()
        .withMessage('L\'ID de la réservation est requis')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    body('type')
        .trim()
        .notEmpty()
        .withMessage('Le type est requis')
        .isIn(['no_show', 'incomplete_work', 'quality_issue', 'late_arrival', 'damage', 'wrong_location', 'overcharge', 'unprofessional', 'payment_issue', 'other'])
        .withMessage('Type de litige invalide'),
    body('description')
        .trim()
        .notEmpty()
        .withMessage('La description est requise')
        .isLength({ min: 10, max: 2000 })
        .withMessage('La description doit contenir entre 10 et 2000 caractères'),
    body('claimedAmount')
        .optional()
        .isFloat({ min: 0, max: 10000 })
        .withMessage('Le montant réclamé doit être entre 0$ et 10,000$'),
    body('photos')
        .optional()
        .isArray({ max: 10 })
        .withMessage('Maximum 10 photos autorisées'),
    body('gpsLocation.latitude')
        .optional()
        .isFloat({ min: -90, max: 90 })
        .withMessage('Latitude invalide'),
    body('gpsLocation.longitude')
        .optional()
        .isFloat({ min: -180, max: 180 })
        .withMessage('Longitude invalide'),
    handleValidationErrors,
];

const validateReportNoShow = [
    param('reservationId')
        .isMongoId()
        .withMessage('ID de réservation invalide'),
    body('description')
        .optional()
        .trim()
        .isLength({ max: 2000 })
        .withMessage('La description ne peut pas dépasser 2000 caractères'),
    body('photos')
        .optional()
        .isArray({ max: 10 })
        .withMessage('Maximum 10 photos autorisées'),
    handleValidationErrors,
];

const validateDisputeResponse = [
    param('id')
        .isMongoId()
        .withMessage('ID de litige invalide'),
    body('text')
        .trim()
        .notEmpty()
        .withMessage('La réponse est requise')
        .isLength({ min: 20, max: 5000 })
        .withMessage('La réponse doit contenir entre 20 et 5000 caractères'),
    body('photos')
        .optional()
        .isArray({ max: 10 })
        .withMessage('Maximum 10 photos autorisées'),
    handleValidationErrors,
];

const validateDisputeAppeal = [
    param('id')
        .isMongoId()
        .withMessage('ID de litige invalide'),
    body('reason')
        .trim()
        .notEmpty()
        .withMessage('La raison de l\'appel est requise')
        .isLength({ min: 50, max: 5000 })
        .withMessage('La raison doit contenir entre 50 et 5000 caractères'),
    handleValidationErrors,
];

const validateResolveDispute = [
    param('id')
        .isMongoId()
        .withMessage('ID de litige invalide'),
    body('decision')
        .trim()
        .notEmpty()
        .withMessage('La décision est requise')
        .isIn(['favor_claimant', 'favor_respondent', 'partial_refund', 'full_refund', 'no_action', 'appeal_overturned'])
        .withMessage('Décision invalide'),
    body('refundAmount')
        .optional()
        .isFloat({ min: 0, max: 10000 })
        .withMessage('Le montant de remboursement doit être entre 0$ et 10,000$'),
    body('workerPenalty')
        .optional()
        .isIn(['none', 'warning', 'suspension_3days', 'suspension_7days', 'suspension_30days', 'permanent_ban'])
        .withMessage('Pénalité worker invalide'),
    body('clientPenalty')
        .optional()
        .isIn(['none', 'warning', 'suspension_3days', 'suspension_7days', 'suspension_30days', 'permanent_ban'])
        .withMessage('Pénalité client invalide'),
    body('notes')
        .optional()
        .trim()
        .isLength({ max: 2000 })
        .withMessage('Les notes ne peuvent pas dépasser 2000 caractères'),
    handleValidationErrors,
];

const validateDisputePagination = [
    query('page')
        .optional()
        .isInt({ min: 1 })
        .withMessage('Numéro de page invalide')
        .toInt(),
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 })
        .withMessage('Limite invalide (1-100)')
        .toInt(),
    query('status')
        .optional()
        .isIn(['open', 'under_review', 'pending_response', 'resolved', 'closed', 'appealed', 'escalated'])
        .withMessage('Statut invalide'),
    query('type')
        .optional()
        .isIn(['no_show', 'incomplete_work', 'quality_issue', 'late_arrival', 'damage', 'wrong_location', 'overcharge', 'unprofessional', 'payment_issue', 'other'])
        .withMessage('Type invalide'),
    query('priority')
        .optional()
        .isIn(['low', 'medium', 'high', 'urgent'])
        .withMessage('Priorité invalide'),
    handleValidationErrors,
];

// ============================================
// VALIDATIONS ADMIN
// ============================================

const validateUserId = [
    param('userId')
        .isMongoId()
        .withMessage('ID utilisateur invalide'),
    handleValidationErrors,
];

const validatePagination = [
    query('page')
        .optional()
        .isInt({ min: 1 })
        .withMessage('Numéro de page invalide'),
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 })
        .withMessage('Limite invalide (1-100)'),
    handleValidationErrors,
];

// ============================================
// VALIDATIONS WORKERS
// ============================================

const validateWorkerLocation = [
    body('latitude')
        .notEmpty()
        .withMessage('La latitude est requise')
        .isFloat({ min: -90, max: 90 })
        .withMessage('Latitude invalide'),
    body('longitude')
        .notEmpty()
        .withMessage('La longitude est requise')
        .isFloat({ min: -180, max: 180 })
        .withMessage('Longitude invalide'),
    handleValidationErrors,
];

const validateWorkerZone = [
    body('name')
        .trim()
        .notEmpty()
        .withMessage('Le nom de la zone est requis')
        .isLength({ max: 100 })
        .withMessage('Le nom ne peut pas dépasser 100 caractères'),
    body('centerLat')
        .notEmpty()
        .withMessage('La latitude du centre est requise')
        .isFloat({ min: -90, max: 90 })
        .withMessage('Latitude invalide'),
    body('centerLng')
        .notEmpty()
        .withMessage('La longitude du centre est requise')
        .isFloat({ min: -180, max: 180 })
        .withMessage('Longitude invalide'),
    body('radiusKm')
        .optional()
        .isFloat({ min: 1, max: 50 })
        .withMessage('Le rayon doit être entre 1 et 50 km'),
    handleValidationErrors,
];

// ============================================
// VALIDATION GÉNÉRIQUE MONGO ID
// ============================================

const validateMongoId = (paramName = 'id') => [
    param(paramName)
        .isMongoId()
        .withMessage('ID invalide'),
    handleValidationErrors,
];

module.exports = {
    handleValidationErrors,
    // Auth
    validateRegister,
    validateLogin,
    validateForgotPassword,
    validateResetPassword,
    validateUpdateProfile,
    // Phone
    validateSendCode,
    validateVerifyCode,
    // Reservations
    validateCreateReservation,
    validateReservationId,
    // Vehicles
    validateCreateVehicle,
    validateVehicleId,
    // Payments
    validatePaymentMethodId,
    validateCreatePaymentIntent,
    validateConfirmPayment,
    validateTip,
    validateRefund,
    // Messages
    validateSendMessage,
    // Disputes
    validateCreateDispute,
    validateReportNoShow,
    validateDisputeResponse,
    validateDisputeAppeal,
    validateResolveDispute,
    validateDisputePagination,
    // Admin
    validateUserId,
    validatePagination,
    // Workers
    validateWorkerLocation,
    validateWorkerZone,
    // Generic
    validateMongoId,
};
