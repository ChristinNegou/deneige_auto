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
} = require('../controllers/notificationController');

// @route   GET /api/notifications
// @desc    Get all notifications for current user
// @access  Private
router.get('/', protect, getNotifications);

// @route   GET /api/notifications/unread-count
// @desc    Get unread notifications count
// @access  Private
router.get('/unread-count', protect, getUnreadCount);

// @route   GET /api/notifications/worker
// @desc    Get worker-specific notifications
// @access  Private (Workers only)
router.get('/worker', protect, getWorkerNotifications);

// @route   PATCH /api/notifications/mark-all-read
// @desc    Mark all notifications as read
// @access  Private
router.patch('/mark-all-read', protect, markAllAsRead);

// @route   DELETE /api/notifications/clear-all
// @desc    Clear all notifications
// @access  Private
router.delete('/clear-all', protect, clearAllNotifications);

// @route   POST /api/notifications/send-to-client
// @desc    Send notification to client (for workers)
// @access  Private (Workers only)
router.post('/send-to-client', protect, sendNotificationToClient);

// @route   POST /api/notifications/worker/:workerId
// @desc    Create notification for a specific worker (admin)
// @access  Private (Admin only)
router.post('/worker/:workerId', protect, createWorkerNotification);

// @route   POST /api/notifications/broadcast-zone
// @desc    Broadcast notification to all workers in a zone
// @access  Private (Admin only)
router.post('/broadcast-zone', protect, broadcastZoneNotification);

// @route   PATCH /api/notifications/:id/read
// @desc    Mark notification as read
// @access  Private
router.patch('/:id/read', protect, markAsRead);

// @route   DELETE /api/notifications/:id
// @desc    Delete notification
// @access  Private
router.delete('/:id', protect, deleteNotification);

module.exports = router;
