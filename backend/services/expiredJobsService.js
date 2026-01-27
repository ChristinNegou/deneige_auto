/**
 * Service de gestion des réservations expirées.
 * Détecte et traite automatiquement les réservations non complétées après leur deadline :
 * annulation, remboursement Stripe, pénalisation du déneigeur et notifications.
 */

const Reservation = require('../models/Reservation');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { sendPushNotification } = require('./firebaseService');

// --- Configuration ---

/** Délais et seuils pour la gestion des jobs expirés (en minutes). */
const CONFIG = {
    // Delai apres deadline avant annulation automatique
    AUTO_CANCEL_DELAY_MINUTES: 30,
    // Delai pour envoyer un rappel au worker avant deadline
    REMINDER_BEFORE_DEADLINE_MINUTES: 15,
    // Penalite pour le worker (nombre de warnings avant suspension)
    MAX_WARNINGS_BEFORE_SUSPENSION: 3,
};

// --- Détection des jobs expirés ---

/**
 * Recherche tous les jobs actifs dont la deadline est dépassée.
 * @returns {Promise<Array>} Réservations expirées avec leurs relations peuplées
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
 * Recherche les jobs assignés/en route dont la deadline est dans les X prochaines minutes.
 * @returns {Promise<Array>} Réservations approchant de leur deadline
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

// --- Annulation et conséquences ---

/**
 * Annule un job expiré : met à jour le statut, initie le remboursement Stripe,
 * pénalise le déneigeur et notifie les deux parties. Approche transactionnelle.
 * @param {Document} reservation - La réservation expirée (peuplée)
 * @returns {Promise<Object>} Résultat { action: 'cancelled'|'waiting'|'error', ... }
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

    // Sauvegarder l'état précédent pour rollback si nécessaire
    const previousStatus = reservation.status;
    const previousPaymentStatus = reservation.paymentStatus;

    try {
        // Mettre a jour le statut de la reservation
        reservation.status = 'cancelled';
        reservation.cancelledAt = now;
        reservation.cancelledBy = 'system';
        reservation.cancelReason = `Annulation automatique - Job non complete ${minutesOverdue} minutes apres la deadline`;

        // Marquer pour remboursement si paye (le remboursement réel sera fait après la sauvegarde)
        const needsRefund = reservation.paymentStatus === 'paid' && reservation.paymentIntentId;
        if (needsRefund) {
            reservation.paymentStatus = 'pending_refund';
            reservation.refundAmount = reservation.totalPrice;
        }

        // Sauvegarder d'abord la reservation - POINT CRITIQUE
        await reservation.save();
        console.log(`   ✅ Reservation ${reservation._id} sauvegardée avec statut 'cancelled'`);

        // Effectuer le remboursement Stripe si nécessaire
        if (needsRefund) {
            try {
                const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
                await stripe.refunds.create({
                    payment_intent: reservation.paymentIntentId,
                    amount: Math.round(reservation.totalPrice * 100),
                });
                reservation.paymentStatus = 'refunded';
                reservation.refundedAt = now;
                await reservation.save();
                console.log(`   ✅ Remboursement Stripe effectué pour ${reservation._id}`);
            } catch (refundError) {
                console.error(`   ⚠️ Erreur remboursement Stripe pour ${reservation._id}:`, refundError.message);
                // Le statut reste 'pending_refund' pour traitement manuel
            }
        }

        // Les notifications et pénalités sont envoyées APRÈS la sauvegarde réussie
        // En cas d'échec de notification, le job est déjà annulé correctement

        // Gerer les consequences pour le worker (non-bloquant)
        if (reservation.workerId) {
            penalizeWorker(reservation.workerId, reservation).catch(err => {
                console.error(`   ⚠️ Erreur pénalisation worker:`, err.message);
            });
        }

        // Notifier le client (non-bloquant)
        notifyClientJobExpired(reservation).catch(err => {
            console.error(`   ⚠️ Erreur notification client:`, err.message);
        });

        // Notifier le worker (non-bloquant)
        if (reservation.workerId) {
            notifyWorkerJobExpired(reservation).catch(err => {
                console.error(`   ⚠️ Erreur notification worker:`, err.message);
            });
        }

        return { action: 'cancelled', minutesOverdue, reservationId: reservation._id };

    } catch (saveError) {
        // Rollback en mémoire (la DB n'a pas été modifiée)
        console.error(`   ❌ Erreur lors de l'annulation du job ${reservation._id}:`, saveError.message);
        reservation.status = previousStatus;
        reservation.paymentStatus = previousPaymentStatus;
        reservation.cancelledAt = undefined;
        reservation.cancelledBy = undefined;
        reservation.cancelReason = undefined;
        reservation.refundAmount = undefined;

        return { action: 'error', error: saveError.message, reservationId: reservation._id };
    }
}

// --- Pénalisation ---

/**
 * Pénalise le déneigeur pour un job non complété : avertissement, historique, et suspension
 * automatique après 3 avertissements.
 * @param {ObjectId} workerId - Identifiant du déneigeur
 * @param {Document} reservation - La réservation expirée
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
                title: '🚫 Compte déneigeur suspendu',
                message: `Votre compte déneigeur a été temporairement suspendu suite à ${worker.workerProfile.warningCount} jobs non complétés dans les délais. Cette suspension restera en vigueur jusqu'à examen par notre équipe. Pour rétablir votre compte, veuillez contacter le support en expliquant les circonstances.`,
            });
        }

        await worker.save();
        console.log(`   ⚠️ Worker ${worker.email} penalise (warning ${worker.workerProfile.warningCount})`);

    } catch (error) {
        console.error('Erreur penalisation worker:', error);
    }
}

// --- Notifications ---

/**
 * Notifie le client que sa réservation a été annulée et qu'un remboursement est prévu.
 * @param {Document} reservation - La réservation annulée (peuplée avec userId et vehicle)
 */
async function notifyClientJobExpired(reservation) {
    try {
        const client = reservation.userId;
        const vehicle = reservation.vehicle;
        const vehicleName = vehicle ? `${vehicle.brand || ''} ${vehicle.model || ''}`.trim() : 'votre véhicule';
        const refundAmount = reservation.totalPrice ? reservation.totalPrice.toFixed(2) : '';

        const notification = await Notification.create({
            userId: client._id,
            type: 'reservationUpdate',
            title: '😔 Réservation annulée - Remboursement prévu',
            message: `Nous sommes désolés, votre réservation pour ${vehicleName} a dû être annulée car le déneigeur n'a pas pu compléter le travail dans le délai prévu.${refundAmount ? ` Un remboursement de ${refundAmount}$ sera automatiquement crédité sur votre carte sous 5-10 jours ouvrables.` : ' Vous serez remboursé intégralement.'} Nous nous excusons pour ce désagrément.`,
            metadata: {
                reservationId: reservation._id,
                reason: 'expired',
                refundAmount: reservation.totalPrice,
            },
        });

        // Envoyer push notification
        if (client.fcmToken) {
            await sendPushNotification(
                client.fcmToken,
                '😔 Réservation annulée',
                `Votre réservation pour ${vehicleName} a été annulée. Un remboursement sera effectué automatiquement.`,
                { reservationId: reservation._id.toString(), type: 'reservation_expired' }
            );
        }

        console.log(`   📱 Client ${client.email} notifié`);

    } catch (error) {
        console.error('Erreur notification client:', error);
    }
}

/**
 * Notifie le déneigeur que le job a été annulé et qu'un avertissement a été ajouté.
 * @param {Document} reservation - La réservation annulée (peuplée avec workerId)
 */
async function notifyWorkerJobExpired(reservation) {
    try {
        const worker = reservation.workerId;
        if (!worker) return;

        const vehicle = reservation.vehicle;
        const vehicleName = vehicle ? `${vehicle.brand || ''} ${vehicle.model || ''}`.trim() : 'le véhicule';
        const clientName = reservation.userId?.firstName || 'le client';

        const notification = await Notification.create({
            userId: worker._id,
            type: 'systemNotification',
            title: '⚠️ Job annulé - Délai dépassé',
            message: `Le job pour ${vehicleName} de ${clientName} (réf: #${reservation._id.toString().slice(-6)}) a été annulé car il n'a pas été complété avant la deadline. Un avertissement a été ajouté à votre compte. Rappel: 3 avertissements entraînent une suspension temporaire.`,
            metadata: {
                reservationId: reservation._id,
                reason: 'expired',
            },
        });

        // Envoyer push notification
        if (worker.fcmToken) {
            await sendPushNotification(
                worker.fcmToken,
                '⚠️ Job annulé - Avertissement',
                `Le job #${reservation._id.toString().slice(-6)} a été annulé (délai dépassé). Un avertissement a été ajouté à votre compte.`,
                { reservationId: reservation._id.toString(), type: 'job_expired_warning' }
            );
        }

        console.log(`   📱 Worker ${worker.email} notifié`);

    } catch (error) {
        console.error('Erreur notification worker:', error);
    }
}

// --- Rappels ---

/**
 * Envoie des rappels aux déneigeurs pour les jobs approchant de leur deadline.
 * Utilise des insertions batch (insertMany) pour optimiser les performances.
 * @returns {Promise<number>} Nombre de rappels envoyés
 */
async function sendDeadlineReminders() {
    const approachingJobs = await findJobsApproachingDeadline();

    // Filtrer les jobs avec workers valides
    const jobsWithWorkers = approachingJobs.filter(job => job.workerId);

    if (jobsWithWorkers.length === 0) {
        return 0;
    }

    const now = new Date();

    // Préparer toutes les notifications en batch
    const notificationsToCreate = jobsWithWorkers.map(job => {
        const worker = job.workerId;
        const minutesLeft = Math.floor((job.deadlineTime - now) / (1000 * 60));
        const clientName = job.userId?.firstName || 'le client';
        const vehicleName = job.vehicle ? `${job.vehicle.brand || ''} ${job.vehicle.model || ''}`.trim() : 'le véhicule';

        return {
            userId: worker._id,
            type: 'reminder',
            title: `⏰ ${minutesLeft} min restantes - Action requise`,
            message: `Il vous reste ${minutesLeft} minutes pour compléter le déneigement de ${vehicleName} pour ${clientName}. Passé ce délai, le job sera automatiquement annulé et un avertissement sera ajouté à votre compte.`,
            metadata: {
                reservationId: job._id,
                type: 'deadline_reminder',
                minutesLeft,
            },
        };
    });

    // Insertion batch des notifications (1 seule requête DB)
    try {
        await Notification.insertMany(notificationsToCreate, { ordered: false });
    } catch (error) {
        console.error('Erreur batch insertion notifications:', error.message);
    }

    // Envoyer les push notifications en parallèle (non-bloquant)
    const pushPromises = jobsWithWorkers
        .filter(job => job.workerId?.fcmToken)
        .map(job => {
            const worker = job.workerId;
            const minutesLeft = Math.floor((job.deadlineTime - now) / (1000 * 60));
            const clientName = job.userId?.firstName || 'le client';

            return sendPushNotification(
                worker.fcmToken,
                `⏰ ${minutesLeft} min restantes!`,
                `Terminez le job de ${clientName} rapidement pour éviter l'annulation automatique et un avertissement.`,
                { reservationId: job._id.toString(), type: 'deadline_reminder', urgent: true }
            ).catch(err => {
                console.error(`Push notification error for ${worker.email}:`, err.message);
            });
        });

    // Attendre toutes les push notifications en parallèle
    await Promise.allSettled(pushPromises);

    console.log(`   ⏰ ${jobsWithWorkers.length} rappels envoyes en batch`);

    return jobsWithWorkers.length;
}

// --- Traitement principal (CRON) ---

/**
 * Traite tous les jobs expirés : envoie les rappels puis annule les jobs en retard.
 * Appelée périodiquement par le cron job.
 * @returns {Promise<Object>} Résultat { expired, waiting, reminders, errors }
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

// --- Statistiques ---

/**
 * Récupère les statistiques des jobs expirés pour le tableau de bord admin.
 * @returns {Promise<Object>} { totalExpiredToday, currentlyOverdue, workersWithWarnings, suspendedWorkers }
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
