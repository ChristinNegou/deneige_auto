/**
 * Mise en relation des reservations et des deneigeurs : les regles qui
 * decident qu'un travail est ouvert et qu'un deneigeur peut le prendre, la
 * notification des deneigeurs proches et l'alerte au client quand personne
 * n'a encore accepte.
 */

const Reservation = require('../models/Reservation');
const User = require('../models/User');
const Notification = require('../models/Notification');

/** Meme rayon que l'app du deneigeur (AppConfig.workerSearchRadiusKm). */
const DISPATCH_RADIUS_KM = 25;
/** Plafond de deneigeurs prevenus par vague, les plus proches d'abord. */
const MAX_WORKERS_PER_WAVE = 25;
/** Alerte au client quand l'heure limite approche sans deneigeur... */
const CLIENT_ALERT_BEFORE_DEADLINE_MINUTES = 60;
/** ...mais pas avant que les deneigeurs aient eu le temps de repondre. */
const CLIENT_ALERT_MIN_AGE_MINUTES = 10;

/** Statuts d'un travail accepte mais pas termine (compte dans la limite). */
const ACTIVE_JOB_STATUSES = ['assigned', 'enRoute', 'inProgress'];

/**
 * Suspendu par un admin (racine du compte) ou automatiquement apres trop de
 * travaux non termines, d'annulations ou de litiges (workerProfile) : dans
 * tous les cas, plus de travail. Une suspension datee prend fin d'elle-meme.
 */
const isWorkerSuspended = (user) => {
    const active = (flag, until) => Boolean(flag) && (!until || new Date(until) > new Date());
    return active(user?.isSuspended, user?.suspendedUntil)
        || active(user?.workerProfile?.isSuspended, user?.workerProfile?.suspendedUntil);
};

/** Meme regle que le middleware verificationRequired. */
const isWorkerVerified = (user) => {
    if (process.env.IDENTITY_VERIFICATION_ENABLED !== 'true') return true;
    const verification = user?.workerProfile?.identityVerification;
    if (verification?.status !== 'approved') return false;
    return !verification.expiresAt || new Date(verification.expiresAt) >= new Date();
};

/**
 * Une reservation peut etre proposee puis acceptee si elle attend un
 * deneigeur, est payee et que l'heure limite (voiture prete) n'est pas passee.
 */
const openJobQuery = (now) => ({
    status: 'pending',
    workerId: null,
    paymentStatus: 'paid',
    deadlineTime: { $gt: now },
});

/** true si le deneigeur possede tout l'equipement requis. */
const workerHasRequiredEquipment = (workerEquipment, requiredEquipment) => {
    if (!requiredEquipment || requiredEquipment.length === 0) return true;
    if (!workerEquipment || workerEquipment.length === 0) return false;
    return requiredEquipment.every((eq) => workerEquipment.includes(eq));
};

const timeFmt = new Intl.DateTimeFormat('fr-CA', {
    hour: 'numeric',
    minute: '2-digit',
    timeZone: 'America/Toronto',
});
/** "7 h 30" */
const formatTime = (date) => timeFmt.format(new Date(date));

const formatKm = (km) => km.toLocaleString('fr-CA', { maximumFractionDigits: 1 });

/**
 * Previent par notification (et push) les deneigeurs en ligne qui pourraient
 * prendre la reservation : dans le rayon, verifies, non suspendus, equipes et
 * sous leur limite de travaux. Ceux deja prevenus ne le sont pas deux fois.
 * @param {Document|Object} reservation
 * @returns {Promise<number>} nombre de deneigeurs prevenus
 */
async function notifyNearbyWorkers(reservation) {
    const now = new Date();
    const fresh = await Reservation.findOne({ _id: reservation._id, ...openJobQuery(now) })
        .select('location deadlineTime departureTime serviceOptions snowDepthCm dispatch')
        .lean();
    const coordinates = fresh?.location?.coordinates;
    if (!fresh || !coordinates || (coordinates[0] === 0 && coordinates[1] === 0)) return 0;

    const alreadyNotified = (fresh.dispatch?.notifiedWorkers || []).map(String);
    const candidates = await User.aggregate([
        {
            $geoNear: {
                near: { type: 'Point', coordinates },
                key: 'workerProfile.currentLocation',
                distanceField: 'distance',
                maxDistance: DISPATCH_RADIUS_KM * 1000,
                query: {
                    role: 'snowWorker',
                    'workerProfile.isAvailable': true,
                    // Reglage "Nouvelles demandes" du profil deneigeur
                    'workerProfile.notificationPreferences.newJobs': { $ne: false },
                },
                spherical: true,
            },
        },
        { $limit: MAX_WORKERS_PER_WAVE * 4 },
        {
            $project: {
                distance: 1,
                isSuspended: 1,
                suspendedUntil: 1,
                'workerProfile.isSuspended': 1,
                'workerProfile.suspendedUntil': 1,
                'workerProfile.identityVerification': 1,
                'workerProfile.equipmentList': 1,
                'workerProfile.maxActiveJobs': 1,
            },
        },
    ]);

    const required = Reservation.computeRequiredEquipment(fresh);
    const eligible = candidates.filter((w) => !alreadyNotified.includes(String(w._id))
        && !isWorkerSuspended(w)
        && isWorkerVerified(w)
        && workerHasRequiredEquipment(w.workerProfile?.equipmentList || [], required));
    if (eligible.length === 0) return 0;

    // Limite de travaux en cours
    const busy = await Reservation.aggregate([
        { $match: { workerId: { $in: eligible.map((w) => w._id) }, status: { $in: ACTIVE_JOB_STATUSES } } },
        { $group: { _id: '$workerId', count: { $sum: 1 } } },
    ]);
    const activeCount = new Map(busy.map((b) => [String(b._id), b.count]));
    const recipients = eligible
        .filter((w) => (activeCount.get(String(w._id)) || 0) < (w.workerProfile?.maxActiveJobs || 3))
        .slice(0, MAX_WORKERS_PER_WAVE);
    if (recipients.length === 0) return 0;

    // Marquer avant d'envoyer : une vague concurrente ne les previendra pas
    await Reservation.updateOne(
        { _id: fresh._id },
        { $addToSet: { 'dispatch.notifiedWorkers': { $each: recipients.map((w) => w._id) } } },
    );

    const departure = formatTime(fresh.departureTime);
    await Promise.all(recipients.map((w) => Notification.createNotification({
        userId: w._id,
        type: 'urgentRequest',
        title: 'Nouvelle demande près de vous',
        message: `Déneigement à ${formatKm(w.distance / 1000)} km, voiture à dégager avant ${formatTime(fresh.deadlineTime)} (départ du client à ${departure}).`,
        reservationId: fresh._id,
        priority: 'high',
        metadata: { distanceKm: Math.round(w.distance / 100) / 10 },
    }).catch((err) => console.error('[dispatch] Notification deneigeur echouee:', err.message))));

    return recipients.length;
}

/**
 * Reservations payees que personne n'a encore acceptees a l'approche de
 * l'heure limite : on previent le client (une seule fois) et on relance les
 * deneigeurs passes en ligne depuis.
 * @returns {Promise<number>} nombre de clients alertes
 */
async function alertUnassignedReservations() {
    const now = new Date();
    const pending = await Reservation.find({
        ...openJobQuery(now),
        deadlineTime: { $gt: now, $lte: new Date(now.getTime() + CLIENT_ALERT_BEFORE_DEADLINE_MINUTES * 60000) },
        createdAt: { $lte: new Date(now.getTime() - CLIENT_ALERT_MIN_AGE_MINUTES * 60000) },
        'dispatch.clientAlertedAt': null,
    }).select('_id userId deadlineTime').lean();

    let alerted = 0;
    for (const r of pending) {
        // Une seule alerte meme si deux taches tournent en meme temps
        const claimed = await Reservation.findOneAndUpdate(
            { _id: r._id, ...openJobQuery(now), 'dispatch.clientAlertedAt': null },
            { $set: { 'dispatch.clientAlertedAt': now } },
        );
        if (!claimed) continue;

        try {
            await Notification.createNotification({
                userId: r.userId,
                type: 'searchingWorker',
                title: 'Nous cherchons encore un déneigeur',
                message: `Aucun déneigeur n’a encore accepté votre demande. Nous prévenons ceux qui se connectent. Si personne ne l’accepte avant ${formatTime(r.deadlineTime)}, elle sera annulée et remboursée en entier.`,
                reservationId: r._id,
                priority: 'high',
            });
            alerted += 1;
        } catch (err) {
            console.error('[dispatch] Alerte client echouee:', err.message);
        }
        await notifyNearbyWorkers(r).catch((err) => console.error('[dispatch] Relance echouee:', err.message));
    }
    return alerted;
}

module.exports = {
    DISPATCH_RADIUS_KM,
    ACTIVE_JOB_STATUSES,
    isWorkerSuspended,
    openJobQuery,
    workerHasRequiredEquipment,
    notifyNearbyWorkers,
    alertUnassignedReservations,
    formatTime,
};
