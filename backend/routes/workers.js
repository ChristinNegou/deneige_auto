const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { protect, authorize } = require('../middleware/auth');
const Reservation = require('../models/Reservation');
const User = require('../models/User');
const Notification = require('../models/Notification');
const Transaction = require('../models/Transaction');
const { uploadFromBuffer } = require('../config/cloudinary');

// Configure multer with memory storage for Cloudinary uploads
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB max
    },
    fileFilter: function (req, file, cb) {
        // Accept only images
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Seules les images sont acceptées'), false);
        }
    }
});

// Configure multer for profile photo uploads (also using Cloudinary)
const profileUpload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB max for profile photos
    },
    fileFilter: function (req, file, cb) {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Seules les images sont acceptées'), false);
        }
    }
});

// ============================================
// WORKER AVAILABILITY & LOCATION
// ============================================

// @route   PATCH /api/workers/availability
// @desc    Toggle worker availability
// @access  Private (Worker only)
router.patch('/availability', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { isAvailable } = req.body;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            { 'workerProfile.isAvailable': isAvailable },
            { new: true }
        );

        console.log(`👷 Worker ${user.firstName} is now ${isAvailable ? 'AVAILABLE' : 'UNAVAILABLE'}`);

        res.json({
            success: true,
            message: isAvailable ? 'Vous êtes maintenant disponible' : 'Vous êtes maintenant indisponible',
            isAvailable: user.workerProfile.isAvailable,
        });
    } catch (error) {
        console.error('Error toggling availability:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour de la disponibilité',
            error: error.message,
        });
    }
});

// @route   PUT /api/workers/location
// @desc    Update worker current location
// @access  Private (Worker only)
router.put('/location', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { latitude, longitude } = req.body;

        if (!latitude || !longitude) {
            return res.status(400).json({
                success: false,
                message: 'Latitude et longitude sont requises',
            });
        }

        const user = await User.findByIdAndUpdate(
            req.user.id,
            {
                'workerProfile.currentLocation': {
                    type: 'Point',
                    coordinates: [longitude, latitude], // GeoJSON format: [lng, lat]
                },
            },
            { new: true }
        );

        res.json({
            success: true,
            message: 'Position mise à jour',
            location: user.workerProfile.currentLocation,
        });
    } catch (error) {
        console.error('Error updating location:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour de la position',
            error: error.message,
        });
    }
});

// ============================================
// JOBS DISCOVERY & MANAGEMENT
// ============================================

// Helper function to compute required equipment for a reservation
const computeRequiredEquipment = (reservation) => {
    const required = ['shovel', 'brush']; // Base equipment always required

    if (reservation.serviceOptions && reservation.serviceOptions.length > 0) {
        if (reservation.serviceOptions.includes('windowScraping')) {
            required.push('ice_scraper');
        }
        if (reservation.serviceOptions.includes('doorDeicing')) {
            required.push('salt_spreader');
        }
    }

    // Heavy snow requires snow blower
    if (reservation.snowDepthCm && reservation.snowDepthCm > 15) {
        required.push('snow_blower');
    }

    return [...new Set(required)];
};

// Helper function to check if worker has required equipment
const workerHasRequiredEquipment = (workerEquipment, requiredEquipment) => {
    if (!requiredEquipment || requiredEquipment.length === 0) return true;
    if (!workerEquipment || workerEquipment.length === 0) return false;
    return requiredEquipment.every(eq => workerEquipment.includes(eq));
};

// @route   GET /api/workers/available-jobs
// @desc    Get available jobs near worker location (filtered by worker's equipment)
// @access  Private (Worker only)
router.get('/available-jobs', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { lat, lng, radiusKm = 50, filterByEquipment = 'true' } = req.query; // Default radius: 50km

        console.log(`🔍 Available jobs request from worker ${req.user.firstName}: lat=${lat}, lng=${lng}, radius=${radiusKm}km`);

        // Get worker's equipment list
        const workerEquipment = req.user.workerProfile?.equipmentList || [];

        if (!lat || !lng) {
            return res.status(400).json({
                success: false,
                message: 'Latitude et longitude sont requises',
            });
        }

        const latitude = parseFloat(lat);
        const longitude = parseFloat(lng);
        const radius = parseFloat(radiusKm);

        console.log(`📍 Searching jobs around [${longitude}, ${latitude}] within ${radius}km`);

        // Find pending reservations within radius, sorted by urgency and distance
        const now = new Date();
        const next24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000);

        // 1. Get reservations WITH location using geoNear
        // Inclure: departureTime futur OU créé récemment (moins de 2h)
        let geoReservations = [];
        try {
            geoReservations = await Reservation.aggregate([
                {
                    $geoNear: {
                        near: {
                            type: 'Point',
                            coordinates: [longitude, latitude],
                        },
                        distanceField: 'distance',
                        maxDistance: radius * 1000, // Convert km to meters
                        query: {
                            status: 'pending',
                            $or: [
                                // Réservations futures (dans les 24h)
                                { departureTime: { $gte: now, $lte: next24Hours } },
                                // OU réservations créées récemment (même si departureTime passé)
                                { createdAt: { $gte: twoHoursAgo } },
                            ],
                        },
                        spherical: true,
                    },
                },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'userId',
                        foreignField: '_id',
                        as: 'client',
                    },
                },
                {
                    $lookup: {
                        from: 'vehicles',
                        localField: 'vehicle',
                        foreignField: '_id',
                        as: 'vehicleInfo',
                    },
                },
                {
                    $unwind: { path: '$client', preserveNullAndEmptyArrays: true },
                },
                {
                    $unwind: { path: '$vehicleInfo', preserveNullAndEmptyArrays: true },
                },
                {
                    $addFields: {
                        distanceKm: { $divide: ['$distance', 1000] },
                        hoursUntilDeparture: {
                            $divide: [
                                { $subtract: ['$departureTime', now] },
                                1000 * 60 * 60,
                            ],
                        },
                    },
                },
            ]);
            console.log(`📊 GeoNear found ${geoReservations.length} reservations`);
        } catch (geoErr) {
            console.log('⚠️ GeoNear query failed (might be no 2dsphere index or no geo data):', geoErr.message);
        }

        // Si aucune réservation trouvée par géolocalisation, chercher toutes les pending
        let allReservations = [...geoReservations];

        if (allReservations.length === 0) {
            console.log('📍 Aucune réservation trouvée par géolocalisation, recherche de toutes les réservations pending...');

            // Fallback: chercher toutes les réservations pending sans filtre géospatial
            // Inclure: departureTime futur OU créé récemment (moins de 2h)
            const fallbackReservations = await Reservation.find({
                status: 'pending',
                $or: [
                    { departureTime: { $gte: now, $lte: next24Hours } },
                    { createdAt: { $gte: twoHoursAgo } },
                ],
            })
                .populate('userId', 'firstName lastName phoneNumber')
                .populate('vehicle', 'make model color licensePlate photoUrl')
                .lean();

            console.log(`📋 Fallback: ${fallbackReservations.length} réservations pending trouvées`);

            // Ajouter des champs calculés
            allReservations = fallbackReservations.map(r => ({
                ...r,
                client: r.userId,
                vehicleInfo: r.vehicle,
                distanceKm: null, // Distance inconnue sans géolocalisation
                hoursUntilDeparture: (new Date(r.departureTime) - now) / (1000 * 60 * 60),
            }));
        }

        // Sort: priority first, then by urgency, then by distance
        allReservations.sort((a, b) => {
            // Priority first
            if (a.isPriority && !b.isPriority) return -1;
            if (!a.isPriority && b.isPriority) return 1;
            // Then by urgency (hours until departure)
            if (a.hoursUntilDeparture !== b.hoursUntilDeparture) {
                return a.hoursUntilDeparture - b.hoursUntilDeparture;
            }
            // Then by distance
            return (a.distanceKm || 0) - (b.distanceKm || 0);
        });

        // Compute required equipment for each reservation
        const reservationsWithEquipment = allReservations.map(r => ({
            ...r,
            requiredEquipment: r.requiredEquipment || computeRequiredEquipment(r),
        }));

        // Filter by equipment if enabled
        const shouldFilter = filterByEquipment === 'true';
        const filteredReservations = shouldFilter
            ? reservationsWithEquipment.filter(r =>
                workerHasRequiredEquipment(workerEquipment, r.requiredEquipment))
            : reservationsWithEquipment;

        console.log(`🔧 Worker equipment: [${workerEquipment.join(', ')}]`);
        console.log(`📋 ${reservationsWithEquipment.length} total jobs, ${filteredReservations.length} compatible with worker equipment`);

        // Format output
        const formattedReservations = filteredReservations.map(r => ({
            _id: r._id,
            departureTime: r.departureTime,
            deadlineTime: r.deadlineTime,
            status: r.status,
            serviceOptions: r.serviceOptions,
            snowDepthCm: r.snowDepthCm,
            totalPrice: r.totalPrice,
            isPriority: r.isPriority,
            notes: r.notes,
            location: r.location,
            parkingSpotNumber: r.parkingSpotNumber,
            customLocation: r.customLocation,
            distanceKm: r.distanceKm,
            hoursUntilDeparture: r.hoursUntilDeparture,
            createdAt: r.createdAt,
            requiredEquipment: r.requiredEquipment,
            workerHasEquipment: workerHasRequiredEquipment(workerEquipment, r.requiredEquipment),
            client: r.client ? {
                _id: r.client._id,
                firstName: r.client.firstName,
                lastName: r.client.lastName,
                phoneNumber: r.client.phoneNumber,
            } : null,
            vehicle: r.vehicleInfo ? {
                _id: r.vehicleInfo._id,
                make: r.vehicleInfo.make,
                model: r.vehicleInfo.model,
                color: r.vehicleInfo.color,
                licensePlate: r.vehicleInfo.licensePlate,
                photoUrl: r.vehicleInfo.photoUrl,
            } : null,
        }));

        console.log(`📍 Found ${formattedReservations.length} available jobs within ${radius}km`);

        res.json({
            success: true,
            count: formattedReservations.length,
            data: formattedReservations,
        });
    } catch (error) {
        console.error('Error fetching available jobs:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des jobs disponibles',
            error: error.message,
        });
    }
});

// @route   GET /api/workers/my-jobs
// @desc    Get worker's assigned and in-progress jobs
// @access  Private (Worker only)
router.get('/my-jobs', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const reservations = await Reservation.find({
            workerId: req.user.id,
            status: { $in: ['assigned', 'enRoute', 'inProgress'] },
        })
            .populate('userId', 'firstName lastName phoneNumber')
            .populate('vehicle', 'make model color licensePlate photoUrl')
            .sort({ departureTime: 1 });

        res.json({
            success: true,
            count: reservations.length,
            data: reservations,
        });
    } catch (error) {
        console.error('Error fetching my jobs:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de vos jobs',
            error: error.message,
        });
    }
});

// @route   GET /api/workers/history
// @desc    Get worker's completed jobs history
// @access  Private (Worker only)
router.get('/history', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { page = 1, limit = 20, startDate, endDate } = req.query;

        const query = {
            workerId: req.user.id,
            status: { $in: ['completed', 'cancelled'] },
        };

        // Date filters
        if (startDate || endDate) {
            query.completedAt = {};
            if (startDate) query.completedAt.$gte = new Date(startDate);
            if (endDate) query.completedAt.$lte = new Date(endDate);
        }

        const total = await Reservation.countDocuments(query);

        const reservations = await Reservation.find(query)
            .populate('userId', 'firstName lastName phoneNumber')
            .populate('vehicle', 'make model color licensePlate photoUrl')
            .sort({ completedAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        res.json({
            success: true,
            count: reservations.length,
            total,
            page: parseInt(page),
            pages: Math.ceil(total / limit),
            data: reservations,
        });
    } catch (error) {
        console.error('Error fetching job history:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de l\'historique',
            error: error.message,
        });
    }
});

// ============================================
// WORKER STATISTICS & EARNINGS
// ============================================

// @route   GET /api/workers/stats
// @desc    Get worker statistics (today, week, month, all-time)
// @access  Private (Worker only)
router.get('/stats', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const now = new Date();
        const startOfToday = new Date(now.setHours(0, 0, 0, 0));
        const startOfWeek = new Date(now);
        startOfWeek.setDate(now.getDate() - now.getDay());
        startOfWeek.setHours(0, 0, 0, 0);
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

        // Get worker profile for all-time stats
        const worker = await User.findById(req.user.id);

        // Today's stats
        const todayStats = await Reservation.aggregate([
            {
                $match: {
                    workerId: req.user._id,
                    completedAt: { $gte: startOfToday },
                    status: 'completed',
                },
            },
            {
                $group: {
                    _id: null,
                    completed: { $sum: 1 },
                    earnings: { $sum: '$totalPrice' },
                    tips: { $sum: { $ifNull: ['$tipAmount', 0] } },
                },
            },
        ]);

        // Count in-progress jobs
        const inProgressCount = await Reservation.countDocuments({
            workerId: req.user.id,
            status: 'inProgress',
        });

        // Count assigned jobs (pending acceptance)
        const assignedCount = await Reservation.countDocuments({
            workerId: req.user.id,
            status: 'assigned',
        });

        // Week stats
        const weekStats = await Reservation.aggregate([
            {
                $match: {
                    workerId: req.user._id,
                    completedAt: { $gte: startOfWeek },
                    status: 'completed',
                },
            },
            {
                $group: {
                    _id: null,
                    completed: { $sum: 1 },
                    earnings: { $sum: '$totalPrice' },
                    tips: { $sum: { $ifNull: ['$tipAmount', 0] } },
                },
            },
        ]);

        // Month stats
        const monthStats = await Reservation.aggregate([
            {
                $match: {
                    workerId: req.user._id,
                    completedAt: { $gte: startOfMonth },
                    status: 'completed',
                },
            },
            {
                $group: {
                    _id: null,
                    completed: { $sum: 1 },
                    earnings: { $sum: '$totalPrice' },
                    tips: { $sum: { $ifNull: ['$tipAmount', 0] } },
                },
            },
        ]);

        res.json({
            success: true,
            data: {
                today: {
                    completed: todayStats[0]?.completed || 0,
                    inProgress: inProgressCount,
                    assigned: assignedCount,
                    earnings: todayStats[0]?.earnings || 0,
                    tips: todayStats[0]?.tips || 0,
                },
                week: {
                    completed: weekStats[0]?.completed || 0,
                    earnings: weekStats[0]?.earnings || 0,
                    tips: weekStats[0]?.tips || 0,
                },
                month: {
                    completed: monthStats[0]?.completed || 0,
                    earnings: monthStats[0]?.earnings || 0,
                    tips: monthStats[0]?.tips || 0,
                },
                allTime: {
                    completed: worker.workerProfile?.totalJobsCompleted || 0,
                    earnings: worker.workerProfile?.totalEarnings || 0,
                    tips: worker.workerProfile?.totalTipsReceived || 0,
                    averageRating: worker.workerProfile?.averageRating || 0,
                    totalRatings: worker.workerProfile?.totalRatingsCount || 0,
                },
                isAvailable: worker.workerProfile?.isAvailable || false,
            },
        });
    } catch (error) {
        console.error('Error fetching worker stats:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des statistiques',
            error: error.message,
        });
    }
});

// @route   GET /api/workers/earnings
// @desc    Get detailed earnings breakdown
// @access  Private (Worker only)
router.get('/earnings', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { period = 'week' } = req.query;

        const now = new Date();
        let startDate;

        switch (period) {
            case 'day':
                startDate = new Date(now.setHours(0, 0, 0, 0));
                break;
            case 'week':
                startDate = new Date(now);
                startDate.setDate(now.getDate() - 7);
                break;
            case 'month':
                startDate = new Date(now.getFullYear(), now.getMonth(), 1);
                break;
            case 'year':
                startDate = new Date(now.getFullYear(), 0, 1);
                break;
            default:
                startDate = new Date(now);
                startDate.setDate(now.getDate() - 7);
        }

        // Daily breakdown
        const dailyEarnings = await Reservation.aggregate([
            {
                $match: {
                    workerId: req.user._id,
                    completedAt: { $gte: startDate },
                    status: 'completed',
                },
            },
            {
                $group: {
                    _id: {
                        $dateToString: { format: '%Y-%m-%d', date: '$completedAt' },
                    },
                    jobsCount: { $sum: 1 },
                    earnings: { $sum: '$totalPrice' },
                    tips: { $sum: { $ifNull: ['$tipAmount', 0] } },
                },
            },
            { $sort: { _id: 1 } },
        ]);

        // Total summary
        const totalSummary = await Reservation.aggregate([
            {
                $match: {
                    workerId: req.user._id,
                    completedAt: { $gte: startDate },
                    status: 'completed',
                },
            },
            {
                $group: {
                    _id: null,
                    totalJobs: { $sum: 1 },
                    totalEarnings: { $sum: '$totalPrice' },
                    totalTips: { $sum: { $ifNull: ['$tipAmount', 0] } },
                    avgJobPrice: { $avg: '$totalPrice' },
                },
            },
        ]);

        res.json({
            success: true,
            period,
            startDate,
            data: {
                daily: dailyEarnings,
                summary: totalSummary[0] || {
                    totalJobs: 0,
                    totalEarnings: 0,
                    totalTips: 0,
                    avgJobPrice: 0,
                },
            },
        });
    } catch (error) {
        console.error('Error fetching earnings:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des revenus',
            error: error.message,
        });
    }
});

// ============================================
// WORKER PROFILE
// ============================================

// @route   GET /api/workers/profile
// @desc    Get worker profile
// @access  Private (Worker only)
router.get('/profile', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const worker = await User.findById(req.user.id);

        res.json({
            success: true,
            data: {
                id: worker._id,
                email: worker.email,
                firstName: worker.firstName,
                lastName: worker.lastName,
                phoneNumber: worker.phoneNumber,
                photoUrl: worker.photoUrl,
                workerProfile: worker.workerProfile,
            },
        });
    } catch (error) {
        console.error('Error fetching worker profile:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération du profil',
            error: error.message,
        });
    }
});

// @route   PUT /api/workers/profile
// @desc    Update worker profile (zones, equipment, settings)
// @access  Private (Worker only)
router.put('/profile', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { preferredZones, equipmentList, vehicleType, maxActiveJobs, notificationPreferences } = req.body;

        const updateData = {};

        if (preferredZones !== undefined) {
            updateData['workerProfile.preferredZones'] = preferredZones;
        }
        if (equipmentList !== undefined) {
            updateData['workerProfile.equipmentList'] = equipmentList;
        }
        if (vehicleType !== undefined) {
            updateData['workerProfile.vehicleType'] = vehicleType;
        }
        if (maxActiveJobs !== undefined) {
            updateData['workerProfile.maxActiveJobs'] = maxActiveJobs;
        }
        if (notificationPreferences !== undefined) {
            if (notificationPreferences.newJobs !== undefined) {
                updateData['workerProfile.notificationPreferences.newJobs'] = notificationPreferences.newJobs;
            }
            if (notificationPreferences.urgentJobs !== undefined) {
                updateData['workerProfile.notificationPreferences.urgentJobs'] = notificationPreferences.urgentJobs;
            }
            if (notificationPreferences.tips !== undefined) {
                updateData['workerProfile.notificationPreferences.tips'] = notificationPreferences.tips;
            }
        }

        const worker = await User.findByIdAndUpdate(
            req.user.id,
            updateData,
            { new: true }
        );

        res.json({
            success: true,
            message: 'Profil mis à jour',
            data: worker.workerProfile,
        });
    } catch (error) {
        console.error('Error updating worker profile:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour du profil',
            error: error.message,
        });
    }
});

// @route   POST /api/workers/profile/photo
// @desc    Upload worker profile photo
// @access  Private (Worker only)
router.post('/profile/photo', protect, authorize('snowWorker'), profileUpload.single('photo'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Photo requise',
            });
        }

        // Upload vers Cloudinary
        const cloudinaryResult = await uploadFromBuffer(req.file.buffer, {
            folder: 'deneige-auto/profiles',
            public_id: `worker-${req.user.id}-${Date.now()}`,
        });

        const photoUrl = cloudinaryResult.url;

        // Update user's photoUrl
        const worker = await User.findByIdAndUpdate(
            req.user.id,
            { photoUrl: photoUrl },
            { new: true }
        );

        console.log(`📷 Profile photo uploaded to Cloudinary for worker ${worker.firstName}: ${photoUrl}`);

        res.json({
            success: true,
            message: 'Photo de profil mise à jour',
            data: {
                photoUrl: photoUrl,
            },
        });
    } catch (error) {
        console.error('Error uploading profile photo:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'upload de la photo de profil',
            error: error.message,
        });
    }
});

// ============================================
// JOB ACTIONS
// ============================================

// @route   POST /api/workers/jobs/:id/accept
// @desc    Accept a job
// @access  Private (Worker only)
router.post('/jobs/:id/accept', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { id } = req.params;

        // Check if reservation exists and is pending
        const reservation = await Reservation.findById(id);

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        if (reservation.status !== 'pending') {
            return res.status(400).json({
                success: false,
                message: 'Cette réservation n\'est plus disponible',
            });
        }

        // Check worker's active job count
        const activeJobsCount = await Reservation.countDocuments({
            workerId: req.user.id,
            status: { $in: ['assigned', 'inProgress'] },
        });

        const worker = await User.findById(req.user.id);
        const maxJobs = worker.workerProfile?.maxActiveJobs || 3;

        if (activeJobsCount >= maxJobs) {
            return res.status(400).json({
                success: false,
                message: `Vous avez déjà ${maxJobs} jobs actifs. Terminez-en un avant d'en accepter un nouveau.`,
            });
        }

        // Accept the job
        reservation.workerId = req.user.id;
        reservation.status = 'assigned';
        reservation.assignedAt = new Date();
        await reservation.save();

        // Populate for response
        await reservation.populate('userId', 'firstName lastName phoneNumber');
        await reservation.populate('vehicle', 'make model color licensePlate photoUrl');

        // Send notification to client
        await Notification.createNotification({
            userId: reservation.userId._id,
            type: 'reservationAssigned',
            title: 'Déneigeur assigné',
            message: `${worker.firstName} ${worker.lastName} a accepté votre demande de déneigement.`,
            reservationId: reservation._id,
            workerId: worker._id,
            metadata: {
                workerName: `${worker.firstName} ${worker.lastName}`,
                workerPhone: worker.phoneNumber,
            },
        });

        console.log(`✅ Worker ${worker.firstName} accepted job ${reservation._id}`);

        res.json({
            success: true,
            message: 'Job accepté avec succès',
            data: reservation,
        });
    } catch (error) {
        console.error('Error accepting job:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'acceptation du job',
            error: error.message,
        });
    }
});

// @route   PATCH /api/workers/jobs/:id/en-route
// @desc    Mark worker as en route to job
// @access  Private (Worker only)
router.patch('/jobs/:id/en-route', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { id } = req.params;
        const { latitude, longitude, estimatedMinutes } = req.body;

        const reservation = await Reservation.findOne({
            _id: id,
            workerId: req.user.id,
            status: 'assigned',
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou non assignée à vous',
            });
        }

        reservation.status = 'enRoute';
        reservation.workerEnRouteAt = new Date();
        if (latitude && longitude) {
            reservation.workerLocation = {
                type: 'Point',
                coordinates: [longitude, latitude],
            };
        }
        if (estimatedMinutes) {
            reservation.estimatedArrivalTime = new Date(Date.now() + estimatedMinutes * 60 * 1000);
        }
        await reservation.save();

        // Populate for response
        await reservation.populate('userId', 'firstName lastName phoneNumber');
        await reservation.populate('vehicle', 'make model color licensePlate photoUrl');

        // Send notification to client
        const worker = await User.findById(req.user.id);
        await Notification.createNotification({
            userId: reservation.userId._id,
            type: 'workerEnRoute',
            title: 'Déneigeur en route',
            message: `${worker.firstName} est en route vers votre véhicule.`,
            reservationId: reservation._id,
            workerId: req.user.id,
            metadata: {
                estimatedArrival: reservation.estimatedArrivalTime,
            },
        });

        res.json({
            success: true,
            message: 'Statut mis à jour: en route',
            data: reservation,
        });
    } catch (error) {
        console.error('Error marking en route:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour du statut',
            error: error.message,
        });
    }
});

// @route   PATCH /api/workers/jobs/:id/start
// @desc    Start working on job
// @access  Private (Worker only)
router.patch('/jobs/:id/start', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { id } = req.params;

        const reservation = await Reservation.findOne({
            _id: id,
            workerId: req.user.id,
            status: { $in: ['assigned', 'enRoute'] },
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou non prête à démarrer',
            });
        }

        reservation.status = 'inProgress';
        reservation.startedAt = new Date();
        reservation.workerArrivedAt = new Date();
        await reservation.save();

        // Populate for response
        await reservation.populate('userId', 'firstName lastName phoneNumber');
        await reservation.populate('vehicle', 'make model color licensePlate photoUrl');

        // Send notification to client
        const worker = await User.findById(req.user.id);
        await Notification.createNotification({
            userId: reservation.userId._id,
            type: 'workStarted',
            title: 'Déneigement en cours',
            message: `${worker.firstName} a commencé le déneigement de votre véhicule.`,
            reservationId: reservation._id,
            workerId: req.user.id,
        });

        res.json({
            success: true,
            message: 'Travail commencé',
            data: reservation,
        });
    } catch (error) {
        console.error('Error starting job:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du démarrage du travail',
            error: error.message,
        });
    }
});

// @route   PATCH /api/workers/jobs/:id/complete
// @desc    Complete job
// @access  Private (Worker only)
router.patch('/jobs/:id/complete', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { id } = req.params;
        const { workerNotes } = req.body;

        const reservation = await Reservation.findOne({
            _id: id,
            workerId: req.user.id,
            status: 'inProgress',
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou pas en cours',
            });
        }

        // Check if there's at least one 'after' photo
        const hasAfterPhoto = reservation.photos && reservation.photos.some(p => p.type === 'after');
        if (!hasAfterPhoto) {
            return res.status(400).json({
                success: false,
                message: 'Une photo du travail terminé est requise avant de compléter',
                requiresPhoto: true,
            });
        }

        reservation.status = 'completed';
        reservation.completedAt = new Date();
        if (workerNotes) {
            reservation.workerNotes = workerNotes;
        }
        await reservation.save();

        // Populate for response
        await reservation.populate('userId', 'firstName lastName phoneNumber');
        await reservation.populate('vehicle', 'make model color licensePlate photoUrl');

        // Update worker stats
        await User.findByIdAndUpdate(req.user.id, {
            $inc: {
                'workerProfile.totalJobsCompleted': 1,
                'workerProfile.totalEarnings': reservation.totalPrice,
            },
        });

        // Send notification to client
        const worker = await User.findById(req.user.id);
        await Notification.createNotification({
            userId: reservation.userId._id,
            type: 'workCompleted',
            title: 'Déneigement terminé',
            message: `${worker.firstName} a terminé le déneigement de votre véhicule. N'hésitez pas à laisser un avis!`,
            reservationId: reservation._id,
            workerId: req.user.id,
            metadata: {
                completedAt: reservation.completedAt,
                totalPrice: reservation.totalPrice,
            },
        });

        console.log(`✅ Job ${reservation._id} completed by worker ${worker.firstName}`);

        // ============================================
        // PAYOUT AUTOMATIQUE AU DÉNEIGEUR
        // ============================================
        const workerConnectId = worker?.workerProfile?.stripeConnectId;
        const isPaid = reservation.paymentStatus === 'paid' || reservation.paymentIntentId;
        const payoutNotDone = reservation.payout?.status !== 'paid';

        if (workerConnectId && isPaid && payoutNotDone) {
            try {
                const PLATFORM_FEE_PERCENT = 0.25; // 25% commission plateforme
                const grossAmount = reservation.totalPrice;
                const platformFee = grossAmount * PLATFORM_FEE_PERCENT;
                const stripeFee = (grossAmount * 0.029) + 0.30;
                const workerAmount = grossAmount - platformFee;

                // Créer le transfert vers le compte Connect du déneigeur
                const transfer = await stripe.transfers.create({
                    amount: Math.round(workerAmount * 100), // En cents
                    currency: 'cad',
                    destination: workerConnectId,
                    description: `Paiement pour réservation #${reservation._id}`,
                    metadata: {
                        reservationId: reservation._id.toString(),
                        workerId: worker._id.toString(),
                        clientId: reservation.userId._id.toString(),
                    },
                });

                // Mettre à jour la réservation avec les infos de payout
                reservation.payout = {
                    status: 'paid',
                    workerAmount: workerAmount,
                    platformFee: platformFee,
                    stripeFee: stripeFee,
                    stripeTransferId: transfer.id,
                    paidAt: new Date(),
                };
                await reservation.save();

                // Créer la transaction
                await Transaction.create({
                    type: 'payout',
                    status: 'succeeded',
                    amount: workerAmount,
                    reservationId: reservation._id,
                    toUserId: worker._id,
                    stripeTransferId: transfer.id,
                    breakdown: {
                        grossAmount,
                        stripeFee,
                        platformFee,
                        workerAmount,
                    },
                    description: `Paiement automatique pour réservation #${reservation._id}`,
                    processedAt: new Date(),
                });

                console.log(`💰 Payout automatique effectué: ${workerAmount}$ vers ${worker.firstName} (Transfer: ${transfer.id})`);

                // Notification au déneigeur
                await Notification.createNotification({
                    userId: worker._id,
                    type: 'paymentReceived',
                    title: 'Paiement reçu',
                    message: `Vous avez reçu ${workerAmount.toFixed(2)} $ pour le job complété.`,
                    reservationId: reservation._id,
                    metadata: {
                        amount: workerAmount,
                        transferId: transfer.id,
                    },
                });
            } catch (payoutError) {
                console.error('⚠️ Erreur payout automatique (job complété quand même):', payoutError.message);
                // Le job est marqué complété même si le payout échoue
                // On peut réessayer le payout manuellement plus tard
            }
        } else if (!workerConnectId) {
            console.log('⚠️ Pas de compte Stripe Connect configuré pour le déneigeur - payout reporté');
        } else if (!isPaid) {
            console.log('⚠️ Paiement non effectué - payout reporté');
        }

        res.json({
            success: true,
            message: 'Travail terminé avec succès',
            data: reservation,
        });
    } catch (error) {
        console.error('Error completing job:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la complétion du travail',
            error: error.message,
        });
    }
});

// @route   POST /api/workers/jobs/:id/photos/upload
// @desc    Upload before/after photo to Cloudinary
// @access  Private (Worker only)
router.post('/jobs/:id/photos/upload', protect, authorize('snowWorker'), upload.single('photo'), async (req, res) => {
    try {
        const { id } = req.params;
        const { type } = req.body;

        if (!type || !['before', 'after'].includes(type)) {
            return res.status(400).json({
                success: false,
                message: 'Type de photo invalide (before ou after)',
            });
        }

        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Photo requise',
            });
        }

        const reservation = await Reservation.findOne({
            _id: id,
            workerId: req.user.id,
            status: { $in: ['assigned', 'enRoute', 'inProgress'] },
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Upload vers Cloudinary
        const cloudinaryResult = await uploadFromBuffer(req.file.buffer, {
            folder: `deneige-auto/jobs/${id}`,
            public_id: `${type}-${Date.now()}`,
        });

        const photoUrl = cloudinaryResult.url;

        reservation.photos.push({
            url: photoUrl,
            type,
            uploadedAt: new Date(),
            cloudinaryPublicId: cloudinaryResult.publicId,
        });
        await reservation.save();

        console.log(`📷 Photo ${type} uploaded to Cloudinary for job ${id}: ${photoUrl}`);

        res.json({
            success: true,
            message: `Photo ${type === 'before' ? 'avant' : 'après'} ajoutée`,
            data: {
                url: photoUrl,
                type,
                photos: reservation.photos,
            },
        });
    } catch (error) {
        console.error('Error uploading photo:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'ajout de la photo',
            error: error.message,
        });
    }
});

// @route   POST /api/workers/jobs/:id/photos
// @desc    Upload before/after photo (URL version - legacy)
// @access  Private (Worker only)
router.post('/jobs/:id/photos', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const { id } = req.params;
        const { type, photoUrl } = req.body;

        if (!type || !['before', 'after'].includes(type)) {
            return res.status(400).json({
                success: false,
                message: 'Type de photo invalide (before ou after)',
            });
        }

        if (!photoUrl) {
            return res.status(400).json({
                success: false,
                message: 'URL de la photo requise',
            });
        }

        const reservation = await Reservation.findOne({
            _id: id,
            workerId: req.user.id,
            status: { $in: ['assigned', 'enRoute', 'inProgress'] },
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        reservation.photos.push({
            url: photoUrl,
            type,
            uploadedAt: new Date(),
        });
        await reservation.save();

        res.json({
            success: true,
            message: `Photo ${type === 'before' ? 'avant' : 'après'} ajoutée`,
            data: reservation.photos,
        });
    } catch (error) {
        console.error('Error uploading photo:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'ajout de la photo',
            error: error.message,
        });
    }
});

module.exports = router;
