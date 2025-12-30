const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const User = require('../models/User');
const Reservation = require('../models/Reservation');
const Notification = require('../models/Notification');

// Middleware pour vérifier le rôle admin
const adminOnly = authorize('admin');

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
                    platformFees: revenueStats[0]?.totalPlatformFees || 0,
                    workerPayouts: revenueStats[0]?.totalWorkerPayouts || 0,
                    tips: revenueStats[0]?.totalTips || 0,
                    thisMonth: monthlyRevenueStats[0]?.revenue || 0,
                    monthlyPlatformFees: monthlyRevenueStats[0]?.platformFees || 0,
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
            },
        });
    } catch (error) {
        console.error('Erreur dashboard admin:', error);
        res.status(500).json({
            success: false,
            message: error.message,
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
        if (role) query.role = role;
        if (search) {
            query.$or = [
                { firstName: { $regex: search, $options: 'i' } },
                { lastName: { $regex: search, $options: 'i' } },
                { email: { $regex: search, $options: 'i' } },
                { phoneNumber: { $regex: search, $options: 'i' } },
            ];
        }

        const sortOrder = order === 'desc' ? -1 : 1;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const [users, total] = await Promise.all([
            User.find(query)
                .select('-password -resetPasswordToken -resetPasswordExpire')
                .sort({ [sortBy]: sortOrder })
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
            message: error.message,
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
            message: error.message,
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

        Object.assign(user, updateData);
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
            message: error.message,
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
            message: error.message,
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
            message: error.message,
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
        if (status) query.status = status;
        if (startDate || endDate) {
            query.departureTime = {};
            if (startDate) query.departureTime.$gte = new Date(startDate);
            if (endDate) query.departureTime.$lte = new Date(endDate);
        }

        const sortOrder = order === 'desc' ? -1 : 1;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const [reservations, total] = await Promise.all([
            Reservation.find(query)
                .populate('userId', 'firstName lastName email phoneNumber')
                .populate('workerId', 'firstName lastName phoneNumber')
                .populate('vehicle')
                .sort({ [sortBy]: sortOrder })
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
            message: error.message,
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
            message: error.message,
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
        const reservation = await Reservation.findByIdAndUpdate(
            req.params.id,
            req.body,
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
            message: error.message,
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
            message: error.message,
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
            message: error.message,
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
            message: error.message,
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
            message: error.message,
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
            message: error.message,
        });
    }
});

module.exports = router;
