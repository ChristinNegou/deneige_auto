const Notification = require('../models/Notification');

// @desc    Get all notifications for current user
// @route   GET /api/notifications
// @access  Private
exports.getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({ userId: req.user.id })
            .sort({ createdAt: -1 })
            .limit(50)
            .populate('workerId', 'firstName lastName')
            .populate('reservationId', 'parkingSpotNumber departureTime status');

        res.json({
            success: true,
            notifications,
        });
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Get unread notifications count
// @route   GET /api/notifications/unread-count
// @access  Private
exports.getUnreadCount = async (req, res) => {
    try {
        const count = await Notification.countDocuments({
            userId: req.user.id,
            isRead: false,
        });

        res.json({
            success: true,
            count,
        });
    } catch (error) {
        console.error('Error fetching unread count:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Mark notification as read
// @route   PATCH /api/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res) => {
    try {
        const notification = await Notification.findOne({
            _id: req.params.id,
            userId: req.user.id,
        });

        if (!notification) {
            return res.status(404).json({
                success: false,
                message: 'Notification non trouvée',
            });
        }

        notification.isRead = true;
        await notification.save();

        res.json({
            success: true,
            message: 'Notification marquée comme lue',
        });
    } catch (error) {
        console.error('Error marking notification as read:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Mark all notifications as read
// @route   PATCH /api/notifications/mark-all-read
// @access  Private
exports.markAllAsRead = async (req, res) => {
    try {
        await Notification.updateMany(
            { userId: req.user.id, isRead: false },
            { isRead: true }
        );

        res.json({
            success: true,
            message: 'Toutes les notifications marquées comme lues',
        });
    } catch (error) {
        console.error('Error marking all as read:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private
exports.deleteNotification = async (req, res) => {
    try {
        const notification = await Notification.findOneAndDelete({
            _id: req.params.id,
            userId: req.user.id,
        });

        if (!notification) {
            return res.status(404).json({
                success: false,
                message: 'Notification non trouvée',
            });
        }

        res.json({
            success: true,
            message: 'Notification supprimée',
        });
    } catch (error) {
        console.error('Error deleting notification:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Clear all notifications
// @route   DELETE /api/notifications/clear-all
// @access  Private
exports.clearAllNotifications = async (req, res) => {
    try {
        await Notification.deleteMany({ userId: req.user.id });

        res.json({
            success: true,
            message: 'Toutes les notifications supprimées',
        });
    } catch (error) {
        console.error('Error clearing notifications:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Send notification to client (for workers)
// @route   POST /api/notifications/send-to-client
// @access  Private (Workers only)
exports.sendNotificationToClient = async (req, res) => {
    try {
        const { reservationId, type, title, message, metadata } = req.body;

        // Vérifier que l'utilisateur est un worker
        if (req.user.role !== 'worker' && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Seuls les déneigeurs peuvent envoyer des notifications aux clients',
            });
        }

        // Récupérer la réservation pour obtenir le client
        const Reservation = require('../models/Reservation');
        const reservation = await Reservation.findById(reservationId);

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Vérifier que le worker est assigné à cette réservation
        if (reservation.assignedWorker?.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Vous n\'êtes pas assigné à cette réservation',
            });
        }

        // Déterminer la priorité selon le type
        let priority = 'normal';
        if (['workerEnRoute', 'workStarted', 'workCompleted'].includes(type)) {
            priority = 'high';
        }

        // Créer la notification pour le client
        const notification = await Notification.createNotification({
            userId: reservation.userId,
            type: type,
            title: title,
            message: message,
            priority: priority,
            reservationId: reservationId,
            workerId: req.user.id,
            metadata: {
                ...metadata,
                workerName: `${req.user.firstName} ${req.user.lastName}`,
                sentAt: new Date(),
            },
        });

        res.status(201).json({
            success: true,
            message: 'Notification envoyée au client',
            notification: notification,
        });
    } catch (error) {
        console.error('Error sending notification to client:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Get notifications for worker (job-related)
// @route   GET /api/notifications/worker
// @access  Private (Workers only)
exports.getWorkerNotifications = async (req, res) => {
    try {
        if (req.user.role !== 'worker' && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Accès réservé aux déneigeurs',
            });
        }

        const notifications = await Notification.find({
            userId: req.user.id,
            type: {
                $in: [
                    'urgentRequest',
                    'reservationAssigned',
                    'reservationCancelled',
                    'paymentSuccess',
                    'weatherAlert',
                    'systemNotification',
                ]
            }
        })
            .sort({ createdAt: -1 })
            .limit(50);

        res.json({
            success: true,
            notifications,
        });
    } catch (error) {
        console.error('Error fetching worker notifications:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Create worker-specific notification (admin/system)
// @route   POST /api/notifications/worker/:workerId
// @access  Private (Admin only)
exports.createWorkerNotification = async (req, res) => {
    try {
        const { workerId } = req.params;
        const { type, title, message, priority, metadata } = req.body;

        // Vérifier que c'est un admin ou le système
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Accès réservé aux administrateurs',
            });
        }

        const notification = await Notification.createNotification({
            userId: workerId,
            type: type || 'systemNotification',
            title: title,
            message: message,
            priority: priority || 'normal',
            metadata: metadata,
        });

        res.status(201).json({
            success: true,
            notification,
        });
    } catch (error) {
        console.error('Error creating worker notification:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Notify all workers in a zone about high demand
// @route   POST /api/notifications/broadcast-zone
// @access  Private (Admin only)
exports.broadcastZoneNotification = async (req, res) => {
    try {
        const { zone, title, message, priority } = req.body;

        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Accès réservé aux administrateurs',
            });
        }

        // Trouver tous les workers actifs dans la zone
        const User = require('../models/User');
        const workers = await User.find({
            role: 'worker',
            isActive: true,
            // Optionnel: filtrer par zone géographique
        });

        const notifications = [];
        for (const worker of workers) {
            const notification = await Notification.createNotification({
                userId: worker._id,
                type: 'weatherAlert',
                title: title,
                message: message,
                priority: priority || 'high',
                metadata: { zone, broadcastType: 'zone' },
            });
            notifications.push(notification);
        }

        res.status(201).json({
            success: true,
            message: `${notifications.length} notifications envoyées`,
            count: notifications.length,
        });
    } catch (error) {
        console.error('Error broadcasting zone notification:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};
