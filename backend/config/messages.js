/**
 * Messages d'erreur et de succès centralisés
 * Facilite la maintenance et la traduction future
 */

module.exports = {
    // ============== ERREURS D'AUTHENTIFICATION ==============
    AUTH: {
        INVALID_CREDENTIALS: 'Email ou mot de passe incorrect',
        INVALID_TOKEN: 'Session invalide ou expirée. Veuillez vous reconnecter',
        TOKEN_EXPIRED: 'Votre session a expiré. Veuillez vous reconnecter',
        NO_TOKEN: 'Connexion requise',
        UNAUTHORIZED: 'Vous n\'êtes pas autorisé à effectuer cette action',
        FORBIDDEN: 'Accès refusé',
        ACCOUNT_DISABLED: 'Votre compte a été désactivé',
        EMAIL_NOT_VERIFIED: 'Veuillez vérifier votre adresse email',
        PHONE_NOT_VERIFIED: 'Veuillez vérifier votre numéro de téléphone',
        INVALID_REFRESH_TOKEN: 'Session expirée. Veuillez vous reconnecter',
        PASSWORD_TOO_WEAK: 'Le mot de passe doit contenir au moins 8 caractères',
        EMAIL_ALREADY_EXISTS: 'Cette adresse email est déjà utilisée',
        PHONE_ALREADY_EXISTS: 'Ce numéro de téléphone est déjà utilisé',
    },

    // ============== ERREURS DE VALIDATION ==============
    VALIDATION: {
        REQUIRED_FIELD: (field) => `Le champ ${field} est requis`,
        INVALID_EMAIL: 'Adresse email invalide',
        INVALID_PHONE: 'Numéro de téléphone invalide',
        INVALID_DATE: 'Date invalide',
        INVALID_AMOUNT: 'Montant invalide',
        MIN_LENGTH: (field, min) => `${field} doit contenir au moins ${min} caractères`,
        MAX_LENGTH: (field, max) => `${field} ne peut pas dépasser ${max} caractères`,
        INVALID_ID: 'Identifiant invalide',
        INVALID_STATUS: 'Statut invalide',
    },

    // ============== ERREURS DE RÉSERVATION ==============
    RESERVATION: {
        NOT_FOUND: 'Réservation non trouvée',
        ALREADY_ASSIGNED: 'Cette réservation a déjà été acceptée par un autre déneigeur',
        CANNOT_CANCEL: 'Cette réservation ne peut plus être annulée',
        ALREADY_COMPLETED: 'Cette réservation est déjà terminée',
        ALREADY_CANCELLED: 'Cette réservation a déjà été annulée',
        INVALID_STATUS_TRANSITION: 'Changement de statut non autorisé',
        NOT_ASSIGNED_TO_YOU: 'Cette réservation ne vous est pas assignée',
        DEPARTURE_TIME_PASSED: 'L\'heure de départ est déjà passée',
        NO_VEHICLE: 'Aucun véhicule sélectionné',
        NO_LOCATION: 'Aucun emplacement spécifié',
    },

    // ============== ERREURS DE PAIEMENT ==============
    PAYMENT: {
        FAILED: 'Le paiement a échoué. Veuillez réessayer',
        CARD_DECLINED: 'Carte refusée. Veuillez utiliser une autre carte',
        INSUFFICIENT_FUNDS: 'Fonds insuffisants',
        INVALID_CARD: 'Informations de carte invalides',
        EXPIRED_CARD: 'Carte expirée',
        PROCESSING_ERROR: 'Erreur lors du traitement du paiement',
        REFUND_FAILED: 'Le remboursement a échoué',
        PAYOUT_FAILED: 'Le versement a échoué',
        NO_PAYMENT_METHOD: 'Aucun moyen de paiement enregistré',
        STRIPE_ACCOUNT_NOT_READY: 'Votre compte de paiement n\'est pas encore configuré',
    },

    // ============== ERREURS WORKER ==============
    WORKER: {
        NOT_AVAILABLE: 'Déneigeur non disponible',
        NO_EQUIPMENT: 'Équipement manquant pour ce travail',
        ALREADY_HAS_JOB: 'Vous avez déjà un travail en cours',
        ACCOUNT_SUSPENDED: 'Votre compte est temporairement suspendu',
        STRIPE_ACCOUNT_REQUIRED: 'Vous devez configurer votre compte bancaire pour recevoir des paiements',
        IDENTITY_VERIFICATION_REQUIRED: 'Vérification d\'identité requise',
    },

    // ============== ERREURS VÉHICULE ==============
    VEHICLE: {
        NOT_FOUND: 'Véhicule non trouvé',
        ALREADY_EXISTS: 'Ce véhicule existe déjà',
        MAX_VEHICLES_REACHED: 'Nombre maximum de véhicules atteint',
        INVALID_LICENSE_PLATE: 'Plaque d\'immatriculation invalide',
    },

    // ============== ERREURS SERVEUR ==============
    SERVER: {
        INTERNAL_ERROR: 'Une erreur interne est survenue. Veuillez réessayer',
        SERVICE_UNAVAILABLE: 'Service temporairement indisponible',
        DATABASE_ERROR: 'Erreur de base de données',
        RATE_LIMITED: 'Trop de requêtes. Veuillez patienter',
        MAINTENANCE: 'Service en maintenance',
    },

    // ============== MESSAGES DE SUCCÈS ==============
    SUCCESS: {
        CREATED: (item) => `${item} créé avec succès`,
        UPDATED: (item) => `${item} mis à jour avec succès`,
        DELETED: (item) => `${item} supprimé avec succès`,
        RESERVATION_CREATED: 'Réservation créée avec succès',
        RESERVATION_ACCEPTED: 'Réservation acceptée',
        RESERVATION_COMPLETED: 'Travail terminé avec succès',
        PAYMENT_SUCCESS: 'Paiement effectué avec succès',
        REFUND_SUCCESS: 'Remboursement effectué avec succès',
        LOGIN_SUCCESS: 'Connexion réussie',
        LOGOUT_SUCCESS: 'Déconnexion réussie',
        PASSWORD_RESET: 'Mot de passe réinitialisé avec succès',
        EMAIL_SENT: 'Email envoyé avec succès',
        SMS_SENT: 'SMS envoyé avec succès',
    },

    // ============== NOTIFICATIONS ==============
    NOTIFICATIONS: {
        WORKER_ASSIGNED: (workerName) => `${workerName} a accepté votre demande de déneigement`,
        WORKER_EN_ROUTE: (workerName) => `${workerName} est en route vers votre véhicule`,
        WORK_STARTED: (workerName) => `${workerName} a commencé le déneigement de votre véhicule`,
        WORK_COMPLETED: (workerName) => `${workerName} a terminé le déneigement. Votre véhicule est prêt!`,
        RESERVATION_CANCELLED: 'Votre réservation a été annulée',
        TIP_RECEIVED: (amount) => `Vous avez reçu un pourboire de ${amount}$`,
        NEW_JOB_AVAILABLE: 'Nouvelle demande de déneigement disponible près de vous',
    },
};
