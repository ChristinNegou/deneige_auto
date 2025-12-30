/**
 * Service de nettoyage automatique de la base de données
 * Supprime les données obsolètes pour optimiser les performances
 */

const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const Message = require('../models/Message');
const Reservation = require('../models/Reservation');

// Configuration des délais de rétention (en jours)
const RETENTION_CONFIG = {
    // Notifications
    readNotifications: 30,        // Notifications lues: 30 jours
    unreadNotifications: 90,      // Notifications non lues: 90 jours

    // Messages
    messagesAfterCompletion: 90,  // Messages après réservation terminée: 90 jours

    // Réservations (données associées uniquement, pas la réservation elle-même)
    completedReservationData: 180, // Données des réservations terminées: 6 mois
    cancelledReservationData: 90,  // Données des réservations annulées: 90 jours
};

/**
 * Calcule une date dans le passé
 * @param {number} days - Nombre de jours à soustraire
 * @returns {Date}
 */
const daysAgo = (days) => {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return date;
};

/**
 * Supprime les anciennes notifications lues
 */
const cleanOldReadNotifications = async () => {
    const cutoffDate = daysAgo(RETENTION_CONFIG.readNotifications);

    const result = await Notification.deleteMany({
        isRead: true,
        createdAt: { $lt: cutoffDate }
    });

    return {
        type: 'readNotifications',
        deleted: result.deletedCount,
        cutoffDate
    };
};

/**
 * Supprime les anciennes notifications non lues
 */
const cleanOldUnreadNotifications = async () => {
    const cutoffDate = daysAgo(RETENTION_CONFIG.unreadNotifications);

    const result = await Notification.deleteMany({
        isRead: false,
        createdAt: { $lt: cutoffDate }
    });

    return {
        type: 'unreadNotifications',
        deleted: result.deletedCount,
        cutoffDate
    };
};

/**
 * Supprime les messages des réservations terminées depuis longtemps
 */
const cleanOldMessages = async () => {
    const cutoffDate = daysAgo(RETENTION_CONFIG.messagesAfterCompletion);

    // Trouver les réservations terminées/annulées avant la date limite
    const oldReservations = await Reservation.find({
        status: { $in: ['completed', 'cancelled'] },
        updatedAt: { $lt: cutoffDate }
    }).select('_id');

    const reservationIds = oldReservations.map(r => r._id);

    if (reservationIds.length === 0) {
        return {
            type: 'messages',
            deleted: 0,
            reservationsProcessed: 0,
            cutoffDate
        };
    }

    const result = await Message.deleteMany({
        reservationId: { $in: reservationIds }
    });

    return {
        type: 'messages',
        deleted: result.deletedCount,
        reservationsProcessed: reservationIds.length,
        cutoffDate
    };
};

/**
 * Nettoie les photos des anciennes réservations terminées
 * (Met à null les URLs des photos pour libérer les références)
 */
const cleanOldReservationPhotos = async () => {
    const cutoffDate = daysAgo(RETENTION_CONFIG.completedReservationData);

    const result = await Reservation.updateMany(
        {
            status: 'completed',
            updatedAt: { $lt: cutoffDate },
            $or: [
                { beforePhotoUrl: { $ne: null } },
                { afterPhotoUrl: { $ne: null } }
            ]
        },
        {
            $set: {
                beforePhotoUrl: null,
                afterPhotoUrl: null
            }
        }
    );

    return {
        type: 'reservationPhotos',
        updated: result.modifiedCount,
        cutoffDate
    };
};

/**
 * Supprime les notifications orphelines (dont la réservation n'existe plus)
 */
const cleanOrphanedNotifications = async () => {
    // Récupérer toutes les notifications avec un reservationId
    const notificationsWithReservation = await Notification.find({
        reservationId: { $ne: null }
    }).select('_id reservationId');

    if (notificationsWithReservation.length === 0) {
        return {
            type: 'orphanedNotifications',
            deleted: 0
        };
    }

    // Récupérer les IDs de réservations existantes
    const reservationIds = [...new Set(notificationsWithReservation.map(n => n.reservationId.toString()))];
    const existingReservations = await Reservation.find({
        _id: { $in: reservationIds }
    }).select('_id');

    const existingIds = new Set(existingReservations.map(r => r._id.toString()));

    // Trouver les notifications orphelines
    const orphanedIds = notificationsWithReservation
        .filter(n => !existingIds.has(n.reservationId.toString()))
        .map(n => n._id);

    if (orphanedIds.length === 0) {
        return {
            type: 'orphanedNotifications',
            deleted: 0
        };
    }

    const result = await Notification.deleteMany({
        _id: { $in: orphanedIds }
    });

    return {
        type: 'orphanedNotifications',
        deleted: result.deletedCount
    };
};

/**
 * Supprime les messages orphelins (dont la réservation n'existe plus)
 */
const cleanOrphanedMessages = async () => {
    // Récupérer tous les reservationIds uniques des messages
    const messageReservationIds = await Message.distinct('reservationId');

    if (messageReservationIds.length === 0) {
        return {
            type: 'orphanedMessages',
            deleted: 0
        };
    }

    // Vérifier quelles réservations existent encore
    const existingReservations = await Reservation.find({
        _id: { $in: messageReservationIds }
    }).select('_id');

    const existingIds = new Set(existingReservations.map(r => r._id.toString()));

    // Trouver les reservationIds orphelins
    const orphanedReservationIds = messageReservationIds.filter(
        id => !existingIds.has(id.toString())
    );

    if (orphanedReservationIds.length === 0) {
        return {
            type: 'orphanedMessages',
            deleted: 0
        };
    }

    const result = await Message.deleteMany({
        reservationId: { $in: orphanedReservationIds }
    });

    return {
        type: 'orphanedMessages',
        deleted: result.deletedCount,
        orphanedReservations: orphanedReservationIds.length
    };
};

/**
 * Exécute toutes les tâches de nettoyage
 * @returns {Object} Rapport de nettoyage
 */
const runFullCleanup = async () => {
    const startTime = Date.now();
    const results = [];
    const errors = [];

    console.log('\n🧹 Démarrage du nettoyage de la base de données...');
    console.log(`📅 Date: ${new Date().toISOString()}`);
    console.log('─'.repeat(50));

    const tasks = [
        { name: 'Notifications lues anciennes', fn: cleanOldReadNotifications },
        { name: 'Notifications non lues anciennes', fn: cleanOldUnreadNotifications },
        { name: 'Messages anciens', fn: cleanOldMessages },
        { name: 'Photos anciennes', fn: cleanOldReservationPhotos },
        { name: 'Notifications orphelines', fn: cleanOrphanedNotifications },
        { name: 'Messages orphelins', fn: cleanOrphanedMessages },
    ];

    for (const task of tasks) {
        try {
            const result = await task.fn();
            results.push(result);

            const deletedOrUpdated = result.deleted ?? result.updated ?? 0;
            const icon = deletedOrUpdated > 0 ? '✅' : '⏭️';
            console.log(`${icon} ${task.name}: ${deletedOrUpdated} élément(s) traité(s)`);
        } catch (error) {
            errors.push({ task: task.name, error: error.message });
            console.error(`❌ ${task.name}: Erreur - ${error.message}`);
        }
    }

    const duration = Date.now() - startTime;
    const totalDeleted = results.reduce((sum, r) => sum + (r.deleted ?? 0), 0);
    const totalUpdated = results.reduce((sum, r) => sum + (r.updated ?? 0), 0);

    console.log('─'.repeat(50));
    console.log(`📊 Résumé: ${totalDeleted} supprimé(s), ${totalUpdated} mis à jour`);
    console.log(`⏱️ Durée: ${duration}ms`);
    console.log('🧹 Nettoyage terminé\n');

    return {
        success: errors.length === 0,
        startTime: new Date(startTime).toISOString(),
        duration,
        totalDeleted,
        totalUpdated,
        results,
        errors
    };
};

/**
 * Obtient les statistiques de la base de données
 * @returns {Object} Statistiques
 */
const getDatabaseStats = async () => {
    const [
        notificationCount,
        readNotificationCount,
        messageCount,
        reservationCount,
        completedReservationCount,
        cancelledReservationCount
    ] = await Promise.all([
        Notification.countDocuments(),
        Notification.countDocuments({ isRead: true }),
        Message.countDocuments(),
        Reservation.countDocuments(),
        Reservation.countDocuments({ status: 'completed' }),
        Reservation.countDocuments({ status: 'cancelled' })
    ]);

    // Estimation des données à nettoyer
    const oldReadNotifications = await Notification.countDocuments({
        isRead: true,
        createdAt: { $lt: daysAgo(RETENTION_CONFIG.readNotifications) }
    });

    const oldUnreadNotifications = await Notification.countDocuments({
        isRead: false,
        createdAt: { $lt: daysAgo(RETENTION_CONFIG.unreadNotifications) }
    });

    return {
        counts: {
            notifications: notificationCount,
            readNotifications: readNotificationCount,
            messages: messageCount,
            reservations: reservationCount,
            completedReservations: completedReservationCount,
            cancelledReservations: cancelledReservationCount
        },
        toClean: {
            oldReadNotifications,
            oldUnreadNotifications
        },
        retentionConfig: RETENTION_CONFIG
    };
};

module.exports = {
    runFullCleanup,
    getDatabaseStats,
    cleanOldReadNotifications,
    cleanOldUnreadNotifications,
    cleanOldMessages,
    cleanOldReservationPhotos,
    cleanOrphanedNotifications,
    cleanOrphanedMessages,
    RETENTION_CONFIG
};
