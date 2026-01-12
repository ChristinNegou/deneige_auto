const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { protect, authorize } = require('../middleware/auth');
const User = require('../models/User');
const Reservation = require('../models/Reservation');
const Notification = require('../models/Notification');
const SupportRequest = require('../models/SupportRequest');
const Transaction = require('../models/Transaction');
const { runFullCleanup, getDatabaseStats, RETENTION_CONFIG } = require('../services/databaseCleanupService');

// Middleware pour vérifier le rôle admin
const adminOnly = authorize('admin');

// ============================================================================
// SECURITY UTILITIES
// ============================================================================

// Whitelist des champs de tri autorisés pour éviter NoSQL injection
const ALLOWED_USER_SORT_FIELDS = ['createdAt', 'firstName', 'lastName', 'email', 'role', 'isActive'];
const ALLOWED_RESERVATION_SORT_FIELDS = ['createdAt', 'departureTime', 'status', 'totalPrice', 'paymentStatus'];

// Whitelist des champs modifiables pour les utilisateurs (évite Object.assign non contrôlé)
const ALLOWED_USER_UPDATE_FIELDS = ['firstName', 'lastName', 'email', 'phoneNumber', 'photoUrl'];

// Fonction pour échapper les caractères spéciaux regex (évite ReDoS)
const escapeRegex = (string) => {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

// Fonction pour valider et sécuriser le champ de tri
const validateSortField = (sortBy, allowedFields) => {
    return allowedFields.includes(sortBy) ? sortBy : 'createdAt';
};

// Message d'erreur générique pour la production
const getErrorMessage = (error) => {
    if (process.env.NODE_ENV === 'production') {
        return 'Une erreur est survenue';
    }
    return error.message;
};

// ============================================================================
// DASHBOARD STATS
// ============================================================================

/**
 * @route   GET /api/admin/dashboard
 * @desc    Obtenir les statistiques du dashboard
 * @access  Private (Admin)
 */
router.get('/dashboard', protect, adminOnly, async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const thisMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        const lastMonth = new Date(today.getFullYear(), today.getMonth() - 1, 1);

        // Stats globales
        const [
            totalUsers,
            totalClients,
            totalWorkers,
            activeWorkers,
            totalReservations,
            completedReservations,
            cancelledReservations,
            todayReservations,
            monthlyReservations,
            pendingReservations,
            // Support stats
            totalSupportRequests,
            pendingSupportRequests,
            inProgressSupportRequests,
            resolvedSupportRequests,
            closedSupportRequests,
            todaySupportRequests,
        ] = await Promise.all([
            User.countDocuments(),
            User.countDocuments({ role: 'client' }),
            User.countDocuments({ role: 'snowWorker' }),
            User.countDocuments({ role: 'snowWorker', 'workerProfile.isAvailable': true }),
            Reservation.countDocuments(),
            Reservation.countDocuments({ status: 'completed' }),
            Reservation.countDocuments({ status: 'cancelled' }),
            Reservation.countDocuments({ createdAt: { $gte: today } }),
            Reservation.countDocuments({ createdAt: { $gte: thisMonth } }),
            Reservation.countDocuments({ status: 'pending' }),
            // Support stats
            SupportRequest.countDocuments(),
            SupportRequest.countDocuments({ status: 'pending' }),
            SupportRequest.countDocuments({ status: 'in_progress' }),
            SupportRequest.countDocuments({ status: 'resolved' }),
            SupportRequest.countDocuments({ status: 'closed' }),
            SupportRequest.countDocuments({ createdAt: { $gte: today } }),
        ]);

        // Revenus
        const revenueStats = await Reservation.aggregate([
            { $match: { status: 'completed', paymentStatus: 'paid' } },
            {
                $group: {
                    _id: null,
                    totalRevenue: { $sum: '$totalPrice' },
                    totalPlatformFees: { $sum: '$payout.platformFee' },
                    totalWorkerPayouts: { $sum: '$payout.workerAmount' },
                    totalTips: { $sum: '$tipAmount' },
                    totalStripeFees: { $sum: { $ifNull: ['$payout.stripeFee', 0] } },
                    reservationCount: { $sum: 1 },
                },
            },
        ]);

        const monthlyRevenueStats = await Reservation.aggregate([
            {
                $match: {
                    status: 'completed',
                    paymentStatus: 'paid',
                    createdAt: { $gte: thisMonth },
                },
            },
            {
                $group: {
                    _id: null,
                    revenue: { $sum: '$totalPrice' },
                    platformFees: { $sum: '$payout.platformFee' },
                    stripeFees: { $sum: { $ifNull: ['$payout.stripeFee', 0] } },
                    tips: { $sum: '$tipAmount' },
                },
            },
        ]);

        // Réservations par jour (7 derniers jours)
        const sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const dailyReservations = await Reservation.aggregate([
            { $match: { createdAt: { $gte: sevenDaysAgo } } },
            {
                $group: {
                    _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
                    count: { $sum: 1 },
                    revenue: {
                        $sum: {
                            $cond: [{ $eq: ['$status', 'completed'] }, '$totalPrice', 0],
                        },
                    },
                },
            },
            { $sort: { _id: 1 } },
        ]);

        // Top 5 déneigeurs
        const topWorkers = await User.find({ role: 'snowWorker' })
            .select('firstName lastName workerProfile.totalJobsCompleted workerProfile.totalEarnings workerProfile.averageRating')
            .sort({ 'workerProfile.totalJobsCompleted': -1 })
            .limit(5);

        res.json({
            success: true,
            stats: {
                users: {
                    total: totalUsers,
                    clients: totalClients,
                    workers: totalWorkers,
                    activeWorkers,
                },
                reservations: {
                    total: totalReservations,
                    completed: completedReservations,
                    cancelled: cancelledReservations,
                    pending: pendingReservations,
                    today: todayReservations,
                    thisMonth: monthlyReservations,
                    completionRate: totalReservations > 0
                        ? ((completedReservations / totalReservations) * 100).toFixed(1)
                        : 0,
                },
                revenue: {
                    total: revenueStats[0]?.totalRevenue || 0,
                    platformFeesGross: revenueStats[0]?.totalPlatformFees || 0,
                    stripeFees: revenueStats[0]?.totalStripeFees || 0,
                    platformFeesNet: (revenueStats[0]?.totalPlatformFees || 0) - (revenueStats[0]?.totalStripeFees || 0),
                    workerPayouts: revenueStats[0]?.totalWorkerPayouts || 0,
                    tips: revenueStats[0]?.totalTips || 0,
                    reservationCount: revenueStats[0]?.reservationCount || 0,
                    thisMonth: monthlyRevenueStats[0]?.revenue || 0,
                    monthlyPlatformFeesGross: monthlyRevenueStats[0]?.platformFees || 0,
                    monthlyStripeFees: monthlyRevenueStats[0]?.stripeFees || 0,
                    monthlyPlatformFeesNet: (monthlyRevenueStats[0]?.platformFees || 0) - (monthlyRevenueStats[0]?.stripeFees || 0),
                    monthlyTips: monthlyRevenueStats[0]?.tips || 0,
                },
                charts: {
                    dailyReservations,
                },
                topWorkers: topWorkers.map(w => ({
                    id: w._id,
                    name: `${w.firstName} ${w.lastName}`,
                    jobsCompleted: w.workerProfile?.totalJobsCompleted || 0,
                    totalEarnings: w.workerProfile?.totalEarnings || 0,
                    rating: w.workerProfile?.averageRating || 0,
                })),
                support: {
                    total: totalSupportRequests,
                    pending: pendingSupportRequests,
                    inProgress: inProgressSupportRequests,
                    resolved: resolvedSupportRequests,
                    closed: closedSupportRequests,
                    todayNew: todaySupportRequests,
                    avgResponseTimeHours: 0, // TODO: calculer si besoin
                },
            },
        });
    } catch (error) {
        console.error('Erreur dashboard admin:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

// ============================================================================
// USER MANAGEMENT
// ============================================================================

/**
 * @route   GET /api/admin/users
 * @desc    Lister tous les utilisateurs avec pagination
 * @access  Private (Admin)
 */
router.get('/users', protect, adminOnly, async (req, res) => {
    try {
        const { page = 1, limit = 20, role, search, sortBy = 'createdAt', order = 'desc' } = req.query;

        const query = {};
        if (role && ['client', 'snowWorker', 'admin'].includes(role)) {
            query.role = role;
        }
        if (search) {
            // Échapper les caractères spéciaux pour éviter ReDoS
            const safeSearch = escapeRegex(search);
            query.$or = [
                { firstName: { $regex: safeSearch, $options: 'i' } },
                { lastName: { $regex: safeSearch, $options: 'i' } },
                { email: { $regex: safeSearch, $options: 'i' } },
                { phoneNumber: { $regex: safeSearch, $options: 'i' } },
            ];
        }

        const sortOrder = order === 'desc' ? -1 : 1;
        const skip = (parseInt(page) - 1) * parseInt(limit);
        // Valider le champ de tri contre la whitelist
        const safeSortBy = validateSortField(sortBy, ALLOWED_USER_SORT_FIELDS);

        const [users, total] = await Promise.all([
            User.find(query)
                .select('-password -resetPasswordToken -resetPasswordExpire')
                .sort({ [safeSortBy]: sortOrder })
                .skip(skip)
                .limit(parseInt(limit)),
            User.countDocuments(query),
        ]);

        res.json({
            success: true,
            users,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        console.error('Erreur liste utilisateurs:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   GET /api/admin/users/:id
 * @desc    Détails d'un utilisateur
 * @access  Private (Admin)
 */
router.get('/users/:id', protect, adminOnly, async (req, res) => {
    try {
        const user = await User.findById(req.params.id)
            .select('-password -resetPasswordToken -resetPasswordExpire');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Utilisateur non trouvé',
            });
        }

        // Stats supplémentaires si c'est un client
        let clientStats = null;
        if (user.role === 'client') {
            const reservations = await Reservation.find({ userId: user._id });
            clientStats = {
                totalReservations: reservations.length,
                completedReservations: reservations.filter(r => r.status === 'completed').length,
                cancelledReservations: reservations.filter(r => r.status === 'cancelled').length,
                totalSpent: reservations
                    .filter(r => r.paymentStatus === 'paid')
                    .reduce((sum, r) => sum + r.totalPrice, 0),
            };
        }

        // Stats supplémentaires si c'est un worker
        let workerStats = null;
        if (user.role === 'snowWorker') {
            const jobs = await Reservation.find({ workerId: user._id });
            workerStats = {
                totalJobs: jobs.length,
                completedJobs: jobs.filter(r => r.status === 'completed').length,
                cancelledJobs: jobs.filter(r => r.status === 'cancelled' && r.cancelledBy === 'worker').length,
                averageRating: user.workerProfile?.averageRating || 0,
                totalEarnings: user.workerProfile?.totalEarnings || 0,
            };
        }

        res.json({
            success: true,
            user,
            clientStats,
            workerStats,
        });
    } catch (error) {
        console.error('Erreur détails utilisateur:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   PATCH /api/admin/users/:id
 * @desc    Modifier un utilisateur
 * @access  Private (Admin)
 */
router.patch('/users/:id', protect, adminOnly, async (req, res) => {
    try {
        const { isActive, role, ...updateData } = req.body;

        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Utilisateur non trouvé',
            });
        }

        // Mettre à jour les champs autorisés
        if (typeof isActive === 'boolean') user.isActive = isActive;
        if (role && ['client', 'snowWorker', 'admin'].includes(role)) user.role = role;

        // Seulement mettre à jour les champs dans la whitelist (évite injection de champs sensibles)
        for (const field of ALLOWED_USER_UPDATE_FIELDS) {
            if (updateData[field] !== undefined) {
                user[field] = updateData[field];
            }
        }
        await user.save();

        res.json({
            success: true,
            message: 'Utilisateur mis à jour',
            user,
        });
    } catch (error) {
        console.error('Erreur modification utilisateur:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   POST /api/admin/users/:id/suspend
 * @desc    Suspendre un utilisateur
 * @access  Private (Admin)
 */
router.post('/users/:id/suspend', protect, adminOnly, async (req, res) => {
    try {
        const { reason, days = 7 } = req.body;

        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Utilisateur non trouvé',
            });
        }

        const suspendedUntil = new Date();
        suspendedUntil.setDate(suspendedUntil.getDate() + parseInt(days));

        // Set suspension at root level (for all users)
        user.isSuspended = true;
        user.suspendedUntil = suspendedUntil;
        user.suspensionReason = reason || 'Suspendu par un administrateur';
        user.isActive = false;

        // Also set in workerProfile if snowWorker (for backwards compatibility)
        if (user.role === 'snowWorker' && user.workerProfile) {
            user.workerProfile.isSuspended = true;
            user.workerProfile.suspendedUntil = suspendedUntil;
            user.workerProfile.suspensionReason = reason || 'Suspendu par un administrateur';
            user.workerProfile.isAvailable = false; // Disable availability
        }
        await user.save();

        // Notifier l'utilisateur
        await Notification.create({
            userId: user._id,
            type: 'systemNotification',
            title: 'Compte suspendu',
            message: `Votre compte a été suspendu jusqu'au ${suspendedUntil.toLocaleDateString('fr-CA')}. Raison: ${reason || 'Non spécifiée'}`,
            priority: 'urgent',
        });

        res.json({
            success: true,
            message: `Utilisateur suspendu jusqu'au ${suspendedUntil.toLocaleDateString('fr-CA')}`,
            user,
        });
    } catch (error) {
        console.error('Erreur suspension utilisateur:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   POST /api/admin/users/:id/unsuspend
 * @desc    Lever la suspension d'un utilisateur
 * @access  Private (Admin)
 */
router.post('/users/:id/unsuspend', protect, adminOnly, async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Utilisateur non trouvé',
            });
        }

        // Clear suspension at root level (for all users)
        user.isSuspended = false;
        user.suspendedUntil = null;
        user.suspensionReason = null;
        user.isActive = true;

        // Also clear in workerProfile if snowWorker (for backwards compatibility)
        if (user.role === 'snowWorker' && user.workerProfile) {
            user.workerProfile.isSuspended = false;
            user.workerProfile.suspendedUntil = null;
            user.workerProfile.suspensionReason = null;
        }
        await user.save();

        // Notifier l'utilisateur
        await Notification.create({
            userId: user._id,
            type: 'systemNotification',
            title: 'Suspension levée',
            message: 'Votre compte a été réactivé. Vous pouvez reprendre vos activités.',
            priority: 'high',
        });

        res.json({
            success: true,
            message: 'Suspension levée',
            user,
        });
    } catch (error) {
        console.error('Erreur lever suspension:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

// ============================================================================
// RESERVATION MANAGEMENT
// ============================================================================

/**
 * @route   GET /api/admin/reservations
 * @desc    Lister toutes les réservations avec pagination
 * @access  Private (Admin)
 */
router.get('/reservations', protect, adminOnly, async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            status,
            startDate,
            endDate,
            sortBy = 'createdAt',
            order = 'desc'
        } = req.query;

        const query = {};
        // Valider le status contre les valeurs autorisées
        const validStatuses = ['pending', 'assigned', 'inProgress', 'completed', 'cancelled'];
        if (status && validStatuses.includes(status)) {
            query.status = status;
        }
        if (startDate || endDate) {
            query.departureTime = {};
            if (startDate) query.departureTime.$gte = new Date(startDate);
            if (endDate) query.departureTime.$lte = new Date(endDate);
        }

        const sortOrder = order === 'desc' ? -1 : 1;
        const skip = (parseInt(page) - 1) * parseInt(limit);
        // Valider le champ de tri contre la whitelist
        const safeSortBy = validateSortField(sortBy, ALLOWED_RESERVATION_SORT_FIELDS);

        const [reservations, total] = await Promise.all([
            Reservation.find(query)
                .populate('userId', 'firstName lastName email phoneNumber')
                .populate('workerId', 'firstName lastName phoneNumber')
                .populate('vehicle')
                .sort({ [safeSortBy]: sortOrder })
                .skip(skip)
                .limit(parseInt(limit)),
            Reservation.countDocuments(query),
        ]);

        res.json({
            success: true,
            reservations,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        console.error('Erreur liste réservations:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   GET /api/admin/reservations/:id
 * @desc    Détails d'une réservation
 * @access  Private (Admin)
 */
router.get('/reservations/:id', protect, adminOnly, async (req, res) => {
    try {
        const reservation = await Reservation.findById(req.params.id)
            .populate('userId', 'firstName lastName email phoneNumber')
            .populate('workerId', 'firstName lastName phoneNumber workerProfile')
            .populate('vehicle')
            .populate('parkingSpot');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        res.json({
            success: true,
            reservation,
        });
    } catch (error) {
        console.error('Erreur détails réservation:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   PATCH /api/admin/reservations/:id
 * @desc    Modifier une réservation (admin override)
 * @access  Private (Admin)
 */
router.patch('/reservations/:id', protect, adminOnly, async (req, res) => {
    try {
        // Whitelist des champs modifiables pour les réservations
        const allowedFields = ['status', 'workerNotes', 'adminNotes', 'priority'];
        const updateData = {};

        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                updateData[field] = req.body[field];
            }
        }

        const reservation = await Reservation.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true, runValidators: true }
        )
            .populate('userId', 'firstName lastName email')
            .populate('workerId', 'firstName lastName');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        res.json({
            success: true,
            message: 'Réservation mise à jour',
            reservation,
        });
    } catch (error) {
        console.error('Erreur modification réservation:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   POST /api/admin/reservations/:id/refund
 * @desc    Rembourser manuellement une réservation
 * @access  Private (Admin)
 */
router.post('/reservations/:id/refund', protect, adminOnly, async (req, res) => {
    try {
        const { amount, reason } = req.body;
        const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

        const reservation = await Reservation.findById(req.params.id);
        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        if (!reservation.paymentIntentId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun paiement Stripe associé',
            });
        }

        const refundAmount = amount || reservation.totalPrice;

        const refund = await stripe.refunds.create({
            payment_intent: reservation.paymentIntentId,
            amount: Math.round(refundAmount * 100),
            reason: 'requested_by_customer',
            metadata: {
                adminId: req.user.id,
                adminReason: reason || 'Admin refund',
            },
        });

        reservation.refundAmount = (reservation.refundAmount || 0) + refundAmount;
        reservation.refundedAt = new Date();
        reservation.paymentStatus = refundAmount >= reservation.totalPrice ? 'refunded' : 'partially_refunded';
        await reservation.save();

        res.json({
            success: true,
            message: `Remboursement de ${refundAmount.toFixed(2)}$ effectué`,
            refund: {
                id: refund.id,
                amount: refundAmount,
                status: refund.status,
            },
        });
    } catch (error) {
        console.error('Erreur remboursement:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

// ============================================================================
// WORKER MANAGEMENT
// ============================================================================

/**
 * @route   GET /api/admin/workers
 * @desc    Lister tous les déneigeurs
 * @access  Private (Admin)
 */
router.get('/workers', protect, adminOnly, async (req, res) => {
    try {
        const { available, suspended } = req.query;

        const query = { role: 'snowWorker' };
        if (available === 'true') query['workerProfile.isAvailable'] = true;
        if (available === 'false') query['workerProfile.isAvailable'] = false;
        if (suspended === 'true') query['workerProfile.isSuspended'] = true;
        if (suspended === 'false') query['workerProfile.isSuspended'] = { $ne: true };

        const workers = await User.find(query)
            .select('-password')
            .sort({ 'workerProfile.totalJobsCompleted': -1 });

        res.json({
            success: true,
            workers,
            count: workers.length,
        });
    } catch (error) {
        console.error('Erreur liste workers:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   GET /api/admin/workers/:id/jobs
 * @desc    Historique des jobs d'un déneigeur
 * @access  Private (Admin)
 */
router.get('/workers/:id/jobs', protect, adminOnly, async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const [jobs, total] = await Promise.all([
            Reservation.find({ workerId: req.params.id })
                .populate('userId', 'firstName lastName')
                .populate('vehicle')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Reservation.countDocuments({ workerId: req.params.id }),
        ]);

        res.json({
            success: true,
            jobs,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / parseInt(limit)),
            },
        });
    } catch (error) {
        console.error('Erreur historique jobs:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

// ============================================================================
// NOTIFICATIONS
// ============================================================================

/**
 * @route   POST /api/admin/notifications/broadcast
 * @desc    Envoyer une notification à tous les utilisateurs ou un groupe
 * @access  Private (Admin)
 */
router.post('/notifications/broadcast', protect, adminOnly, async (req, res) => {
    try {
        const { title, message, priority = 'normal', targetRole } = req.body;

        if (!title || !message) {
            return res.status(400).json({
                success: false,
                message: 'Titre et message requis',
            });
        }

        const query = targetRole ? { role: targetRole } : {};
        const users = await User.find(query).select('_id');

        const notifications = users.map(user => ({
            userId: user._id,
            type: 'systemNotification',
            title,
            message,
            priority,
        }));

        await Notification.insertMany(notifications);

        res.json({
            success: true,
            message: `Notification envoyée à ${users.length} utilisateurs`,
            count: users.length,
        });
    } catch (error) {
        console.error('Erreur broadcast notification:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   POST /api/admin/notifications/test
 * @desc    Envoyer une notification test à un utilisateur (avec FCM)
 * @access  Private (Admin)
 */
router.post('/notifications/test', protect, adminOnly, async (req, res) => {
    try {
        const { userId, email } = req.body;

        // Trouver l'utilisateur
        let user;
        if (userId) {
            user = await User.findById(userId);
        } else if (email) {
            user = await User.findOne({ email: email.toLowerCase() });
        } else {
            // Si aucun paramètre, envoyer à l'admin qui fait la requête
            user = await User.findById(req.user.id);
        }

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Utilisateur non trouvé',
            });
        }

        // Créer la notification (ceci enverra aussi le push FCM)
        const notification = await Notification.createNotification({
            userId: user._id,
            type: 'systemNotification',
            title: '🧪 Test Notification',
            message: `Ceci est un test de notification push envoyé à ${user.firstName} ${user.lastName}`,
            priority: 'high',
        });

        res.json({
            success: true,
            message: `Notification envoyée à ${user.email}`,
            notification: {
                id: notification._id,
                title: notification.title,
                message: notification.message,
            },
            fcmStatus: user.fcmToken ? 'Token présent - push envoyé' : 'Pas de token FCM - push non envoyé',
            user: {
                id: user._id,
                email: user.email,
                firstName: user.firstName,
                hasFcmToken: !!user.fcmToken,
            },
        });
    } catch (error) {
        console.error('Erreur test notification:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   GET /api/admin/notifications/fcm-status
 * @desc    Obtenir le statut FCM de tous les utilisateurs
 * @access  Private (Admin)
 */
router.get('/notifications/fcm-status', protect, adminOnly, async (req, res) => {
    try {
        const users = await User.find({}, 'email firstName lastName role fcmToken notificationSettings createdAt')
            .sort({ createdAt: -1 })
            .lean();

        const stats = {
            total: users.length,
            withFcmToken: 0,
            withoutFcmToken: 0,
            byRole: {},
        };

        const usersWithToken = [];
        const usersWithoutToken = [];

        users.forEach(user => {
            const hasToken = !!user.fcmToken;
            if (hasToken) {
                stats.withFcmToken++;
                usersWithToken.push({
                    id: user._id,
                    email: user.email,
                    name: `${user.firstName} ${user.lastName}`,
                    role: user.role,
                    tokenPreview: user.fcmToken.substring(0, 20) + '...',
                    pushEnabled: user.notificationSettings?.pushEnabled !== false,
                });
            } else {
                stats.withoutFcmToken++;
                usersWithoutToken.push({
                    id: user._id,
                    email: user.email,
                    name: `${user.firstName} ${user.lastName}`,
                    role: user.role,
                });
            }

            // Stats par rôle
            if (!stats.byRole[user.role]) {
                stats.byRole[user.role] = { total: 0, withToken: 0 };
            }
            stats.byRole[user.role].total++;
            if (hasToken) stats.byRole[user.role].withToken++;
        });

        res.json({
            success: true,
            stats,
            usersWithToken,
            usersWithoutToken,
        });
    } catch (error) {
        console.error('Erreur FCM status:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

// ============================================================================
// REPORTS
// ============================================================================

/**
 * @route   GET /api/admin/reports/revenue
 * @desc    Rapport de revenus par période
 * @access  Private (Admin)
 */
router.get('/reports/revenue', protect, adminOnly, async (req, res) => {
    try {
        const { period = 'month', startDate, endDate } = req.query;

        let groupBy;
        switch (period) {
            case 'day':
                groupBy = { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } };
                break;
            case 'week':
                groupBy = { $week: '$createdAt' };
                break;
            case 'month':
            default:
                groupBy = { $dateToString: { format: '%Y-%m', date: '$createdAt' } };
        }

        const match = { status: 'completed', paymentStatus: 'paid' };
        if (startDate) match.createdAt = { $gte: new Date(startDate) };
        if (endDate) {
            match.createdAt = match.createdAt || {};
            match.createdAt.$lte = new Date(endDate);
        }

        const report = await Reservation.aggregate([
            { $match: match },
            {
                $group: {
                    _id: groupBy,
                    totalRevenue: { $sum: '$totalPrice' },
                    platformFees: { $sum: '$payout.platformFee' },
                    workerPayouts: { $sum: '$payout.workerAmount' },
                    tips: { $sum: '$tipAmount' },
                    count: { $sum: 1 },
                },
            },
            { $sort: { _id: 1 } },
        ]);

        res.json({
            success: true,
            report,
            period,
        });
    } catch (error) {
        console.error('Erreur rapport revenus:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

// ============================================================================
// DATABASE MANAGEMENT
// ============================================================================

/**
 * @route   GET /api/admin/database/stats
 * @desc    Obtenir les statistiques de la base de données
 * @access  Private (Admin)
 */
router.get('/database/stats', protect, adminOnly, async (req, res) => {
    try {
        const stats = await getDatabaseStats();

        res.json({
            success: true,
            stats,
            retentionConfig: RETENTION_CONFIG,
        });
    } catch (error) {
        console.error('Erreur stats database:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   POST /api/admin/database/cleanup
 * @desc    Lancer un nettoyage manuel de la base de données
 * @access  Private (Admin)
 */
router.post('/database/cleanup', protect, adminOnly, async (req, res) => {
    try {
        console.log(`🧹 Nettoyage manuel lancé par admin: ${req.user.id}`);

        const result = await runFullCleanup();

        res.json({
            success: result.success,
            message: `Nettoyage terminé: ${result.totalDeleted} éléments supprimés, ${result.totalUpdated} mis à jour`,
            result,
        });
    } catch (error) {
        console.error('Erreur nettoyage database:', error);
        res.status(500).json({
            success: false,
            message: getErrorMessage(error),
        });
    }
});

/**
 * @route   GET /api/admin/database/retention-config
 * @desc    Obtenir la configuration de rétention des données
 * @access  Private (Admin)
 */
router.get('/database/retention-config', protect, adminOnly, async (req, res) => {
    res.json({
        success: true,
        config: RETENTION_CONFIG,
        description: {
            readNotifications: `Notifications lues supprimées après ${RETENTION_CONFIG.readNotifications} jours`,
            unreadNotifications: `Notifications non lues supprimées après ${RETENTION_CONFIG.unreadNotifications} jours`,
            messagesAfterCompletion: `Messages supprimés ${RETENTION_CONFIG.messagesAfterCompletion} jours après fin de réservation`,
            completedReservationData: `Photos des réservations terminées supprimées après ${RETENTION_CONFIG.completedReservationData} jours`,
            cancelledReservationData: `Données des réservations annulées nettoyées après ${RETENTION_CONFIG.cancelledReservationData} jours`,
        },
    });
});

// ============================================================================
// GESTION DES JOBS EXPIRES
// ============================================================================

const { processExpiredJobs, getExpiredJobsStats, findExpiredJobs, CONFIG: EXPIRED_JOBS_CONFIG } = require('../services/expiredJobsService');

/**
 * @route   GET /api/admin/expired-jobs/stats
 * @desc    Obtenir les statistiques des jobs expires
 * @access  Private (Admin)
 */
router.get('/expired-jobs/stats', protect, adminOnly, async (req, res) => {
    try {
        const stats = await getExpiredJobsStats();
        res.json({
            success: true,
            stats,
            config: EXPIRED_JOBS_CONFIG,
        });
    } catch (error) {
        console.error('Erreur stats jobs expires:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la recuperation des stats',
        });
    }
});

/**
 * @route   GET /api/admin/expired-jobs/list
 * @desc    Lister les jobs actuellement expires
 * @access  Private (Admin)
 */
router.get('/expired-jobs/list', protect, adminOnly, async (req, res) => {
    try {
        const expiredJobs = await findExpiredJobs();
        res.json({
            success: true,
            count: expiredJobs.length,
            jobs: expiredJobs.map(job => ({
                id: job._id,
                status: job.status,
                deadlineTime: job.deadlineTime,
                departureTime: job.departureTime,
                minutesOverdue: Math.floor((new Date() - job.deadlineTime) / (1000 * 60)),
                client: job.userId ? {
                    id: job.userId._id,
                    name: `${job.userId.firstName} ${job.userId.lastName}`,
                    email: job.userId.email,
                } : null,
                worker: job.workerId ? {
                    id: job.workerId._id,
                    name: `${job.workerId.firstName} ${job.workerId.lastName}`,
                    email: job.workerId.email,
                } : null,
                vehicle: job.vehicle ? {
                    brand: job.vehicle.brand,
                    model: job.vehicle.model,
                    licensePlate: job.vehicle.licensePlate,
                } : null,
            })),
        });
    } catch (error) {
        console.error('Erreur liste jobs expires:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la recuperation des jobs expires',
        });
    }
});

/**
 * @route   POST /api/admin/expired-jobs/process
 * @desc    Declencher manuellement le traitement des jobs expires
 * @access  Private (Admin)
 */
router.post('/expired-jobs/process', protect, adminOnly, async (req, res) => {
    try {
        console.log(`\n🔧 Traitement manuel des jobs expires declenche par admin ${req.user.email}`);
        const results = await processExpiredJobs();
        res.json({
            success: true,
            message: 'Traitement des jobs expires termine',
            results,
        });
    } catch (error) {
        console.error('Erreur traitement manuel:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du traitement',
            error: error.message,
        });
    }
});

/**
 * @route   GET /api/admin/workers/warnings
 * @desc    Lister les workers avec des avertissements
 * @access  Private (Admin)
 */
router.get('/workers/warnings', protect, adminOnly, async (req, res) => {
    try {
        const workers = await User.find({
            role: 'snowWorker',
            'workerProfile.warningCount': { $gt: 0 },
        }).select('firstName lastName email workerProfile.warningCount workerProfile.isSuspended workerProfile.cancellationHistory');

        res.json({
            success: true,
            count: workers.length,
            workers: workers.map(w => ({
                id: w._id,
                name: `${w.firstName} ${w.lastName}`,
                email: w.email,
                warningCount: w.workerProfile?.warningCount || 0,
                isSuspended: w.workerProfile?.isSuspended || false,
                cancellationHistory: w.workerProfile?.cancellationHistory || [],
            })),
        });
    } catch (error) {
        console.error('Erreur liste workers warnings:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la recuperation',
        });
    }
});

/**
 * @route   POST /api/admin/workers/:id/reset-warnings
 * @desc    Reinitialiser les avertissements d'un worker
 * @access  Private (Admin)
 */
router.post('/workers/:id/reset-warnings', protect, adminOnly, async (req, res) => {
    try {
        const worker = await User.findById(req.params.id);

        if (!worker || worker.role !== 'snowWorker') {
            return res.status(404).json({
                success: false,
                message: 'Worker non trouve',
            });
        }

        worker.workerProfile.warningCount = 0;
        worker.workerProfile.isSuspended = false;
        worker.workerProfile.suspendedAt = null;
        worker.workerProfile.suspensionReason = null;
        await worker.save();

        // Notifier le worker
        await Notification.create({
            userId: worker._id,
            type: 'systemNotification',
            title: 'Avertissements reinitialises',
            message: 'Vos avertissements ont ete reinitialises par un administrateur. Votre compte est de nouveau actif.',
        });

        res.json({
            success: true,
            message: `Avertissements de ${worker.firstName} ${worker.lastName} reinitialises`,
        });
    } catch (error) {
        console.error('Erreur reset warnings:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la reinitialisation',
        });
    }
});

// ============================================================================
// RECONCILIATION STRIPE
// ============================================================================

/**
 * @route   GET /api/admin/finance/reconciliation
 * @desc    Comparer les donnees locales avec Stripe pour detecter les ecarts
 * @access  Private (Admin)
 */
router.get('/finance/reconciliation', protect, adminOnly, async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        // Dates par defaut: 30 derniers jours
        const end = endDate ? new Date(endDate) : new Date();
        const start = startDate ? new Date(startDate) : new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

        // 1. Donnees locales depuis la base de donnees
        const localStats = await Reservation.aggregate([
            {
                $match: {
                    status: 'completed',
                    paymentStatus: 'paid',
                    completedAt: { $gte: start, $lte: end },
                },
            },
            {
                $group: {
                    _id: null,
                    totalRevenue: { $sum: '$totalPrice' },
                    platformFees: { $sum: '$payout.platformFee' },
                    workerPayouts: { $sum: '$payout.workerAmount' },
                    stripeFees: { $sum: { $ifNull: ['$payout.stripeFee', 0] } },
                    tips: { $sum: '$tipAmount' },
                    count: { $sum: 1 },
                },
            },
        ]);

        // 2. Donnees Stripe - Balance et transactions
        let stripeData = {
            balance: null,
            charges: { total: 0, count: 0 },
            transfers: { total: 0, count: 0 },
            refunds: { total: 0, count: 0 },
            fees: 0,
        };

        try {
            // Solde Stripe actuel
            const balance = await stripe.balance.retrieve();
            stripeData.balance = {
                available: balance.available.reduce((sum, b) => sum + b.amount, 0) / 100,
                pending: balance.pending.reduce((sum, b) => sum + b.amount, 0) / 100,
                currency: 'CAD',
            };

            // Charges (paiements recus) dans la periode
            const charges = await stripe.charges.list({
                created: {
                    gte: Math.floor(start.getTime() / 1000),
                    lte: Math.floor(end.getTime() / 1000),
                },
                limit: 100,
            });

            for (const charge of charges.data) {
                if (charge.status === 'succeeded') {
                    stripeData.charges.total += charge.amount / 100;
                    stripeData.charges.count++;
                    // Frais Stripe
                    if (charge.balance_transaction) {
                        try {
                            const txn = await stripe.balanceTransactions.retrieve(charge.balance_transaction);
                            stripeData.fees += txn.fee / 100;
                        } catch (e) {
                            // Ignorer si impossible de recuperer
                        }
                    }
                }
            }

            // Transferts vers les workers
            const transfers = await stripe.transfers.list({
                created: {
                    gte: Math.floor(start.getTime() / 1000),
                    lte: Math.floor(end.getTime() / 1000),
                },
                limit: 100,
            });

            for (const transfer of transfers.data) {
                stripeData.transfers.total += transfer.amount / 100;
                stripeData.transfers.count++;
            }

            // Remboursements
            const refunds = await stripe.refunds.list({
                created: {
                    gte: Math.floor(start.getTime() / 1000),
                    lte: Math.floor(end.getTime() / 1000),
                },
                limit: 100,
            });

            for (const refund of refunds.data) {
                if (refund.status === 'succeeded') {
                    stripeData.refunds.total += refund.amount / 100;
                    stripeData.refunds.count++;
                }
            }

        } catch (stripeError) {
            console.error('Erreur Stripe API:', stripeError.message);
            stripeData.error = 'Impossible de recuperer les donnees Stripe';
        }

        // 3. Calculer les ecarts
        const local = localStats[0] || { totalRevenue: 0, platformFees: 0, workerPayouts: 0, stripeFees: 0, tips: 0, count: 0 };

        const discrepancies = {
            revenue: {
                local: local.totalRevenue,
                stripe: stripeData.charges.total,
                difference: stripeData.charges.total - local.totalRevenue,
                percentDiff: local.totalRevenue > 0
                    ? (((stripeData.charges.total - local.totalRevenue) / local.totalRevenue) * 100).toFixed(2)
                    : 0,
            },
            workerPayouts: {
                local: local.workerPayouts,
                stripe: stripeData.transfers.total,
                difference: stripeData.transfers.total - local.workerPayouts,
            },
            stripeFees: {
                local: local.stripeFees,
                stripe: stripeData.fees,
                difference: stripeData.fees - local.stripeFees,
            },
            transactionCount: {
                local: local.count,
                stripe: stripeData.charges.count,
                difference: stripeData.charges.count - local.count,
            },
        };

        // 4. Trouver les reservations potentiellement desynchronisees
        const problematicReservations = await Reservation.find({
            completedAt: { $gte: start, $lte: end },
            $or: [
                { status: 'completed', paymentStatus: { $ne: 'paid' } },
                { paymentIntentId: { $exists: true }, 'payout.status': 'pending' },
            ],
        }).select('_id totalPrice status paymentStatus paymentIntentId payout.status createdAt')
          .limit(20);

        res.json({
            success: true,
            period: {
                start: start.toISOString(),
                end: end.toISOString(),
            },
            localDatabase: {
                totalRevenue: local.totalRevenue,
                platformFeesGross: local.platformFees,
                platformFeesNet: local.platformFees - local.stripeFees,
                workerPayouts: local.workerPayouts,
                stripeFees: local.stripeFees,
                tips: local.tips,
                reservationCount: local.count,
            },
            stripe: {
                balance: stripeData.balance,
                chargesTotal: stripeData.charges.total,
                chargesCount: stripeData.charges.count,
                transfersTotal: stripeData.transfers.total,
                transfersCount: stripeData.transfers.count,
                refundsTotal: stripeData.refunds.total,
                refundsCount: stripeData.refunds.count,
                feesTotal: stripeData.fees,
                error: stripeData.error || null,
            },
            discrepancies,
            problematicReservations: problematicReservations.map(r => ({
                id: r._id,
                totalPrice: r.totalPrice,
                status: r.status,
                paymentStatus: r.paymentStatus,
                payoutStatus: r.payout?.status,
                paymentIntentId: r.paymentIntentId,
                createdAt: r.createdAt,
            })),
            recommendations: generateReconciliationRecommendations(discrepancies, problematicReservations.length),
        });
    } catch (error) {
        console.error('Erreur reconciliation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la reconciliation',
        });
    }
});

/**
 * Genere des recommandations basees sur les ecarts detectes
 */
function generateReconciliationRecommendations(discrepancies, problematicCount) {
    const recommendations = [];

    if (Math.abs(discrepancies.revenue.difference) > 10) {
        recommendations.push({
            type: 'warning',
            message: `Ecart de revenus de ${discrepancies.revenue.difference.toFixed(2)}$ detecte`,
            action: 'Verifier les webhooks Stripe et les reservations non synchronisees',
        });
    }

    if (Math.abs(discrepancies.transactionCount.difference) > 0) {
        recommendations.push({
            type: 'warning',
            message: `${Math.abs(discrepancies.transactionCount.difference)} transaction(s) non synchronisee(s)`,
            action: 'Executer une synchronisation manuelle des paiements',
        });
    }

    if (problematicCount > 0) {
        recommendations.push({
            type: 'action',
            message: `${problematicCount} reservation(s) avec statut de paiement suspect`,
            action: 'Examiner les reservations listees et corriger manuellement si necessaire',
        });
    }

    if (discrepancies.stripeFees.difference > 5) {
        recommendations.push({
            type: 'info',
            message: 'Les frais Stripe locaux different des frais reels',
            action: 'Mettre a jour le calcul des frais Stripe (actuellement estime a 2.9% + 0.30$)',
        });
    }

    if (recommendations.length === 0) {
        recommendations.push({
            type: 'success',
            message: 'Aucun ecart significatif detecte',
            action: 'Les donnees sont synchronisees',
        });
    }

    return recommendations;
}

/**
 * @route   POST /api/admin/finance/cleanup-test-reservations
 * @desc    Supprimer les reservations de test (completed sans paiement)
 * @access  Private (Admin)
 */
router.post('/finance/cleanup-test-reservations', protect, adminOnly, async (req, res) => {
    try {
        const { dryRun = true } = req.body;

        // Trouver les reservations de test
        const testReservations = await Reservation.find({
            status: 'completed',
            paymentStatus: 'pending',
            $or: [
                { paymentIntentId: { $exists: false } },
                { paymentIntentId: null }
            ]
        }).select('_id totalPrice status paymentStatus createdAt');

        const summary = {
            found: testReservations.length,
            totalAmount: testReservations.reduce((sum, r) => sum + (r.totalPrice || 0), 0),
            reservations: testReservations.map(r => ({
                id: r._id,
                totalPrice: r.totalPrice,
                createdAt: r.createdAt,
            })),
            deleted: 0,
            dryRun,
        };

        if (!dryRun && testReservations.length > 0) {
            const result = await Reservation.deleteMany({
                status: 'completed',
                paymentStatus: 'pending',
                $or: [
                    { paymentIntentId: { $exists: false } },
                    { paymentIntentId: null }
                ]
            });
            summary.deleted = result.deletedCount;
        }

        res.json({
            success: true,
            message: dryRun
                ? `${summary.found} reservation(s) de test trouvee(s). Utilisez dryRun: false pour supprimer.`
                : `${summary.deleted} reservation(s) de test supprimee(s)`,
            summary,
        });
    } catch (error) {
        console.error('Erreur cleanup:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du nettoyage',
        });
    }
});

/**
 * @route   POST /api/admin/finance/fix-payouts
 * @desc    Calculer et remplir les champs payout manquants pour les réservations payées
 * @access  Private (Admin)
 */
router.post('/finance/fix-payouts', protect, adminOnly, async (req, res) => {
    try {
        const { dryRun = true } = req.body;

        // Trouver les réservations payées avec payout.platformFee manquant ou à 0
        const reservationsToFix = await Reservation.find({
            status: 'completed',
            paymentStatus: 'paid',
            $or: [
                { 'payout.platformFee': { $exists: false } },
                { 'payout.platformFee': null },
                { 'payout.platformFee': 0 }
            ]
        }).select('_id totalPrice tipAmount payout paymentIntentId');

        const summary = {
            found: reservationsToFix.length,
            fixed: 0,
            totalRevenue: 0,
            totalPlatformFees: 0,
            totalStripeFees: 0,
            totalWorkerPayouts: 0,
            details: []
        };

        const PLATFORM_FEE_PERCENT = 0.25; // 25%
        const STRIPE_FEE_PERCENT = 0.029; // 2.9%
        const STRIPE_FEE_FIXED = 0.30; // $0.30

        for (const reservation of reservationsToFix) {
            const totalPrice = reservation.totalPrice || 0;
            const tipAmount = reservation.tipAmount || 0;

            // Calcul des frais
            const platformFee = totalPrice * PLATFORM_FEE_PERCENT;
            const workerAmount = totalPrice * (1 - PLATFORM_FEE_PERCENT) + tipAmount;
            const stripeFee = (totalPrice + tipAmount) * STRIPE_FEE_PERCENT + STRIPE_FEE_FIXED;

            summary.totalRevenue += totalPrice;
            summary.totalPlatformFees += platformFee;
            summary.totalStripeFees += stripeFee;
            summary.totalWorkerPayouts += workerAmount;

            summary.details.push({
                id: reservation._id,
                totalPrice,
                platformFee: Math.round(platformFee * 100) / 100,
                stripeFee: Math.round(stripeFee * 100) / 100,
                workerAmount: Math.round(workerAmount * 100) / 100
            });

            if (!dryRun) {
                await Reservation.findByIdAndUpdate(reservation._id, {
                    'payout.platformFee': Math.round(platformFee * 100) / 100,
                    'payout.workerAmount': Math.round(workerAmount * 100) / 100,
                    'payout.stripeFee': Math.round(stripeFee * 100) / 100,
                    'payout.currency': 'cad'
                });
                summary.fixed++;
            }
        }

        // Arrondir les totaux
        summary.totalRevenue = Math.round(summary.totalRevenue * 100) / 100;
        summary.totalPlatformFees = Math.round(summary.totalPlatformFees * 100) / 100;
        summary.totalStripeFees = Math.round(summary.totalStripeFees * 100) / 100;
        summary.totalWorkerPayouts = Math.round(summary.totalWorkerPayouts * 100) / 100;

        res.json({
            success: true,
            message: dryRun
                ? `${summary.found} reservation(s) a corriger. Utilisez dryRun: false pour appliquer.`
                : `${summary.fixed} reservation(s) corrigee(s)`,
            summary: dryRun ? summary : { found: summary.found, fixed: summary.fixed }
        });
    } catch (error) {
        console.error('Erreur fix-payouts:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la correction des payouts',
        });
    }
});

/**
 * @route   POST /api/admin/finance/process-pending-payouts
 * @desc    Traiter les payouts en attente pour les réservations complétées et payées
 * @access  Private (Admin)
 */
router.post('/finance/process-pending-payouts', protect, adminOnly, async (req, res) => {
    try {
        const { dryRun = true } = req.body;

        // Trouver les réservations avec payout en attente
        const pendingPayouts = await Reservation.find({
            status: 'completed',
            paymentStatus: 'paid',
            'payout.status': { $in: ['pending', 'pending_payment', 'pending_account'] },
        }).populate('workerId', 'firstName lastName workerProfile.stripeConnectId');

        const summary = {
            found: pendingPayouts.length,
            processed: 0,
            succeeded: 0,
            failed: 0,
            noAccount: 0,
            details: [],
        };

        const PLATFORM_FEE_PERCENT_LOCAL = 0.25;

        for (const reservation of pendingPayouts) {
            const worker = reservation.workerId;
            const totalAmount = reservation.totalPrice;
            const tipAmount = reservation.tipAmount || 0;
            const platformFee = reservation.payout?.platformFee || (totalAmount * PLATFORM_FEE_PERCENT_LOCAL);
            const workerAmount = reservation.payout?.workerAmount || (totalAmount - platformFee + tipAmount);

            const detail = {
                reservationId: reservation._id,
                workerName: worker ? `${worker.firstName} ${worker.lastName}` : 'N/A',
                amount: workerAmount,
                currentStatus: reservation.payout?.status,
                hasStripeConnect: !!worker?.workerProfile?.stripeConnectId,
            };

            if (!worker?.workerProfile?.stripeConnectId) {
                detail.result = 'no_account';
                summary.noAccount++;
            } else if (!dryRun) {
                try {
                    const transfer = await stripe.transfers.create(
                        {
                            amount: Math.round(workerAmount * 100),
                            currency: 'cad',
                            destination: worker.workerProfile.stripeConnectId,
                            description: `Paiement job #${reservation._id}`,
                            metadata: {
                                reservationId: reservation._id.toString(),
                                workerId: worker._id.toString(),
                                originalAmount: totalAmount,
                                platformFee: platformFee,
                                tipAmount: tipAmount,
                            },
                        },
                        {
                            idempotencyKey: `transfer_job_${reservation._id}_retry`,
                        }
                    );

                    reservation.payout = {
                        ...reservation.payout,
                        status: 'completed',
                        stripeTransferId: transfer.id,
                        processedAt: new Date(),
                    };
                    await reservation.save();

                    // Update worker stats
                    worker.workerProfile.totalJobsCompleted = (worker.workerProfile.totalJobsCompleted || 0) + 1;
                    worker.workerProfile.totalEarnings = (worker.workerProfile.totalEarnings || 0) + workerAmount;
                    worker.workerProfile.totalTipsReceived = (worker.workerProfile.totalTipsReceived || 0) + tipAmount;
                    await worker.save();

                    detail.result = 'success';
                    detail.transferId = transfer.id;
                    summary.succeeded++;

                } catch (stripeError) {
                    detail.result = 'failed';
                    detail.error = stripeError.message;
                    summary.failed++;

                    reservation.payout.status = 'failed';
                    reservation.payout.error = stripeError.message;
                    await reservation.save();
                }
                summary.processed++;
            } else {
                detail.result = 'would_process';
            }

            summary.details.push(detail);
        }

        res.json({
            success: true,
            message: dryRun
                ? `${summary.found} payout(s) en attente trouve(s). ${summary.noAccount} sans compte Stripe. Utilisez dryRun: false pour traiter.`
                : `${summary.processed} payout(s) traite(s): ${summary.succeeded} reussi(s), ${summary.failed} echoue(s)`,
            summary,
        });
    } catch (error) {
        console.error('Erreur process-pending-payouts:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du traitement des payouts',
        });
    }
});

module.exports = router;
