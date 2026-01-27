/**
 * Routes de gestion des notifications (lecture, marquage, suppression, push FCM, diffusion par zone).
 * @module routes/notifications
 */

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
    getNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    clearAllNotifications,
    sendNotificationToClient,
    getWorkerNotifications,
    createWorkerNotification,
    broadcastZoneNotification,
    registerFcmToken,
    unregisterFcmToken,
    updateNotificationSettings,
} = require('../controllers/notificationController');

// --- Tokens FCM (push notifications) ---

/**
 * POST /api/notifications/register-token
 * Enregistre un token FCM pour les notifications push.
 */
router.post('/register-token', protect, registerFcmToken);

/**
 * DELETE /api/notifications/unregister-token
 * Désenregistre un token FCM (à la déconnexion).
 */
router.delete('/unregister-token', protect, unregisterFcmToken);

/**
 * PATCH /api/notifications/settings
 * Met à jour les paramètres de notification de l'utilisateur.
 */
router.patch('/settings', protect, updateNotificationSettings);

// --- Lecture et gestion ---

/**
 * GET /api/notifications
 * Retourne toutes les notifications de l'utilisateur.
 */
router.get('/', protect, getNotifications);

/**
 * GET /api/notifications/unread-count
 * Retourne le nombre de notifications non lues.
 */
router.get('/unread-count', protect, getUnreadCount);

/**
 * GET /api/notifications/worker
 * Retourne les notifications spécifiques aux déneigeurs.
 */
router.get('/worker', protect, getWorkerNotifications);

/**
 * PATCH /api/notifications/mark-all-read
 * Marque toutes les notifications comme lues.
 */
router.patch('/mark-all-read', protect, markAllAsRead);

/**
 * DELETE /api/notifications/clear-all
 * Supprime toutes les notifications de l'utilisateur.
 */
router.delete('/clear-all', protect, clearAllNotifications);

// --- Envoi de notifications ---

/**
 * POST /api/notifications/send-to-client
 * Envoie une notification à un client (utilisé par les déneigeurs).
 */
router.post('/send-to-client', protect, sendNotificationToClient);

/**
 * POST /api/notifications/worker/:workerId
 * Crée une notification pour un déneigeur spécifique (admin).
 */
router.post('/worker/:workerId', protect, createWorkerNotification);

/**
 * POST /api/notifications/broadcast-zone
 * Diffuse une notification à tous les déneigeurs d'une zone (admin).
 */
router.post('/broadcast-zone', protect, broadcastZoneNotification);

/**
 * PATCH /api/notifications/:id/read
 * Marque une notification comme lue.
 */
router.patch('/:id/read', protect, markAsRead);

/**
 * DELETE /api/notifications/:id
 * Supprime une notification.
 */
router.delete('/:id', protect, deleteNotification);

module.exports = router;
