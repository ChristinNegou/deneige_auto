const mongoose = require('mongoose');
const { sendPushNotification } = require('../services/firebaseService');

const notificationSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: [true, 'L\'utilisateur est requis'],
        index: true,
    },
    type: {
        type: String,
        enum: [
            'reservationAssigned',
            'workerEnRoute',
            'workStarted',
            'workCompleted',
            'reservationCancelled',
            'paymentSuccess',
            'paymentFailed',
            'refundProcessed',
            'weatherAlert',
            'urgentRequest',
            'workerMessage',
            'systemNotification',
            'newMessage',      // Pour les messages de chat
            'tipReceived',     // Pourboire reçu par le déneigeur
            'rating',          // Évaluation reçue par le déneigeur
        ],
        required: [true, 'Le type est requis'],
    },
    title: {
        type: String,
        required: [true, 'Le titre est requis'],
        trim: true,
        maxlength: [100, 'Le titre ne peut pas dépasser 100 caractères'],
    },
    message: {
        type: String,
        required: [true, 'Le message est requis'],
        trim: true,
        maxlength: [500, 'Le message ne peut pas dépasser 500 caractères'],
    },
    priority: {
        type: String,
        enum: ['low', 'normal', 'high', 'urgent'],
        default: 'normal',
    },
    isRead: {
        type: Boolean,
        default: false,
        index: true,
    },
    reservationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reservation',
        default: null,
    },
    workerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null,
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed,
        default: {},
    },
}, {
    timestamps: true,
});

// Index composé pour optimiser les requêtes
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });
notificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 }); // Pour liste filtrée
notificationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 90 * 24 * 60 * 60 }); // TTL 90 jours
notificationSchema.index({ type: 1, createdAt: -1 }); // Pour stats par type

// Méthode pour créer une notification
notificationSchema.statics.createNotification = async function(data) {
    const notification = new this(data);
    await notification.save();

    // Envoyer une push notification si l'utilisateur a un token FCM
    try {
        const User = mongoose.model('User');
        const user = await User.findById(data.userId).select('fcmToken notificationSettings email');

        // Logging détaillé pour le debugging
        const pushContext = {
            userId: data.userId?.toString(),
            notificationType: data.type,
            hasFcmToken: !!user?.fcmToken,
            pushEnabled: user?.notificationSettings?.pushEnabled !== false,
        };

        if (!user) {
            console.warn('[FCM] Utilisateur non trouvé pour notification push:', pushContext);
        } else if (!user.fcmToken) {
            // Log silencieux - l'utilisateur n'a simplement pas de token (normal si pas d'app installée)
            if (process.env.NODE_ENV !== 'production') {
                console.debug('[FCM] Utilisateur sans token FCM:', { ...pushContext, email: user.email });
            }
        } else if (user.notificationSettings?.pushEnabled === false) {
            console.debug('[FCM] Notifications push désactivées pour:', { ...pushContext, email: user.email });
        } else {
            const pushData = {
                notificationId: notification._id.toString(),
                type: data.type,
                ...(data.reservationId && { reservationId: data.reservationId.toString() }),
                ...(data.workerId && { workerId: data.workerId.toString() }),
            };

            const result = await sendPushNotification(
                user.fcmToken,
                data.title,
                data.message,
                pushData
            );

            // Si le token est invalide, le supprimer
            if (result && result.invalidToken) {
                await User.findByIdAndUpdate(data.userId, { fcmToken: null });
                console.warn('[FCM] Token invalide supprimé pour utilisateur:', {
                    userId: data.userId?.toString(),
                    email: user.email,
                    errorCode: result.errorCode,
                });
            } else if (result && result.success) {
                console.debug('[FCM] Push envoyée avec succès:', pushContext);
            }
        }
    } catch (error) {
        console.error('[FCM] Erreur envoi notification push:', {
            userId: data.userId?.toString(),
            type: data.type,
            error: error.message,
            stack: process.env.NODE_ENV !== 'production' ? error.stack : undefined,
        });
        // Ne pas faire échouer la création de notification si la push échoue
    }

    return notification;
};

// Méthode helper pour créer des notifications spécifiques
notificationSchema.statics.notifyReservationAssigned = async function(reservation, worker) {
    return await this.createNotification({
        userId: reservation.userId,
        type: 'reservationAssigned',
        title: 'Déneigeur assigné',
        message: `${worker.firstName} ${worker.lastName} a accepté votre demande de déneigement`,
        priority: 'high',
        reservationId: reservation._id,
        workerId: worker._id,
        metadata: {
            workerName: `${worker.firstName} ${worker.lastName}`,
            departureTime: reservation.departureTime,
        },
    });
};

notificationSchema.statics.notifyWorkerEnRoute = async function(reservation, worker) {
    return await this.createNotification({
        userId: reservation.userId,
        type: 'workerEnRoute',
        title: 'Déneigeur en route',
        message: `${worker.firstName} est en route vers votre véhicule`,
        priority: 'high',
        reservationId: reservation._id,
        workerId: worker._id,
        metadata: {
            workerName: `${worker.firstName} ${worker.lastName}`,
            estimatedArrival: new Date(Date.now() + 15 * 60000), // +15 min
        },
    });
};

notificationSchema.statics.notifyWorkStarted = async function(reservation, worker) {
    return await this.createNotification({
        userId: reservation.userId,
        type: 'workStarted',
        title: 'Déneigement commencé',
        message: `${worker.firstName} a commencé le déneigement de votre véhicule`,
        priority: 'normal',
        reservationId: reservation._id,
        workerId: worker._id,
        metadata: {
            startTime: new Date(),
        },
    });
};

notificationSchema.statics.notifyWorkCompleted = async function(reservation, worker) {
    return await this.createNotification({
        userId: reservation.userId,
        type: 'workCompleted',
        title: 'Déneigement terminé',
        message: `${worker.firstName} a terminé le déneigement. Votre véhicule est prêt!`,
        priority: 'high',
        reservationId: reservation._id,
        workerId: worker._id,
        metadata: {
            completedAt: reservation.completedAt,
            totalPrice: reservation.totalPrice,
        },
    });
};

notificationSchema.statics.notifyPaymentSuccess = async function(reservation) {
    return await this.createNotification({
        userId: reservation.userId,
        type: 'paymentSuccess',
        title: 'Paiement réussi',
        message: `Votre paiement de ${reservation.totalPrice.toFixed(2)} $ a été effectué avec succès`,
        priority: 'normal',
        reservationId: reservation._id,
        metadata: {
            amount: reservation.totalPrice,
            paymentIntentId: reservation.paymentIntentId,
        },
    });
};

notificationSchema.statics.notifyPaymentFailed = async function(reservation, error) {
    return await this.createNotification({
        userId: reservation.userId,
        type: 'paymentFailed',
        title: 'Paiement échoué',
        message: `Le paiement de ${reservation.totalPrice.toFixed(2)} $ a échoué. Veuillez réessayer.`,
        priority: 'urgent',
        reservationId: reservation._id,
        metadata: {
            amount: reservation.totalPrice,
            error: error,
        },
    });
};

notificationSchema.statics.notifyReservationCancelled = async function(reservation, reason) {
    return await this.createNotification({
        userId: reservation.userId,
        type: 'reservationCancelled',
        title: 'Réservation annulée',
        message: reason || 'Votre réservation a été annulée',
        priority: 'high',
        reservationId: reservation._id,
        metadata: {
            cancelledAt: reservation.cancelledAt,
            reason: reason,
        },
    });
};

module.exports = mongoose.model('Notification', notificationSchema);
