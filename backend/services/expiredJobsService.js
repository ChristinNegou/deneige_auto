/**
 * Service de gestion des jobs expires
 * Detecte et traite automatiquement les reservations non completees apres leur deadline
 */

const Reservation = require('../models/Reservation');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { sendPushNotification } = require('./firebaseService');

// Configuration des delais (en minutes)
const CONFIG = {
    // Delai apres deadline avant annulation automatique
    AUTO_CANCEL_DELAY_MINUTES: 30,
    // Delai pour envoyer un rappel au worker avant deadline
    REMINDER_BEFORE_DEADLINE_MINUTES: 15,
    // Penalite pour le worker (nombre de warnings avant suspension)
    MAX_WARNINGS_BEFORE_SUSPENSION: 3,
};

/**
 * Trouve tous les jobs expires (deadline depassee)
 */
async function findExpiredJobs() {
    const now = new Date();

    // Jobs actifs dont la deadline est passee
    const expiredJobs = await Reservation.find({
        status: { $in: ['pending', 'assigned', 'enRoute', 'inProgress'] },
        deadlineTime: { $lt: now },
    })
    .populate('userId', 'firstName lastName email fcmToken')
    .populate('workerId', 'firstName lastName email fcmToken workerProfile')
    .populate('vehicle', 'brand model licensePlate');

    return expiredJobs;
}

/**
 * Trouve les jobs qui approchent de leur deadline (pour rappels)
 */
async function findJobsApproachingDeadline() {
    const now = new Date();
    const reminderTime = new Date(now.getTime() + CONFIG.REMINDER_BEFORE_DEADLINE_MINUTES * 60 * 1000);

    // Jobs actifs dont la deadline est dans les X prochaines minutes
    const approachingJobs = await Reservation.find({
        status: { $in: ['assigned', 'enRoute'] }, // Pas encore commence
        deadlineTime: { $gt: now, $lte: reminderTime },
    })
    .populate('userId', 'firstName lastName')
    .populate('workerId', 'firstName lastName fcmToken')
    .populate('vehicle', 'brand model');

    return approachingJobs;
}

/**
 * Annule un job expire et gere les consequences
 */
async function cancelExpiredJob(reservation) {
    const now = new Date();
    const minutesOverdue = Math.floor((now - reservation.deadlineTime) / (1000 * 60));

    // Ne pas annuler si pas assez en retard
    if (minutesOverdue < CONFIG.AUTO_CANCEL_DELAY_MINUTES) {
        return { action: 'waiting', minutesOverdue };
    }

    console.log(`\n⏰ Annulation automatique du job ${reservation._id}`);
    console.log(`   Deadline: ${reservation.deadlineTime}`);
    console.log(`   Retard: ${minutesOverdue} minutes`);

    // Mettre a jour le statut de la reservation
    reservation.status = 'cancelled';
    reservation.cancelledAt = now;
    reservation.cancelledBy = 'system';
    reservation.cancelReason = `Annulation automatique - Job non complete ${minutesOverdue} minutes apres la deadline`;

    // Rembourser le client si paye
    if (reservation.paymentStatus === 'paid') {
        reservation.paymentStatus = 'refunded';
        reservation.refundAmount = reservation.totalPrice;
        reservation.refundedAt = now;
        // Note: Le remboursement Stripe reel devrait etre fait ici
        // await refundPayment(reservation.paymentIntentId, reservation.totalPrice);
    }

    await reservation.save();

    // Gerer les consequences pour le worker
    if (reservation.workerId) {
        await penalizeWorker(reservation.workerId, reservation);
    }

    // Notifier le client
    await notifyClientJobExpired(reservation);

    // Notifier le worker (s'il y en avait un)
    if (reservation.workerId) {
        await notifyWorkerJobExpired(reservation);
    }

    return { action: 'cancelled', minutesOverdue, reservationId: reservation._id };
}

/**
 * Penalise le worker pour job non complete
 */
async function penalizeWorker(workerId, reservation) {
    try {
        const worker = await User.findById(workerId);
        if (!worker || !worker.workerProfile) return;

        // Incrementer le compteur d'avertissements
        worker.workerProfile.warningCount = (worker.workerProfile.warningCount || 0) + 1;
        worker.workerProfile.totalCancellations = (worker.workerProfile.totalCancellations || 0) + 1;

        // Ajouter a l'historique des annulations
        if (!worker.workerProfile.cancellationHistory) {
            worker.workerProfile.cancellationHistory = [];
        }
        worker.workerProfile.cancellationHistory.push({
            reservationId: reservation._id,
            reason: 'expired',
            date: new Date(),
        });

        // Suspendre si trop d'avertissements
        if (worker.workerProfile.warningCount >= CONFIG.MAX_WARNINGS_BEFORE_SUSPENSION) {
            worker.workerProfile.isSuspended = true;
            worker.workerProfile.suspendedAt = new Date();
            worker.workerProfile.suspensionReason = `Suspension automatique - ${worker.workerProfile.warningCount} jobs non completes`;

            console.log(`   ⚠️ Worker ${worker.email} suspendu (${worker.workerProfile.warningCount} avertissements)`);

            // Notifier le worker de sa suspension
            await Notification.create({
                userId: worker._id,
                type: 'systemNotification',
                title: 'Compte suspendu',
                message: `Votre compte deneigeur a ete suspendu suite a ${worker.workerProfile.warningCount} jobs non completes. Contactez le support pour plus d'informations.`,
            });
        }

        await worker.save();
        console.log(`   ⚠️ Worker ${worker.email} penalise (warning ${worker.workerProfile.warningCount})`);

    } catch (error) {
        console.error('Erreur penalisation worker:', error);
    }
}

/**
 * Notifie le client que son job a ete annule
 */
async function notifyClientJobExpired(reservation) {
    try {
        const client = reservation.userId;
        const vehicle = reservation.vehicle;

        const notification = await Notification.create({
            userId: client._id,
            type: 'reservationUpdate',
            title: 'Reservation annulee',
            message: `Votre reservation pour ${vehicle?.brand || 'votre vehicule'} ${vehicle?.model || ''} a ete annulee car le deneigeur n'a pas pu completer le travail a temps. Vous serez rembourse integralement.`,
            metadata: {
                reservationId: reservation._id,
                reason: 'expired',
            },
        });

        // Envoyer push notification
        if (client.fcmToken) {
            await sendPushNotification(
                client.fcmToken,
                'Reservation annulee',
                `Votre reservation a ete annulee. Un remboursement sera effectue.`,
                { reservationId: reservation._id.toString(), type: 'reservation_expired' }
            );
        }

        console.log(`   📱 Client ${client.email} notifie`);

    } catch (error) {
        console.error('Erreur notification client:', error);
    }
}

/**
 * Notifie le worker que le job a ete annule
 */
async function notifyWorkerJobExpired(reservation) {
    try {
        const worker = reservation.workerId;
        if (!worker) return;

        const notification = await Notification.create({
            userId: worker._id,
            type: 'systemNotification',
            title: 'Job annule - Non complete',
            message: `Le job #${reservation._id.toString().slice(-6)} a ete annule car il n'a pas ete complete avant la deadline. Un avertissement a ete ajoute a votre compte.`,
            metadata: {
                reservationId: reservation._id,
                reason: 'expired',
            },
        });

        // Envoyer push notification
        if (worker.fcmToken) {
            await sendPushNotification(
                worker.fcmToken,
                'Job annule',
                `Un job a ete annule car non complete a temps. Verifiez votre compte.`,
                { reservationId: reservation._id.toString(), type: 'job_expired_warning' }
            );
        }

        console.log(`   📱 Worker ${worker.email} notifie`);

    } catch (error) {
        console.error('Erreur notification worker:', error);
    }
}

/**
 * Envoie des rappels aux workers pour les jobs qui approchent de leur deadline
 */
async function sendDeadlineReminders() {
    const approachingJobs = await findJobsApproachingDeadline();
    let remindersSent = 0;

    for (const job of approachingJobs) {
        if (!job.workerId) continue;

        const worker = job.workerId;
        const minutesLeft = Math.floor((job.deadlineTime - new Date()) / (1000 * 60));

        // Creer notification de rappel
        await Notification.create({
            userId: worker._id,
            type: 'reminder',
            title: 'Rappel - Deadline proche',
            message: `Il vous reste ${minutesLeft} minutes pour completer le job pour ${job.userId?.firstName || 'le client'}. Vehicule: ${job.vehicle?.brand || ''} ${job.vehicle?.model || ''}`,
            metadata: {
                reservationId: job._id,
                type: 'deadline_reminder',
            },
        });

        // Push notification
        if (worker.fcmToken) {
            await sendPushNotification(
                worker.fcmToken,
                `⏰ ${minutesLeft} min restantes`,
                `Completez le job rapidement pour eviter l'annulation automatique.`,
                { reservationId: job._id.toString(), type: 'deadline_reminder' }
            );
        }

        remindersSent++;
        console.log(`   ⏰ Rappel envoye a ${worker.email} (${minutesLeft} min restantes)`);
    }

    return remindersSent;
}

/**
 * Traite tous les jobs expires
 * Cette fonction est appelee par le cron job
 */
async function processExpiredJobs() {
    console.log('\n' + '='.repeat(50));
    console.log('🔍 Verification des jobs expires...');
    console.log('='.repeat(50));

    const results = {
        expired: [],
        waiting: [],
        reminders: 0,
        errors: [],
    };

    try {
        // Envoyer les rappels pour jobs approchant deadline
        results.reminders = await sendDeadlineReminders();

        // Trouver et traiter les jobs expires
        const expiredJobs = await findExpiredJobs();
        console.log(`\n📋 ${expiredJobs.length} job(s) depasse(s) trouve(s)`);

        for (const job of expiredJobs) {
            try {
                const result = await cancelExpiredJob(job);

                if (result.action === 'cancelled') {
                    results.expired.push(result);
                } else {
                    results.waiting.push(result);
                }
            } catch (error) {
                console.error(`Erreur traitement job ${job._id}:`, error);
                results.errors.push({ jobId: job._id, error: error.message });
            }
        }

        console.log('\n📊 Resultats:');
        console.log(`   - Jobs annules: ${results.expired.length}`);
        console.log(`   - Jobs en attente (< ${CONFIG.AUTO_CANCEL_DELAY_MINUTES} min): ${results.waiting.length}`);
        console.log(`   - Rappels envoyes: ${results.reminders}`);
        console.log(`   - Erreurs: ${results.errors.length}`);

    } catch (error) {
        console.error('❌ Erreur processExpiredJobs:', error);
        results.errors.push({ error: error.message });
    }

    return results;
}

/**
 * Obtient les statistiques des jobs expires
 */
async function getExpiredJobsStats() {
    const now = new Date();
    const today = new Date(now.setHours(0, 0, 0, 0));

    const stats = {
        totalExpiredToday: await Reservation.countDocuments({
            status: 'cancelled',
            cancelledBy: 'system',
            cancelledAt: { $gte: today },
        }),
        currentlyOverdue: await Reservation.countDocuments({
            status: { $in: ['pending', 'assigned', 'enRoute', 'inProgress'] },
            deadlineTime: { $lt: new Date() },
        }),
        workersWithWarnings: await User.countDocuments({
            role: 'snowWorker',
            'workerProfile.warningCount': { $gt: 0 },
        }),
        suspendedWorkers: await User.countDocuments({
            role: 'snowWorker',
            'workerProfile.isSuspended': true,
        }),
    };

    return stats;
}

module.exports = {
    processExpiredJobs,
    findExpiredJobs,
    cancelExpiredJob,
    sendDeadlineReminders,
    getExpiredJobsStats,
    CONFIG,
};
