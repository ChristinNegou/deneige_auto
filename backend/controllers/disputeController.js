const Dispute = require('../models/Dispute');
const Reservation = require('../models/Reservation');
const User = require('../models/User');
const Notification = require('../models/Notification');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { sendPushNotification, sendMulticastNotification } = require('../services/firebaseService');

// Configuration des pénalités
const PENALTY_CONFIG = {
    noShow: {
        first: 'warning',
        second: 'suspension_3days',
        third: 'suspension_7days',
        fourth: 'suspension_30days',
        fifth: 'permanent_ban',
    },
    qualityIssue: {
        first: 'warning',
        second: 'warning',
        third: 'suspension_3days',
        fourth: 'suspension_7days',
        fifth: 'suspension_30days',
    },
    lateCancellation: {
        threshold: 3, // Nombre avant avertissement
        suspensionThreshold: 5,
    },
};

// Délais de réponse (en heures)
const DEADLINES = {
    response: 48,      // 48h pour répondre
    resolution: 168,   // 7 jours pour résolution
    appeal: 72,        // 72h pour faire appel
};

// ============== HELPER FUNCTIONS ==============

// Calculer la distance entre deux points GPS (en mètres)
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371e3; // Rayon de la Terre en mètres
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
        Math.cos(φ1) * Math.cos(φ2) *
        Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
};

// Envoyer une notification
const sendNotification = async (userId, title, body, type, data = {}) => {
    try {
        // Créer la notification en base de données
        const notification = await Notification.create({
            userId,
            title,
            message: body,
            type,
            metadata: data,
        });

        // Envoyer push notification via FCM si l'utilisateur a un token
        const user = await User.findById(userId).select('fcmToken notificationSettings');
        if (user?.fcmToken && user.notificationSettings?.pushEnabled !== false) {
            const result = await sendPushNotification(
                user.fcmToken,
                title,
                body,
                {
                    ...data,
                    notificationId: notification._id.toString(),
                    type,
                }
            );

            // Supprimer le token s'il est invalide
            if (result?.invalidToken) {
                await User.findByIdAndUpdate(userId, { fcmToken: null });
                console.log(`[Dispute] Removed invalid FCM token for user ${userId}`);
            }
        }
    } catch (error) {
        console.error('Error sending notification:', error);
    }
};

// Notifier tous les admins
const notifyAllAdmins = async (title, body, type, data = {}) => {
    try {
        // Récupérer tous les admins avec leurs tokens FCM
        const admins = await User.find({ role: 'admin' }).select('_id fcmToken notificationSettings');

        // Créer des notifications en base pour chaque admin
        const notifications = admins.map(admin => ({
            userId: admin._id,
            title,
            message: body,
            type,
            priority: 'high',
            metadata: data,
        }));

        if (notifications.length > 0) {
            await Notification.insertMany(notifications);
        }

        // Envoyer les push notifications aux admins qui ont des tokens FCM valides
        const fcmTokens = admins
            .filter(admin => admin.fcmToken && admin.notificationSettings?.pushEnabled !== false)
            .map(admin => admin.fcmToken);

        if (fcmTokens.length > 0) {
            const result = await sendMulticastNotification(fcmTokens, title, body, { ...data, type });

            // Nettoyer les tokens invalides
            if (result?.invalidTokens?.length > 0) {
                await User.updateMany(
                    { fcmToken: { $in: result.invalidTokens } },
                    { fcmToken: null }
                );
                console.log(`[Dispute] Removed ${result.invalidTokens.length} invalid admin FCM tokens`);
            }
        }

        console.log(`[Dispute] Notified ${admins.length} admins: ${title}`);
    } catch (error) {
        console.error('Error notifying admins:', error);
    }
};

// Appliquer une pénalité à un utilisateur
const applyPenalty = async (userId, penaltyType, reason, adminId = null) => {
    const user = await User.findById(userId);
    if (!user) return null;

    const isWorker = user.role === 'snowWorker';
    const profile = isWorker ? 'workerProfile' : 'clientProfile';

    let suspensionDays = 0;
    let isPermanent = false;

    switch (penaltyType) {
        case 'warning':
            if (isWorker) {
                user.workerProfile.warningCount += 1;
            } else {
                user.clientProfile.warningCount += 1;
                user.clientProfile.warnings.push({
                    reason,
                    issuedAt: new Date(),
                    issuedBy: adminId,
                });
            }
            break;
        case 'suspension_3days':
            suspensionDays = 3;
            break;
        case 'suspension_7days':
            suspensionDays = 7;
            break;
        case 'suspension_30days':
            suspensionDays = 30;
            break;
        case 'permanent_ban':
            isPermanent = true;
            break;
    }

    if (suspensionDays > 0 || isPermanent) {
        if (isWorker) {
            user.workerProfile.isSuspended = true;
            user.workerProfile.suspensionReason = reason;
            user.workerProfile.suspendedUntil = isPermanent
                ? new Date('2099-12-31')
                : new Date(Date.now() + suspensionDays * 24 * 60 * 60 * 1000);
        } else {
            user.isSuspended = true;
            user.suspensionReason = reason;
            user.suspendedUntil = isPermanent
                ? new Date('2099-12-31')
                : new Date(Date.now() + suspensionDays * 24 * 60 * 60 * 1000);
        }
    }

    // Mettre à jour le score de fiabilité
    if (isWorker) {
        user.workerProfile.reliabilityScore = Math.max(0, user.workerProfile.reliabilityScore - 10);
    } else {
        user.clientProfile.reliabilityScore = Math.max(0, user.clientProfile.reliabilityScore - 10);
    }

    await user.save();

    // Notifier l'utilisateur
    await sendNotification(
        userId,
        isPermanent ? 'Compte banni' : suspensionDays > 0 ? 'Compte suspendu' : 'Avertissement',
        reason,
        'penalty'
    );

    return { penaltyType, suspensionDays, isPermanent };
};

// Déterminer la pénalité en fonction de l'historique
const determinePenalty = (type, count) => {
    const config = PENALTY_CONFIG[type];
    if (!config) return 'warning';

    if (count <= 1) return config.first || 'warning';
    if (count === 2) return config.second || 'warning';
    if (count === 3) return config.third || 'suspension_3days';
    if (count === 4) return config.fourth || 'suspension_7days';
    return config.fifth || 'suspension_30days';
};

// Traiter un remboursement
const processRefund = async (reservation, amount, reason) => {
    try {
        if (!reservation.paymentIntentId) {
            return { success: false, error: 'Pas de paiement à rembourser' };
        }

        const refund = await stripe.refunds.create({
            payment_intent: reservation.paymentIntentId,
            amount: Math.round(amount * 100), // Stripe utilise les centimes
            reason: 'requested_by_customer',
            metadata: {
                reservationId: reservation._id.toString(),
                disputeReason: reason,
            },
        });

        // Mettre à jour la réservation
        reservation.paymentStatus = amount >= reservation.totalPrice ? 'refunded' : 'partially_refunded';
        reservation.refundAmount = (reservation.refundAmount || 0) + amount;
        reservation.refundedAt = new Date();
        await reservation.save();

        return { success: true, refundId: refund.id, amount };
    } catch (error) {
        console.error('Error processing refund:', error);
        return { success: false, error: error.message };
    }
};

// Générer le message de notification pour le plaignant
const generateClaimantNotification = (decision, refundAmount, disputeType) => {
    const disputeTypeLabels = {
        no_show: 'absence du déneigeur',
        incomplete_work: 'travail incomplet',
        quality_issue: 'qualité du travail',
        late_arrival: 'retard',
        damage: 'dommages',
        wrong_location: 'mauvais emplacement',
        overcharge: 'surfacturation',
        unprofessional: 'comportement inapproprié',
        other: 'votre réclamation',
    };

    const typeLabel = disputeTypeLabels[disputeType] || 'votre réclamation';

    switch (decision) {
        case 'favor_claimant':
            return {
                title: '✅ Litige résolu en votre faveur',
                message: refundAmount > 0
                    ? `Bonne nouvelle! Suite à l'examen de votre litige concernant ${typeLabel}, nous avons décidé en votre faveur. Un remboursement de ${refundAmount.toFixed(2)}$ sera crédité sur votre carte sous 5-10 jours ouvrables.`
                    : `Bonne nouvelle! Suite à l'examen de votre litige concernant ${typeLabel}, nous avons décidé en votre faveur. Les mesures appropriées ont été prises.`,
            };

        case 'full_refund':
            return {
                title: '💰 Remboursement complet accordé',
                message: `Suite à votre réclamation concernant ${typeLabel}, nous vous accordons un remboursement complet de ${refundAmount.toFixed(2)}$. Le montant sera crédité sur votre carte sous 5-10 jours ouvrables.`,
            };

        case 'partial_refund':
            return {
                title: '💵 Remboursement partiel accordé',
                message: `Après examen de votre litige concernant ${typeLabel}, nous vous accordons un remboursement partiel de ${refundAmount.toFixed(2)}$. Le montant sera crédité sur votre carte sous 5-10 jours ouvrables.`,
            };

        case 'favor_respondent':
            return {
                title: '📋 Décision concernant votre litige',
                message: `Après examen approfondi de votre réclamation concernant ${typeLabel}, nous n'avons pas pu confirmer les faits rapportés. Aucun remboursement ne sera effectué. Vous pouvez faire appel dans les 72h si vous avez des éléments supplémentaires.`,
            };

        case 'no_action':
            return {
                title: '📋 Litige examiné - Aucune action',
                message: `Après examen de votre litige concernant ${typeLabel}, nous avons conclu qu'aucune action n'est nécessaire. Si vous avez des questions, n'hésitez pas à nous contacter.`,
            };

        case 'mutual_agreement':
            return {
                title: '🤝 Accord trouvé',
                message: refundAmount > 0
                    ? `Un accord a été trouvé concernant votre litige. Un remboursement de ${refundAmount.toFixed(2)}$ vous sera crédité sous 5-10 jours ouvrables.`
                    : `Un accord a été trouvé concernant votre litige. Merci de votre compréhension.`,
            };

        default:
            return {
                title: '📋 Litige résolu',
                message: refundAmount > 0
                    ? `Votre litige a été résolu. Un remboursement de ${refundAmount.toFixed(2)}$ sera effectué.`
                    : `Votre litige a été résolu. Merci de votre patience.`,
            };
    }
};

// Générer le message de notification pour le défenseur
const generateRespondentNotification = (decision, penalty, disputeType, claimantRole) => {
    const isWorkerDefendant = claimantRole === 'client';

    const disputeTypeLabels = {
        no_show: 'absence signalée',
        incomplete_work: 'travail incomplet signalé',
        quality_issue: 'qualité du travail',
        late_arrival: 'retard signalé',
        damage: 'dommages signalés',
        wrong_location: 'erreur d\'emplacement',
        overcharge: 'surfacturation signalée',
        unprofessional: 'comportement signalé',
        other: 'réclamation',
    };

    const penaltyLabels = {
        warning: 'Un avertissement a été ajouté à votre dossier.',
        suspension_3days: 'Votre compte est suspendu pour 3 jours.',
        suspension_7days: 'Votre compte est suspendu pour 7 jours.',
        suspension_30days: 'Votre compte est suspendu pour 30 jours.',
        permanent_ban: 'Votre compte a été définitivement suspendu.',
    };

    const typeLabel = disputeTypeLabels[disputeType] || 'réclamation';
    const penaltyMessage = penalty && penalty !== 'none' ? ` ${penaltyLabels[penalty] || ''}` : '';

    switch (decision) {
        case 'favor_claimant':
        case 'full_refund':
            return {
                title: '⚠️ Litige résolu - Décision défavorable',
                message: isWorkerDefendant
                    ? `Le litige concernant ${typeLabel} a été résolu en faveur du client.${penaltyMessage} Nous vous encourageons à maintenir un service de qualité.`
                    : `Le litige concernant ${typeLabel} a été résolu en faveur du plaignant.${penaltyMessage}`,
            };

        case 'partial_refund':
            return {
                title: '📋 Litige résolu - Remboursement partiel',
                message: isWorkerDefendant
                    ? `Le litige concernant ${typeLabel} a abouti à un remboursement partiel au client.${penaltyMessage} Aucune faute majeure n'a été retenue.`
                    : `Le litige concernant ${typeLabel} a abouti à un remboursement partiel.${penaltyMessage}`,
            };

        case 'favor_respondent':
            return {
                title: '✅ Litige résolu en votre faveur',
                message: isWorkerDefendant
                    ? `Bonne nouvelle! Le litige concernant ${typeLabel} a été résolu en votre faveur. Aucune mesure n'a été prise contre vous. Continuez votre excellent travail!`
                    : `Le litige concernant ${typeLabel} a été résolu en votre faveur. Aucune mesure n'a été prise.`,
            };

        case 'no_action':
            return {
                title: '📋 Litige classé sans suite',
                message: `Le litige concernant ${typeLabel} a été classé sans suite. Aucune action n'a été prise contre vous.`,
            };

        case 'mutual_agreement':
            return {
                title: '🤝 Accord trouvé',
                message: `Un accord a été trouvé concernant le litige.${penaltyMessage} Merci de votre coopération.`,
            };

        default:
            return {
                title: '📋 Litige résolu',
                message: `Le litige concernant ${typeLabel} a été résolu.${penaltyMessage}`,
            };
    }
};

// ============== MAIN CONTROLLER FUNCTIONS ==============

// @desc    Signaler un no-show (déneigeur pas venu)
// @route   POST /api/disputes/report-no-show/:reservationId
// @access  Private (client only)
exports.reportNoShow = async (req, res) => {
    try {
        const { reservationId } = req.params;
        const { description, photos, gpsLocation } = req.body;

        // Vérifier que la réservation existe
        const reservation = await Reservation.findById(reservationId)
            .populate('workerId', 'firstName lastName workerProfile');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Vérifier que c'est bien le client de la réservation
        if (reservation.userId.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Vous n\'êtes pas autorisé à signaler cette réservation',
            });
        }

        // Vérifier le statut de la réservation
        if (!['assigned', 'enRoute'].includes(reservation.status)) {
            return res.status(400).json({
                success: false,
                message: 'Le signalement no-show n\'est possible que pour les réservations assignées ou en route',
            });
        }

        // Vérifier que l'heure de départ est passée
        const now = new Date();
        const departureTime = new Date(reservation.departureTime);
        const graceMinutes = 30; // 30 minutes de grâce après l'heure de départ

        if (now < new Date(departureTime.getTime() + graceMinutes * 60 * 1000)) {
            return res.status(400).json({
                success: false,
                message: `Vous pouvez signaler un no-show ${graceMinutes} minutes après l'heure de départ prévue`,
            });
        }

        // Vérifier si un dispute existe déjà
        const existingDispute = await Dispute.findOne({
            reservation: reservationId,
            type: 'no_show',
            status: { $nin: ['closed', 'resolved'] },
        });

        if (existingDispute) {
            return res.status(400).json({
                success: false,
                message: 'Un signalement no-show existe déjà pour cette réservation',
            });
        }

        // Analyser automatiquement les données GPS du worker
        let autoResolutionEligible = false;
        let autoResolutionReason = '';

        // Si le worker n'a jamais marqué "en route", c'est un no-show confirmé
        if (!reservation.workerEnRouteAt) {
            autoResolutionEligible = true;
            autoResolutionReason = 'Le déneigeur n\'a jamais commencé le trajet';
        } else if (!reservation.workerArrivedAt) {
            // Worker a commencé mais n'est jamais arrivé
            autoResolutionEligible = true;
            autoResolutionReason = 'Le déneigeur n\'est jamais arrivé sur place';
        }

        // Créer le litige
        const dispute = await Dispute.create({
            type: 'no_show',
            reservation: reservationId,
            claimant: {
                user: req.user.id,
                role: 'client',
            },
            respondent: {
                user: reservation.workerId._id,
                role: 'worker',
            },
            description: description || 'Le déneigeur n\'est pas venu effectuer le travail',
            claimedAmount: reservation.totalPrice,
            priority: 'high',
            evidence: {
                photos: photos?.map(url => ({ url, uploadedAt: new Date() })) || [],
                gpsData: gpsLocation ? {
                    claimantLocation: {
                        type: 'Point',
                        coordinates: [gpsLocation.longitude, gpsLocation.latitude],
                    },
                    timestamp: new Date(),
                } : undefined,
                timestamps: {
                    reservationCreated: reservation.createdAt,
                    workerAssigned: reservation.assignedAt,
                    workerEnRoute: reservation.workerEnRouteAt,
                    workerArrived: reservation.workerArrivedAt,
                    disputeOpened: new Date(),
                },
            },
            deadlines: {
                responseDeadline: new Date(Date.now() + DEADLINES.response * 60 * 60 * 1000),
                resolutionDeadline: new Date(Date.now() + DEADLINES.resolution * 60 * 60 * 1000),
            },
            autoResolution: {
                eligible: autoResolutionEligible,
                reason: autoResolutionReason,
            },
        });

        // Ajouter l'historique
        dispute.addHistory('created', 'Signalement no-show créé par le client', req.user.id);

        // Marquer la réservation
        reservation.noShow.reported = true;
        reservation.noShow.reportedAt = new Date();
        reservation.noShow.reportedBy = req.user.id;
        reservation.dispute.hasDispute = true;
        reservation.dispute.disputeId = dispute._id;
        reservation.dispute.disputeType = 'no_show';
        reservation.dispute.disputeStatus = 'open';
        reservation.dispute.disputeOpenedAt = new Date();
        await reservation.save();

        // Mettre à jour les stats du worker
        const worker = await User.findById(reservation.workerId._id);
        if (worker) {
            worker.workerProfile.noShowCount = (worker.workerProfile.noShowCount || 0) + 1;
            worker.workerProfile.noShowHistory.push({
                reservationId,
                reportedAt: new Date(),
                disputeId: dispute._id,
                resolved: false,
                resolution: 'pending',
            });
            worker.workerProfile.disputesAgainst = (worker.workerProfile.disputesAgainst || 0) + 1;
            await worker.save();
        }

        // Mettre à jour les stats du client
        const client = await User.findById(req.user.id);
        if (client) {
            client.clientProfile.noShowReports = (client.clientProfile.noShowReports || 0) + 1;
            client.clientProfile.totalDisputes = (client.clientProfile.totalDisputes || 0) + 1;
            await client.save();
        }

        await dispute.save();

        // Notifier le worker
        await sendNotification(
            reservation.workerId._id,
            'Signalement No-Show',
            `Un client a signalé que vous n'êtes pas venu pour la réservation. Vous avez ${DEADLINES.response}h pour répondre.`,
            'dispute',
            { disputeId: dispute._id, reservationId }
        );

        // Si éligible à la résolution automatique, traiter immédiatement
        if (autoResolutionEligible) {
            await this.processAutoResolution(dispute._id);
        }

        res.status(201).json({
            success: true,
            message: 'Signalement no-show créé avec succès',
            dispute: {
                id: dispute._id,
                status: dispute.status,
                autoResolutionEligible,
                autoResolutionReason,
            },
        });
    } catch (error) {
        console.error('Error reporting no-show:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Créer un litige général
// @route   POST /api/disputes
// @access  Private
exports.createDispute = async (req, res) => {
    try {
        const {
            reservationId,
            type,
            description,
            photos,
            claimedAmount,
            gpsLocation,
        } = req.body;

        // Validation
        if (!reservationId || !type || !description) {
            return res.status(400).json({
                success: false,
                message: 'Réservation, type et description sont requis',
            });
        }

        // Vérifier la réservation
        const reservation = await Reservation.findById(reservationId)
            .populate('userId', 'firstName lastName')
            .populate('workerId', 'firstName lastName');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Déterminer qui est le plaignant et le défendeur
        const isClient = reservation.userId._id.toString() === req.user.id;
        const isWorker = reservation.workerId?._id.toString() === req.user.id;

        if (!isClient && !isWorker) {
            return res.status(403).json({
                success: false,
                message: 'Vous n\'êtes pas partie prenante de cette réservation',
            });
        }

        // Vérifier si un dispute similaire existe déjà
        const existingDispute = await Dispute.findOne({
            reservation: reservationId,
            type,
            status: { $nin: ['closed', 'resolved'] },
        });

        if (existingDispute) {
            return res.status(400).json({
                success: false,
                message: 'Un litige de ce type existe déjà pour cette réservation',
            });
        }

        // Déterminer la priorité
        let priority = 'medium';
        if (['no_show', 'damage'].includes(type)) priority = 'high';
        if (claimedAmount > 100) priority = 'high';
        if (type === 'other') priority = 'low';

        // Créer le litige
        const dispute = await Dispute.create({
            type,
            reservation: reservationId,
            claimant: {
                user: req.user.id,
                role: isClient ? 'client' : 'worker',
            },
            respondent: {
                user: isClient ? reservation.workerId._id : reservation.userId._id,
                role: isClient ? 'worker' : 'client',
            },
            description,
            claimedAmount: claimedAmount || 0,
            priority,
            evidence: {
                photos: photos?.map(url => ({ url, uploadedAt: new Date() })) || [],
                gpsData: gpsLocation ? {
                    claimantLocation: {
                        type: 'Point',
                        coordinates: [gpsLocation.longitude, gpsLocation.latitude],
                    },
                    timestamp: new Date(),
                } : undefined,
                timestamps: {
                    reservationCreated: reservation.createdAt,
                    workerAssigned: reservation.assignedAt,
                    workerEnRoute: reservation.workerEnRouteAt,
                    workerArrived: reservation.workerArrivedAt,
                    workStarted: reservation.startedAt,
                    workCompleted: reservation.completedAt,
                    disputeOpened: new Date(),
                },
            },
            deadlines: {
                responseDeadline: new Date(Date.now() + DEADLINES.response * 60 * 60 * 1000),
                resolutionDeadline: new Date(Date.now() + DEADLINES.resolution * 60 * 60 * 1000),
            },
        });

        dispute.addHistory('created', `Litige créé par ${isClient ? 'client' : 'déneigeur'}`, req.user.id);
        await dispute.save();

        // Mettre à jour la réservation
        reservation.dispute.hasDispute = true;
        reservation.dispute.disputeId = dispute._id;
        reservation.dispute.disputeType = type;
        reservation.dispute.disputeStatus = 'open';
        reservation.dispute.disputeOpenedAt = new Date();
        await reservation.save();

        // Mettre à jour les stats
        if (isClient) {
            await User.findByIdAndUpdate(req.user.id, {
                $inc: { 'clientProfile.totalDisputes': 1 },
            });
            if (reservation.workerId) {
                await User.findByIdAndUpdate(reservation.workerId._id, {
                    $inc: { 'workerProfile.disputesAgainst': 1, 'workerProfile.totalDisputes': 1 },
                });
            }
        } else {
            await User.findByIdAndUpdate(req.user.id, {
                $inc: { 'workerProfile.totalDisputes': 1 },
            });
            await User.findByIdAndUpdate(reservation.userId._id, {
                $inc: { 'clientProfile.totalDisputes': 1 },
            });
        }

        // Notifier le défendeur
        await sendNotification(
            isClient ? reservation.workerId._id : reservation.userId._id,
            'Nouveau litige ouvert',
            `Un litige a été ouvert contre vous. Vous avez ${DEADLINES.response}h pour répondre.`,
            'dispute',
            { disputeId: dispute._id, reservationId }
        );

        res.status(201).json({
            success: true,
            message: 'Litige créé avec succès',
            dispute,
        });
    } catch (error) {
        console.error('Error creating dispute:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Obtenir mes litiges
// @route   GET /api/disputes/my-disputes
// @access  Private
exports.getMyDisputes = async (req, res) => {
    try {
        const { status, type, page = 1, limit = 20 } = req.query;

        const query = {
            $or: [
                { 'claimant.user': req.user.id },
                { 'respondent.user': req.user.id },
            ],
        };

        if (status) query.status = status;
        if (type) query.type = type;

        const disputes = await Dispute.find(query)
            .populate('reservation', 'departureTime totalPrice status location')
            .populate('claimant.user', 'firstName lastName')
            .populate('respondent.user', 'firstName lastName')
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        const total = await Dispute.countDocuments(query);

        res.json({
            success: true,
            disputes,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit),
            },
        });
    } catch (error) {
        console.error('Error getting disputes:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Obtenir les détails d'un litige
// @route   GET /api/disputes/:id
// @access  Private
exports.getDisputeDetails = async (req, res) => {
    try {
        const dispute = await Dispute.findById(req.params.id)
            .populate('reservation')
            .populate('claimant.user', 'firstName lastName email phoneNumber')
            .populate('respondent.user', 'firstName lastName email phoneNumber')
            .populate('resolution.resolvedBy', 'firstName lastName')
            .populate('adminNotes.addedBy', 'firstName lastName')
            .populate('history.performedBy', 'firstName lastName');

        if (!dispute) {
            return res.status(404).json({
                success: false,
                message: 'Litige non trouvé',
            });
        }

        // Vérifier l'accès (partie prenante ou admin)
        const isParty =
            dispute.claimant.user._id.toString() === req.user.id ||
            dispute.respondent.user._id.toString() === req.user.id;
        const isAdmin = req.user.role === 'admin';

        if (!isParty && !isAdmin) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé',
            });
        }

        // Masquer les notes admin si pas admin
        if (!isAdmin) {
            dispute.adminNotes = undefined;
        }

        res.json({
            success: true,
            dispute,
        });
    } catch (error) {
        console.error('Error getting dispute details:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Répondre à un litige (défendeur)
// @route   POST /api/disputes/:id/respond
// @access  Private
exports.respondToDispute = async (req, res) => {
    try {
        const { text, photos } = req.body;

        if (!text || text.length < 20) {
            return res.status(400).json({
                success: false,
                message: 'La réponse doit contenir au moins 20 caractères',
            });
        }

        const dispute = await Dispute.findById(req.params.id);

        if (!dispute) {
            return res.status(404).json({
                success: false,
                message: 'Litige non trouvé',
            });
        }

        // Vérifier que c'est le défendeur
        if (dispute.respondent.user.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Seul le défendeur peut répondre au litige',
            });
        }

        // Vérifier que le litige est encore ouvert
        if (!['open', 'under_review', 'pending_response'].includes(dispute.status)) {
            return res.status(400).json({
                success: false,
                message: 'Ce litige ne peut plus recevoir de réponse',
            });
        }

        // Vérifier si pas déjà répondu
        if (dispute.response?.submittedAt) {
            return res.status(400).json({
                success: false,
                message: 'Vous avez déjà répondu à ce litige',
            });
        }

        // Enregistrer la réponse
        dispute.response = {
            text,
            submittedAt: new Date(),
            photos: photos?.map(url => ({ url, uploadedAt: new Date() })) || [],
        };

        dispute.status = 'under_review';
        dispute.addHistory('response_submitted', 'Réponse soumise par le défendeur', req.user.id);
        await dispute.save();

        // Notifier le plaignant
        await sendNotification(
            dispute.claimant.user,
            'Réponse au litige',
            'Le défendeur a répondu à votre litige. Un administrateur va examiner le cas.',
            'dispute',
            { disputeId: dispute._id }
        );

        res.json({
            success: true,
            message: 'Réponse enregistrée avec succès',
            dispute,
        });
    } catch (error) {
        console.error('Error responding to dispute:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Ajouter des preuves à un litige
// @route   POST /api/disputes/:id/evidence
// @access  Private
exports.addEvidence = async (req, res) => {
    try {
        const { photos, documents, description } = req.body;

        const dispute = await Dispute.findById(req.params.id);

        if (!dispute) {
            return res.status(404).json({
                success: false,
                message: 'Litige non trouvé',
            });
        }

        // Vérifier que l'utilisateur est partie prenante
        const isClaimant = dispute.claimant.user.toString() === req.user.id;
        const isRespondent = dispute.respondent.user.toString() === req.user.id;

        if (!isClaimant && !isRespondent) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé',
            });
        }

        // Vérifier que le litige est encore ouvert
        if (['resolved', 'closed'].includes(dispute.status)) {
            return res.status(400).json({
                success: false,
                message: 'Ce litige est fermé',
            });
        }

        // Ajouter les preuves
        if (photos?.length) {
            dispute.evidence.photos.push(
                ...photos.map(url => ({ url, uploadedAt: new Date(), description }))
            );
        }

        if (documents?.length) {
            dispute.evidence.documents.push(
                ...documents.map(doc => ({ ...doc, uploadedAt: new Date() }))
            );
        }

        dispute.addHistory('evidence_added', `Preuves ajoutées par ${isClaimant ? 'plaignant' : 'défendeur'}`, req.user.id);
        await dispute.save();

        res.json({
            success: true,
            message: 'Preuves ajoutées avec succès',
        });
    } catch (error) {
        console.error('Error adding evidence:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Faire appel d'une décision
// @route   POST /api/disputes/:id/appeal
// @access  Private
exports.appealDispute = async (req, res) => {
    try {
        const { reason } = req.body;

        if (!reason || reason.length < 50) {
            return res.status(400).json({
                success: false,
                message: 'La raison de l\'appel doit contenir au moins 50 caractères',
            });
        }

        const dispute = await Dispute.findById(req.params.id);

        if (!dispute) {
            return res.status(404).json({
                success: false,
                message: 'Litige non trouvé',
            });
        }

        // Vérifier que l'utilisateur peut faire appel (partie perdante)
        const isClaimant = dispute.claimant.user.toString() === req.user.id;
        const isRespondent = dispute.respondent.user.toString() === req.user.id;

        if (!isClaimant && !isRespondent) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé',
            });
        }

        // Vérifier que le litige est résolu
        if (dispute.status !== 'resolved') {
            return res.status(400).json({
                success: false,
                message: 'Seuls les litiges résolus peuvent faire l\'objet d\'un appel',
            });
        }

        // Vérifier que la partie peut faire appel (pas déjà gagné)
        const favoredClaimant = ['favor_claimant', 'full_refund'].includes(dispute.resolution.decision);
        if ((isClaimant && favoredClaimant) || (isRespondent && !favoredClaimant)) {
            return res.status(400).json({
                success: false,
                message: 'Vous ne pouvez pas faire appel d\'une décision en votre faveur',
            });
        }

        // Vérifier le délai d'appel
        if (dispute.deadlines?.appealDeadline && new Date() > dispute.deadlines.appealDeadline) {
            return res.status(400).json({
                success: false,
                message: 'Le délai d\'appel est dépassé',
            });
        }

        // Vérifier si pas déjà en appel
        if (dispute.appeal?.isAppealed) {
            return res.status(400).json({
                success: false,
                message: 'Un appel a déjà été soumis pour ce litige',
            });
        }

        // Enregistrer l'appel
        dispute.appeal = {
            isAppealed: true,
            appealedBy: req.user.id,
            appealReason: reason,
            appealedAt: new Date(),
        };

        dispute.status = 'appealed';
        dispute.addHistory('appealed', 'Appel soumis', req.user.id);
        await dispute.save();

        // Notifier tous les admins
        await notifyAllAdmins(
            'Appel de litige',
            `Un appel a été soumis pour le litige #${dispute._id}`,
            'admin_alert',
            { disputeId: dispute._id.toString() }
        );

        res.json({
            success: true,
            message: 'Appel enregistré avec succès',
        });
    } catch (error) {
        console.error('Error appealing dispute:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// ============== ADMIN FUNCTIONS ==============

// @desc    Obtenir tous les litiges (admin)
// @route   GET /api/disputes/admin/all
// @access  Private (admin only)
exports.getAllDisputes = async (req, res) => {
    try {
        const { status, type, priority, page = 1, limit = 20, sort = '-createdAt' } = req.query;

        const query = {};
        if (status) query.status = status;
        if (type) query.type = type;
        if (priority) query.priority = priority;

        const disputes = await Dispute.find(query)
            .populate('reservation', 'departureTime totalPrice status')
            .populate('claimant.user', 'firstName lastName email')
            .populate('respondent.user', 'firstName lastName email')
            .sort(sort)
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        const total = await Dispute.countDocuments(query);
        const stats = await Dispute.getStats();

        res.json({
            success: true,
            disputes,
            stats,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit),
            },
        });
    } catch (error) {
        console.error('Error getting all disputes:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Résoudre un litige (admin)
// @route   POST /api/disputes/:id/resolve
// @access  Private (admin only)
exports.resolveDispute = async (req, res) => {
    try {
        const {
            decision,
            refundAmount,
            workerPenalty,
            clientPenalty,
            notes,
        } = req.body;

        if (!decision) {
            return res.status(400).json({
                success: false,
                message: 'La décision est requise',
            });
        }

        const dispute = await Dispute.findById(req.params.id)
            .populate('reservation')
            .populate('claimant.user')
            .populate('respondent.user');

        if (!dispute) {
            return res.status(404).json({
                success: false,
                message: 'Litige non trouvé',
            });
        }

        if (['resolved', 'closed'].includes(dispute.status)) {
            return res.status(400).json({
                success: false,
                message: 'Ce litige est déjà fermé',
            });
        }

        // Enregistrer la résolution
        dispute.resolution = {
            decision,
            refundAmount: refundAmount || 0,
            workerPenalty: workerPenalty || 'none',
            clientPenalty: clientPenalty || 'none',
            notes,
            resolvedBy: req.user.id,
            resolvedAt: new Date(),
        };

        dispute.status = 'resolved';
        dispute.deadlines.appealDeadline = new Date(Date.now() + DEADLINES.appeal * 60 * 60 * 1000);

        // Traiter le remboursement si nécessaire
        if (refundAmount > 0 && dispute.reservation) {
            const refundResult = await processRefund(
                dispute.reservation,
                refundAmount,
                `Litige résolu: ${decision}`
            );

            if (refundResult.success) {
                dispute.resolution.refundProcessed = true;
                dispute.resolution.refundProcessedAt = new Date();
                dispute.resolution.stripeRefundId = refundResult.refundId;
            }
        }

        // Appliquer les pénalités
        if (workerPenalty && workerPenalty !== 'none') {
            const workerId = dispute.respondent.role === 'worker'
                ? dispute.respondent.user._id
                : dispute.claimant.user._id;
            await applyPenalty(workerId, workerPenalty, `Litige #${dispute._id}: ${notes || decision}`, req.user.id);
        }

        if (clientPenalty && clientPenalty !== 'none') {
            const clientId = dispute.claimant.role === 'client'
                ? dispute.claimant.user._id
                : dispute.respondent.user._id;
            await applyPenalty(clientId, clientPenalty, `Litige #${dispute._id}: ${notes || decision}`, req.user.id);
        }

        // Mettre à jour les stats des utilisateurs
        const favoredClaimant = ['favor_claimant', 'full_refund'].includes(decision);

        if (dispute.claimant.role === 'client') {
            await User.findByIdAndUpdate(dispute.claimant.user._id, {
                $inc: {
                    [`clientProfile.disputes${favoredClaimant ? 'Won' : 'Lost'}`]: 1,
                },
            });
        } else {
            await User.findByIdAndUpdate(dispute.claimant.user._id, {
                $inc: {
                    [`workerProfile.disputes${favoredClaimant ? 'Won' : 'Lost'}`]: 1,
                },
            });
        }

        if (dispute.respondent.role === 'worker') {
            await User.findByIdAndUpdate(dispute.respondent.user._id, {
                $inc: {
                    [`workerProfile.disputes${!favoredClaimant ? 'Won' : 'Lost'}`]: 1,
                },
            });

            // Si no-show confirmé, mettre à jour le statut
            if (dispute.type === 'no_show' && favoredClaimant) {
                await User.findOneAndUpdate(
                    {
                        _id: dispute.respondent.user._id,
                        'workerProfile.noShowHistory.disputeId': dispute._id,
                    },
                    {
                        $set: {
                            'workerProfile.noShowHistory.$.resolved': true,
                            'workerProfile.noShowHistory.$.resolution': 'confirmed',
                        },
                    }
                );
            }
        } else {
            await User.findByIdAndUpdate(dispute.respondent.user._id, {
                $inc: {
                    [`clientProfile.disputes${!favoredClaimant ? 'Won' : 'Lost'}`]: 1,
                },
            });
        }

        // Mettre à jour la réservation
        if (dispute.reservation) {
            await Reservation.findByIdAndUpdate(dispute.reservation._id, {
                'dispute.disputeStatus': 'resolved',
                'dispute.disputeResolvedAt': new Date(),
                'noShow.confirmed': dispute.type === 'no_show' && favoredClaimant,
                'noShow.confirmedAt': dispute.type === 'no_show' && favoredClaimant ? new Date() : null,
            });
        }

        dispute.addHistory('resolved', `Résolu: ${decision}`, req.user.id);
        await dispute.save();

        // Générer les messages de notification personnalisés
        const claimantNotification = generateClaimantNotification(decision, refundAmount, dispute.type);
        const respondentNotification = generateRespondentNotification(decision, workerPenalty, dispute.type, dispute.claimant.role);

        // Notifier le plaignant
        await sendNotification(
            dispute.claimant.user._id,
            claimantNotification.title,
            claimantNotification.message,
            'dispute',
            { disputeId: dispute._id, decision, refundAmount }
        );

        // Notifier le défenseur
        await sendNotification(
            dispute.respondent.user._id,
            respondentNotification.title,
            respondentNotification.message,
            'dispute',
            { disputeId: dispute._id, decision }
        );

        res.json({
            success: true,
            message: 'Litige résolu avec succès',
            dispute,
        });
    } catch (error) {
        console.error('Error resolving dispute:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Ajouter une note admin
// @route   POST /api/disputes/:id/admin-note
// @access  Private (admin only)
exports.addAdminNote = async (req, res) => {
    try {
        const { note } = req.body;

        if (!note) {
            return res.status(400).json({
                success: false,
                message: 'La note est requise',
            });
        }

        const dispute = await Dispute.findById(req.params.id);

        if (!dispute) {
            return res.status(404).json({
                success: false,
                message: 'Litige non trouvé',
            });
        }

        dispute.addAdminNote(note, req.user.id);
        await dispute.save();

        res.json({
            success: true,
            message: 'Note ajoutée avec succès',
        });
    } catch (error) {
        console.error('Error adding admin note:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Résoudre un appel (admin)
// @route   POST /api/disputes/:id/resolve-appeal
// @access  Private (admin only)
exports.resolveAppeal = async (req, res) => {
    try {
        const { decision, notes, newRefundAmount, newWorkerPenalty, newClientPenalty } = req.body;

        const dispute = await Dispute.findById(req.params.id);

        if (!dispute) {
            return res.status(404).json({
                success: false,
                message: 'Litige non trouvé',
            });
        }

        if (dispute.status !== 'appealed') {
            return res.status(400).json({
                success: false,
                message: 'Ce litige n\'est pas en appel',
            });
        }

        // Enregistrer la résolution de l'appel
        dispute.appeal.appealResolution = {
            decision,
            notes,
            resolvedBy: req.user.id,
            resolvedAt: new Date(),
        };

        // Si l'appel est accepté, modifier la résolution originale
        if (decision === 'upheld') {
            // Annuler la décision originale
            dispute.resolution.decision = 'appeal_overturned';

            // Traiter les nouvelles pénalités/remboursements si spécifiés
            if (newRefundAmount !== undefined) {
                const reservation = await Reservation.findById(dispute.reservation);
                if (reservation && newRefundAmount > 0) {
                    await processRefund(reservation, newRefundAmount, 'Appel accepté');
                }
            }
        }

        dispute.status = 'resolved';
        dispute.addHistory('appeal_resolved', `Appel ${decision === 'upheld' ? 'accepté' : 'rejeté'}`, req.user.id);
        await dispute.save();

        // Notifier les parties
        await sendNotification(
            dispute.appeal.appealedBy,
            'Résultat de l\'appel',
            `Votre appel a été ${decision === 'upheld' ? 'accepté' : 'rejeté'}. ${notes || ''}`,
            'dispute',
            { disputeId: dispute._id }
        );

        res.json({
            success: true,
            message: 'Appel traité avec succès',
            dispute,
        });
    } catch (error) {
        console.error('Error resolving appeal:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Obtenir les statistiques des litiges (admin)
// @route   GET /api/disputes/admin/stats
// @access  Private (admin only)
exports.getDisputeStats = async (req, res) => {
    try {
        const stats = await Dispute.getStats();

        // Stats supplémentaires
        const avgResolutionTime = await Dispute.aggregate([
            { $match: { status: 'resolved', 'resolution.resolvedAt': { $exists: true } } },
            {
                $project: {
                    resolutionTime: {
                        $subtract: ['$resolution.resolvedAt', '$createdAt'],
                    },
                },
            },
            {
                $group: {
                    _id: null,
                    avgTime: { $avg: '$resolutionTime' },
                },
            },
        ]);

        const pendingCount = await Dispute.countDocuments({
            status: { $in: ['open', 'under_review', 'pending_response'] },
        });

        const overdueCount = await Dispute.countDocuments({
            status: { $nin: ['resolved', 'closed'] },
            'deadlines.resolutionDeadline': { $lt: new Date() },
        });

        res.json({
            success: true,
            stats: {
                ...stats,
                pendingCount,
                overdueCount,
                avgResolutionTimeHours: avgResolutionTime[0]
                    ? Math.round(avgResolutionTime[0].avgTime / (1000 * 60 * 60))
                    : 0,
            },
        });
    } catch (error) {
        console.error('Error getting dispute stats:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// ============== AUTO-RESOLUTION ==============

// @desc    Traiter la résolution automatique
// @access  Internal
exports.processAutoResolution = async (disputeId) => {
    try {
        const dispute = await Dispute.findById(disputeId)
            .populate('reservation')
            .populate('respondent.user');

        if (!dispute || !dispute.autoResolution?.eligible) {
            return { success: false, reason: 'Not eligible for auto-resolution' };
        }

        // No-show automatique
        if (dispute.type === 'no_show') {
            dispute.resolution = {
                decision: 'favor_claimant',
                refundAmount: dispute.reservation?.totalPrice || dispute.claimedAmount,
                workerPenalty: determinePenalty('noShow', dispute.respondent.user?.workerProfile?.noShowCount || 1),
                notes: `Résolution automatique: ${dispute.autoResolution.reason}`,
                resolvedAt: new Date(),
            };

            dispute.status = 'resolved';
            dispute.autoResolution.processedAt = new Date();

            // Traiter le remboursement
            if (dispute.reservation && dispute.resolution.refundAmount > 0) {
                const refundResult = await processRefund(
                    dispute.reservation,
                    dispute.resolution.refundAmount,
                    'No-show confirmé automatiquement'
                );

                if (refundResult.success) {
                    dispute.resolution.refundProcessed = true;
                    dispute.resolution.refundProcessedAt = new Date();
                    dispute.resolution.stripeRefundId = refundResult.refundId;
                }
            }

            // Appliquer la pénalité au worker
            await applyPenalty(
                dispute.respondent.user._id,
                dispute.resolution.workerPenalty,
                'No-show confirmé automatiquement'
            );

            dispute.addHistory('resolved', 'Résolution automatique - No-show confirmé', null);
            await dispute.save();

            // Notifier les parties
            await sendNotification(
                dispute.claimant.user,
                'Litige résolu automatiquement',
                `Votre signalement no-show a été confirmé. Remboursement: ${dispute.resolution.refundAmount}$`,
                'dispute',
                { disputeId: dispute._id }
            );

            await sendNotification(
                dispute.respondent.user._id,
                'No-show confirmé',
                'Le no-show a été confirmé automatiquement. Des pénalités ont été appliquées.',
                'dispute',
                { disputeId: dispute._id }
            );

            return { success: true, resolution: dispute.resolution };
        }

        return { success: false, reason: 'Auto-resolution not implemented for this type' };
    } catch (error) {
        console.error('Error in auto-resolution:', error);
        return { success: false, error: error.message };
    }
};

// ============== QUALITY VERIFICATION ==============

// @desc    Vérifier la qualité d'un travail complété
// @route   POST /api/disputes/verify-quality/:reservationId
// @access  Private (admin or system)
exports.verifyWorkQuality = async (req, res) => {
    try {
        const { reservationId } = req.params;

        const reservation = await Reservation.findById(reservationId);

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        if (reservation.status !== 'completed') {
            return res.status(400).json({
                success: false,
                message: 'Seules les réservations complétées peuvent être vérifiées',
            });
        }

        const flags = [];
        let qualityScore = 100;

        // 1. Vérifier le temps de travail
        if (reservation.startedAt && reservation.completedAt) {
            const actualDuration = (reservation.completedAt - reservation.startedAt) / (1000 * 60); // en minutes
            const expectedDuration = 15; // Minimum attendu en minutes

            reservation.qualityVerification.timeVerification = {
                expectedDuration,
                actualDuration: Math.round(actualDuration),
            };

            if (actualDuration < 5) {
                flags.push('Durée de travail suspicieusement courte');
                reservation.qualityVerification.timeVerification.isSuspicious = true;
                reservation.qualityVerification.timeVerification.suspiciousReason = 'Moins de 5 minutes';
                qualityScore -= 30;
            } else if (actualDuration < 10) {
                flags.push('Durée de travail très courte');
                qualityScore -= 15;
            }
        }

        // 2. Vérifier les photos
        const beforePhotos = reservation.photos?.filter(p => p.type === 'before').length || 0;
        const afterPhotos = reservation.photos?.filter(p => p.type === 'after').length || 0;

        reservation.qualityVerification.photoVerification = {
            beforePhotoCount: beforePhotos,
            afterPhotoCount: afterPhotos,
            photosValidated: beforePhotos >= 1 && afterPhotos >= 1,
        };

        if (afterPhotos === 0) {
            flags.push('Aucune photo après travail');
            qualityScore -= 20;
        }

        // 3. Vérifier la distance GPS
        if (reservation.qualityVerification?.gpsData?.length > 0) {
            const completionGps = reservation.qualityVerification.gpsData.find(
                g => g.event === 'workCompleted'
            );

            if (completionGps && reservation.location?.coordinates) {
                const distance = calculateDistance(
                    completionGps.coordinates[1],
                    completionGps.coordinates[0],
                    reservation.location.coordinates[1],
                    reservation.location.coordinates[0]
                );

                reservation.qualityVerification.distanceFromJobSite = Math.round(distance);

                if (distance > 500) { // Plus de 500m du site
                    flags.push('Travail terminé loin du site');
                    qualityScore -= 25;
                } else if (distance > 200) {
                    flags.push('Distance significative du site');
                    qualityScore -= 10;
                }

                reservation.qualityVerification.gpsVerified = distance <= 200;
            }
        }

        // 4. Vérifier la ponctualité
        if (reservation.workerArrivedAt && reservation.estimatedArrivalTime) {
            const delay = (reservation.workerArrivedAt - reservation.estimatedArrivalTime) / (1000 * 60);
            if (delay > 0) {
                reservation.punctuality = {
                    ...reservation.punctuality,
                    delayMinutes: Math.round(delay),
                    isLate: delay > 15,
                };

                if (delay > 30) {
                    flags.push('Retard significatif (>30 min)');
                    qualityScore -= 15;
                } else if (delay > 15) {
                    flags.push('Retard modéré (>15 min)');
                    qualityScore -= 5;
                }
            }
        }

        // Mettre à jour le score et les flags
        reservation.qualityVerification.qualityScore = Math.max(0, qualityScore);

        if (flags.length > 0) {
            reservation.flags = {
                suspiciousActivity: qualityScore < 50,
                requiresReview: qualityScore < 70,
                flagReasons: flags,
                flaggedAt: new Date(),
            };
        }

        await reservation.save();

        // Si score très bas, créer automatiquement un flag pour review
        if (qualityScore < 50) {
            // Mettre à jour les stats du worker
            await User.findByIdAndUpdate(reservation.workerId, {
                $inc: { 'workerProfile.qualityComplaints': 1 },
            });
        }

        res.json({
            success: true,
            verification: {
                qualityScore,
                flags,
                timeVerification: reservation.qualityVerification.timeVerification,
                photoVerification: reservation.qualityVerification.photoVerification,
                gpsVerified: reservation.qualityVerification.gpsVerified,
                distanceFromJobSite: reservation.qualityVerification.distanceFromJobSite,
            },
        });
    } catch (error) {
        console.error('Error verifying work quality:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// @desc    Client confirme que le travail est satisfaisant
// @route   POST /api/disputes/confirm-satisfaction/:reservationId
// @access  Private (client only)
exports.confirmSatisfaction = async (req, res) => {
    try {
        const { reservationId } = req.params;
        const { satisfied, comments } = req.body;

        const reservation = await Reservation.findById(reservationId);

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        if (reservation.userId.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé',
            });
        }

        if (reservation.status !== 'completed') {
            return res.status(400).json({
                success: false,
                message: 'La réservation doit être complétée',
            });
        }

        reservation.qualityVerification.clientConfirmed = true;
        reservation.qualityVerification.clientConfirmedAt = new Date();
        reservation.qualityVerification.clientSatisfied = satisfied;

        if (!satisfied && comments) {
            reservation.qualityVerification.validationNotes = comments;
        }

        await reservation.save();

        // Si pas satisfait, proposer d'ouvrir un litige
        res.json({
            success: true,
            message: satisfied
                ? 'Merci pour votre confirmation!'
                : 'Votre insatisfaction a été enregistrée. Souhaitez-vous ouvrir un litige?',
            canOpenDispute: !satisfied,
        });
    } catch (error) {
        console.error('Error confirming satisfaction:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

// ============== STRIPE CHARGEBACK HANDLING ==============

// @desc    Gérer un webhook Stripe pour chargeback
// @access  Internal (called by Stripe webhook)
exports.handleStripeDispute = async (stripeDispute) => {
    try {
        const { id, payment_intent, amount, reason, status } = stripeDispute;

        // Trouver la réservation associée
        const reservation = await Reservation.findOne({ paymentIntentId: payment_intent });

        if (!reservation) {
            console.log('No reservation found for payment intent:', payment_intent);
            return { success: false, reason: 'Reservation not found' };
        }

        // Vérifier si un dispute existe déjà pour ce chargeback
        let dispute = await Dispute.findOne({ 'stripeDispute.disputeId': id });

        if (!dispute) {
            // Créer un nouveau litige
            dispute = await Dispute.create({
                type: 'payment_issue',
                reservation: reservation._id,
                claimant: {
                    user: reservation.userId,
                    role: 'client',
                },
                respondent: {
                    user: reservation.workerId || reservation.userId, // Si pas de worker, mettre le client
                    role: reservation.workerId ? 'worker' : 'client',
                },
                description: `Chargeback Stripe: ${reason}`,
                claimedAmount: amount / 100,
                priority: 'urgent',
                status: 'escalated',
                stripeDispute: {
                    disputeId: id,
                    status,
                    amount: amount / 100,
                    reason,
                    createdAt: new Date(),
                },
            });

            dispute.addHistory('created', `Chargeback Stripe reçu: ${reason}`, null);
        } else {
            // Mettre à jour le statut existant
            dispute.stripeDispute.status = status;

            if (status === 'won') {
                dispute.resolution = {
                    decision: 'favor_respondent',
                    notes: 'Chargeback Stripe gagné par la plateforme',
                    resolvedAt: new Date(),
                };
                dispute.status = 'resolved';
                dispute.stripeDispute.resolvedAt = new Date();
            } else if (status === 'lost') {
                dispute.resolution = {
                    decision: 'favor_claimant',
                    refundAmount: amount / 100,
                    notes: 'Chargeback Stripe perdu',
                    resolvedAt: new Date(),
                };
                dispute.status = 'resolved';
                dispute.stripeDispute.resolvedAt = new Date();

                // Mettre à jour le client
                await User.findByIdAndUpdate(reservation.userId, {
                    $inc: { 'clientProfile.chargebackCount': 1 },
                    $push: {
                        'clientProfile.chargebackHistory': {
                            stripeDisputeId: id,
                            amount: amount / 100,
                            status,
                            reason,
                            createdAt: new Date(),
                            resolvedAt: new Date(),
                        },
                    },
                });
            }

            dispute.addHistory('status_changed', `Statut Stripe: ${status}`, null);
        }

        await dispute.save();

        return { success: true, disputeId: dispute._id };
    } catch (error) {
        console.error('Error handling Stripe dispute:', error);
        return { success: false, error: error.message };
    }
};

// @desc    Obtenir les types de litiges disponibles
// @route   GET /api/disputes/types
// @access  Public
exports.getDisputeTypes = async (req, res) => {
    try {
        const types = [
            { value: 'no_show', label: 'Déneigeur non venu', description: 'Le déneigeur n\'est jamais arrivé' },
            { value: 'incomplete_work', label: 'Travail incomplet', description: 'Le travail n\'a pas été terminé' },
            { value: 'quality_issue', label: 'Qualité insuffisante', description: 'Le travail n\'est pas satisfaisant' },
            { value: 'late_arrival', label: 'Retard important', description: 'Le déneigeur est arrivé très en retard' },
            { value: 'damage', label: 'Dommage causé', description: 'Des dommages ont été causés à la propriété' },
            { value: 'wrong_location', label: 'Mauvais emplacement', description: 'Le travail a été fait au mauvais endroit' },
            { value: 'overcharge', label: 'Surfacturation', description: 'Le montant facturé est incorrect' },
            { value: 'unprofessional', label: 'Comportement inapproprié', description: 'Comportement non professionnel' },
            { value: 'other', label: 'Autre', description: 'Autre type de problème' },
        ];

        res.json({
            success: true,
            types,
        });
    } catch (error) {
        console.error('Error getting dispute types:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};
