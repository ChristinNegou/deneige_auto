/**
 * Enums centralisés pour l'application Deneige Auto.
 * Définit les statuts, rôles, types et valeurs autorisées pour la validation Mongoose.
 * Utiliser ces constantes au lieu de chaînes codées en dur.
 * @module config/enums
 */

const RESERVATION_STATUS = {
    PENDING: 'pending',
    ASSIGNED: 'assigned',
    EN_ROUTE: 'enRoute',
    IN_PROGRESS: 'inProgress',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled',
};

const PAYMENT_STATUS = {
    PENDING: 'pending',
    PAID: 'paid',
    FAILED: 'failed',
    REFUNDED: 'refunded',
    PARTIALLY_REFUNDED: 'partially_refunded',
};

const PAYMENT_METHOD = {
    CARD: 'card',
    CASH: 'cash',
    SUBSCRIPTION: 'subscription',
};

const PAYOUT_STATUS = {
    PENDING: 'pending',
    PENDING_ACCOUNT: 'pending_account',
    PENDING_PAYMENT: 'pending_payment',
    PROCESSING: 'processing',
    COMPLETED: 'completed',
    PAID: 'paid',
    FAILED: 'failed',
};

const USER_ROLE = {
    CLIENT: 'client',
    SNOW_WORKER: 'snowWorker',
    ADMIN: 'admin',
};

const DISPUTE_TYPE = {
    NO_SHOW: 'no_show',
    QUALITY_ISSUE: 'quality_issue',
    DAMAGE: 'damage',
    OVERCHARGE: 'overcharge',
    LATE_ARRIVAL: 'late_arrival',
    OTHER: 'other',
};

const DISPUTE_STATUS = {
    OPEN: 'open',
    UNDER_REVIEW: 'under_review',
    RESOLVED: 'resolved',
    CLOSED: 'closed',
    ESCALATED: 'escalated',
};

const NOTIFICATION_TYPE = {
    RESERVATION_ASSIGNED: 'reservationAssigned',
    WORKER_EN_ROUTE: 'workerEnRoute',
    WORK_STARTED: 'workStarted',
    WORK_COMPLETED: 'workCompleted',
    PAYMENT_RECEIVED: 'paymentReceived',
    REFUND_PROCESSED: 'refundProcessed',
    DISPUTE_OPENED: 'disputeOpened',
    DISPUTE_RESOLVED: 'disputeResolved',
    NEW_MESSAGE: 'newMessage',
    TIP_RECEIVED: 'tipReceived',
};

const PHOTO_TYPE = {
    BEFORE: 'before',
    AFTER: 'after',
};

const SERVICE_OPTION = {
    WINDOW_SCRAPING: 'windowScraping',
    DOOR_DEICING: 'doorDeicing',
    WHEEL_CLEARANCE: 'wheelClearance',
};

const EQUIPMENT_TYPE = {
    SHOVEL: 'shovel',
    BRUSH: 'brush',
    ICE_SCRAPER: 'ice_scraper',
    SALT_SPREADER: 'salt_spreader',
    SNOW_BLOWER: 'snow_blower',
};

const CANCELLED_BY = {
    CLIENT: 'client',
    WORKER: 'worker',
    SYSTEM: 'system',
};

// Arrays pour validation dans les schémas Mongoose
const RESERVATION_STATUS_VALUES = Object.values(RESERVATION_STATUS);
const PAYMENT_STATUS_VALUES = Object.values(PAYMENT_STATUS);
const PAYMENT_METHOD_VALUES = Object.values(PAYMENT_METHOD);
const PAYOUT_STATUS_VALUES = Object.values(PAYOUT_STATUS);
const USER_ROLE_VALUES = Object.values(USER_ROLE);
const DISPUTE_TYPE_VALUES = Object.values(DISPUTE_TYPE);
const DISPUTE_STATUS_VALUES = Object.values(DISPUTE_STATUS);
const PHOTO_TYPE_VALUES = Object.values(PHOTO_TYPE);
const SERVICE_OPTION_VALUES = Object.values(SERVICE_OPTION);
const EQUIPMENT_TYPE_VALUES = Object.values(EQUIPMENT_TYPE);
const CANCELLED_BY_VALUES = Object.values(CANCELLED_BY);

module.exports = {
    // Enums
    RESERVATION_STATUS,
    PAYMENT_STATUS,
    PAYMENT_METHOD,
    PAYOUT_STATUS,
    USER_ROLE,
    DISPUTE_TYPE,
    DISPUTE_STATUS,
    NOTIFICATION_TYPE,
    PHOTO_TYPE,
    SERVICE_OPTION,
    EQUIPMENT_TYPE,
    CANCELLED_BY,

    // Arrays for Mongoose enum validation
    RESERVATION_STATUS_VALUES,
    PAYMENT_STATUS_VALUES,
    PAYMENT_METHOD_VALUES,
    PAYOUT_STATUS_VALUES,
    USER_ROLE_VALUES,
    DISPUTE_TYPE_VALUES,
    DISPUTE_STATUS_VALUES,
    PHOTO_TYPE_VALUES,
    SERVICE_OPTION_VALUES,
    EQUIPMENT_TYPE_VALUES,
    CANCELLED_BY_VALUES,
};
