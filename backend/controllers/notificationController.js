const Notification = require('../models/Notification');
const User = require('../models/User');
const { handleError } = require('../utils/errorHandler');

// @desc    Register FCM token for push notifications
// @route   POST /api/notifications/register-token
// @access  Private
exports.registerFcmToken = async (req, res) => {
    try {
        const { fcmToken } = req.body;

        if (!fcmToken) {
            return res.status(400).json({
                success: false,
                message: 'Le token FCM est requis',
            });
        }

        // Mettre à jour le token FCM de l'utilisateur
        await User.findByIdAndUpdate(req.user.id, { fcmToken });

        res.json({
            success: true,
            message: 'Token FCM enregistré avec succès',
        });
    } catch (error) {
        return handleError(res, error, 'notifications:register-token', 'Erreur lors de l\'enregistrement du token');
    }
};

// @desc    Unregister FCM token (logout)
// @route   DELETE /api/notifications/unregister-token
// @access  Private
exports.unregisterFcmToken = async (req, res) => {
    try {
        await User.findByIdAndUpdate(req.user.id, { fcmToken: null });

        res.json({
            success: true,
            message: 'Token FCM supprimé avec succès',
        });
    } catch (error) {
        return handleError(res, error, 'notifications:unregister-token', 'Erreur lors de la suppression du token');
    }
};

// @desc    Update notification settings
// @route   PATCH /api/notifications/settings
// @access  Private
exports.updateNotificationSettings = async (req, res) => {
    try {
        const { pushEnabled, emailEnabled, smsEnabled } = req.body;

        const updateData = {};
        if (typeof pushEnabled === 'boolean') {
            updateData['notificationSettings.pushEnabled'] = pushEnabled;
        }
        if (typeof emailEnabled === 'boolean') {
            updateData['notificationSettings.emailEnabled'] = emailEnabled;
        }
        if (typeof smsEnabled === 'boolean') {
            updateData['notificationSettings.smsEnabled'] = smsEnabled;
        }

        const user = await User.findByIdAndUpdate(
            req.user.id,
            updateData,
            { new: true }
        ).select('notificationSettings');

        res.json({
            success: true,
            message: 'Paramètres de notification mis à jour',
            settings: user.notificationSettings,
        });
    } catch (error) {
        return handleError(res, error, 'notifications:update-settings', 'Erreur lors de la mise à jour des paramètres');
    }
};

// @desc    Get all notifications for current user
// @route   GET /api/notifications
// @access  Private
exports.getNotifications = async (req, res) => {
    try {
        const { page = 1, limit = 20, unreadOnly = 'false' } = req.query;
        const pageNum = Math.max(1, parseInt(page));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit)));
        const skip = (pageNum - 1) * limitNum;

        const query = { userId: req.user.id };
        if (unreadOnly === 'true') {
            query.isRead = false;
        }

        const [notifications, total] = await Promise.all([
            Notification.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limitNum)
                .populate('workerId', 'firstName lastName')
                .populate('reservationId', 'parkingSpotNumber departureTime status'),
            Notification.countDocuments(query),
        ]);

        res.json({
            success: true,
            count: notifications.length,
            total,
            page: pageNum,
            pages: Math.ceil(total / limitNum),
            notifications,
        });
    } catch (error) {
        return handleError(res, error, 'notifications:get-all', 'Erreur lors de la récupération des notifications');
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
        return handleError(res, error, 'notifications:unread-count', 'Erreur lors du comptage des notifications');
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
        return handleError(res, error, 'notifications:mark-read', 'Erreur lors du marquage de la notification');
    }
};

// @desc    Mark all notifications as read
// @route   PATCH /api/notifications/mark-all-read
// @access  Private
exports.markAllAsRead = async (req, res) => {
    try {
        const result = await Notification.updateMany(
            { userId: req.user.id, isRead: false },
            { isRead: true }
        );

        res.json({
            success: true,
            message: 'Toutes les notifications marquées comme lues',
            modifiedCount: result.modifiedCount,
            matchedCount: result.matchedCount,
        });
    } catch (error) {
        return handleError(res, error, 'notifications:mark-all-read', 'Erreur lors du marquage des notifications');
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
        return handleError(res, error, 'notifications:delete', 'Erreur lors de la suppression de la notification');
    }
};

// @desc    Clear all notifications
// @route   DELETE /api/notifications/clear-all
// @access  Private
exports.clearAllNotifications = async (req, res) => {
    try {
        const result = await Notification.deleteMany({ userId: req.user.id });

        res.json({
            success: true,
            message: 'Toutes les notifications supprimées',
            deletedCount: result.deletedCount,
        });
    } catch (error) {
        return handleError(res, error, 'notifications:clear-all', 'Erreur lors de la suppression des notifications');
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
        return handleError(res, error, 'notifications:send-to-client', 'Erreur lors de l\'envoi de la notification');
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
        return handleError(res, error, 'notifications:worker-list', 'Erreur lors de la récupération des notifications');
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
        return handleError(res, error, 'notifications:create-worker', 'Erreur lors de la création de la notification');
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
        return handleError(res, error, 'notifications:broadcast-zone', 'Erreur lors de la diffusion des notifications');
    }
};
