/**
 * Routes pour les déneigeurs : disponibilité, localisation, jobs, statistiques, profil et vérification d'identité.
 * @module routes/workers
 */

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
const { PLATFORM_FEE_PERCENT, WORKER_PERCENT, FILE_UPLOAD, GEOLOCATION } = require('../config/constants');
const { logError, safeNotify } = require('../utils/errorHandler');
const { locationLimiter, uploadLimiter } = require('../middleware/rateLimiter');
const smartNotifications = require('../services/smartNotificationService');
const verificationRequired = require('../middleware/verificationRequired');
const identityVerificationService = require('../services/identityVerificationService');

// Configure multer with memory storage for Cloudinary uploads
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: FILE_UPLOAD.MAX_FILE_SIZE,
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

// --- Disponibilité et localisation ---

/**
 * PATCH /api/workers/availability
 * Active ou désactive la disponibilité du déneigeur.
 * @param {boolean} req.body.isAvailable - Statut de disponibilité
 */
router.patch('/availability', protect, authorize('snowWorker'), verificationRequired, async (req, res) => {
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
        });
    }
});

/**
 * PUT /api/workers/location
 * Met à jour la position GPS du déneigeur (format GeoJSON).
 * @param {number} req.body.latitude - Latitude
 * @param {number} req.body.longitude - Longitude
 */
router.put('/location', protect, authorize('snowWorker'), locationLimiter, async (req, res) => {
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
        });
    }
});

// --- Découverte et gestion des jobs ---

/**
 * Calcule l'équipement requis pour une réservation selon ses options de service.
 * @param {Object} reservation - Document de réservation
 * @returns {string[]} Liste d'équipement requis (sans doublons)
 */
const computeRequiredEquipment = (reservation) => {
    const required = ['shovel', 'brush']; // Base equipment always required

    if (reservation.serviceOptions && reservation.serviceOptions.length > 0) {
        // Grattage des vitres
        if (reservation.serviceOptions.includes('windowScraping')) {
            required.push('ice_scraper');
        }
        // Déglaçage des portes
        if (reservation.serviceOptions.includes('doorDeicing')) {
            required.push('ice_scraper');
            required.push('deicer_spray');
        }
        // Déneigement du toit
        if (reservation.serviceOptions.includes('roofClearing')) {
            required.push('roof_broom');
        }
        // Épandage de sel
        if (reservation.serviceOptions.includes('saltSpreading')) {
            required.push('salt_spreader');
        }
        // Nettoyage des phares/feux
        if (reservation.serviceOptions.includes('lightsCleaning')) {
            required.push('microfiber_cloth');
        }
        // perimeterClearance - uses shovel (already in base)
        // exhaustCheck - no specific equipment needed (visual check)
    }

    // Heavy snow requires snow blower
    if (reservation.snowDepthCm && reservation.snowDepthCm > 15) {
        required.push('snow_blower');
    }

    return [...new Set(required)];
};

/**
 * Vérifie si le déneigeur possède tout l'équipement requis.
 * @param {string[]} workerEquipment - Équipement du déneigeur
 * @param {string[]} requiredEquipment - Équipement requis
 * @returns {boolean} true si le déneigeur a tout l'équipement
 */
const workerHasRequiredEquipment = (workerEquipment, requiredEquipment) => {
    if (!requiredEquipment || requiredEquipment.length === 0) return true;
    if (!workerEquipment || workerEquipment.length === 0) return false;
    return requiredEquipment.every(eq => workerEquipment.includes(eq));
};

/**
 * GET /api/workers/available-jobs
 * Retourne les jobs disponibles proches du déneigeur, filtrés par équipement.
 * Utilise la recherche géospatiale ($geoNear) avec repli sur recherche globale.
 * @param {number} req.query.lat - Latitude du déneigeur
 * @param {number} req.query.lng - Longitude du déneigeur
 * @param {number} [req.query.radiusKm=50] - Rayon de recherche en km
 * @param {string} [req.query.filterByEquipment='true'] - Filtrer par équipement
 */
router.get('/available-jobs', protect, authorize('snowWorker'), verificationRequired, async (req, res) => {
    try {
        const { lat, lng, radiusKm = GEOLOCATION.DEFAULT_SEARCH_RADIUS_KM, filterByEquipment = 'true' } = req.query;

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
        });
    }
});

/**
 * GET /api/workers/my-jobs
 * Retourne les jobs actifs du déneigeur (assigned, enRoute, inProgress).
 */
router.get('/my-jobs', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const reservations = await Reservation.find({
            workerId: req.user.id,
            status: { $in: ['assigned', 'enRoute', 'inProgress'] },
        })
            .populate('userId', 'firstName lastName phoneNumber')
            .populate('vehicle', 'make model color licensePlate photoUrl')
            .sort({ departureTime: 1 })
            .lean();

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
        });
    }
});

/**
 * GET /api/workers/history
 * Retourne l'historique des jobs terminés/annulés du déneigeur avec pagination.
 * @param {string} [req.query.startDate] - Date de début (ISO 8601)
 * @param {string} [req.query.endDate] - Date de fin (ISO 8601)
 */
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
            .limit(parseInt(limit))
            .lean();

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
        });
    }
});

// --- Statistiques et revenus ---

/**
 * GET /api/workers/stats
 * Retourne les statistiques du déneigeur (aujourd'hui, semaine, mois, global).
 * Inclut les jobs complétés, revenus, pourboires et note moyenne.
 */
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
        });
    }
});

/**
 * GET /api/workers/earnings
 * Retourne le détail des revenus avec ventilation quotidienne.
 * @param {string} [req.query.period='week'] - Période (day, week, month, year)
 */
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
        });
    }
});

// --- Profil du déneigeur ---

/**
 * GET /api/workers/profile
 * Retourne le profil complet du déneigeur (infos personnelles + workerProfile).
 */
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
        });
    }
});

/**
 * PUT /api/workers/profile
 * Met à jour le profil du déneigeur (zones, équipement, préférences).
 * @param {string[]} [req.body.preferredZones] - Zones de travail préférées
 * @param {string[]} [req.body.equipmentList] - Liste d'équipement
 * @param {string} [req.body.vehicleType] - Type de véhicule
 * @param {number} [req.body.maxActiveJobs] - Nombre max de jobs actifs
 */
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
        });
    }
});

/**
 * POST /api/workers/profile/photo
 * Téléverse une photo de profil du déneigeur vers Cloudinary.
 * @param {File} req.file - Fichier image (champ 'photo', max 5 Mo)
 */
router.post('/profile/photo', protect, authorize('snowWorker'), uploadLimiter, profileUpload.single('photo'), async (req, res) => {
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
        });
    }
});

// --- Actions sur les jobs ---

/**
 * POST /api/workers/jobs/:id/accept
 * Accepte un job et assigne le déneigeur. Notifie le client via push intelligent.
 * Vérifie la limite de jobs actifs.
 */
router.post('/jobs/:id/accept', protect, authorize('snowWorker'), verificationRequired, async (req, res) => {
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

        // Envoyer notification push intelligente
        await smartNotifications.notifyWorkerAssigned(reservation._id);

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
        });
    }
});

/**
 * PATCH /api/workers/jobs/:id/en-route
 * Indique que le déneigeur est en route vers le job. Met à jour sa position et l'ETA.
 * @param {number} [req.body.latitude] - Latitude actuelle
 * @param {number} [req.body.longitude] - Longitude actuelle
 * @param {number} [req.body.estimatedMinutes] - Temps estimé d'arrivée en minutes
 */
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

        // Envoyer notification push intelligente avec ETA
        await smartNotifications.notifyWorkerEnRoute(reservation._id);

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
        });
    }
});

/**
 * PATCH /api/workers/jobs/:id/start
 * Démarre le travail de déneigement. Passe le statut à 'inProgress'.
 */
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

        // Envoyer notifications push intelligentes (arrivé + travail commencé)
        await smartNotifications.notifyWorkerArrived(reservation._id);
        await smartNotifications.notifyJobStarted(reservation._id);

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
        });
    }
});

/**
 * PATCH /api/workers/jobs/:id/complete
 * Termine le job, exige une photo 'after', déclenche le paiement automatique via Stripe Connect.
 * @param {string} [req.body.workerNotes] - Notes du déneigeur sur le travail
 */
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

        // Envoyer notification push intelligente avec durée réelle
        const actualDuration = reservation.startedAt
            ? Math.round((reservation.completedAt - reservation.startedAt) / 60000)
            : null;
        await smartNotifications.notifyJobCompleted(reservation._id, actualDuration);

        console.log(`✅ Job ${reservation._id} completed by worker ${worker.firstName}`);

        // ============================================
        // PAYOUT AUTOMATIQUE AU DÉNEIGEUR
        // ============================================
        const workerConnectId = worker?.workerProfile?.stripeConnectId;
        const isPaid = reservation.paymentStatus === 'paid' || reservation.paymentIntentId;
        const payoutNotDone = reservation.payout?.status !== 'paid';

        if (workerConnectId && isPaid && payoutNotDone) {
            try {
                const grossAmount = reservation.totalPrice;
                const platformFee = grossAmount * PLATFORM_FEE_PERCENT;
                const workerAmount = grossAmount * WORKER_PERCENT;

                // Créer le transfert vers le compte Connect du déneigeur
                const transfer = await stripe.transfers.create(
                    {
                        amount: Math.round(workerAmount * 100), // En cents
                        currency: 'cad',
                        destination: workerConnectId,
                        description: `Paiement pour réservation #${reservation._id}`,
                        metadata: {
                            reservationId: reservation._id.toString(),
                            workerId: worker._id.toString(),
                            clientId: reservation.userId._id.toString(),
                        },
                    },
                    {
                        idempotencyKey: `payout_job_${reservation._id}`, // Empêche les doubles paiements
                    }
                );

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
        });
    }
});

// --- Photos de jobs ---

/**
 * POST /api/workers/jobs/:id/photos/upload
 * Téléverse une photo avant/après vers Cloudinary pour un job en cours.
 * @param {string} req.body.type - Type de photo ('before' ou 'after')
 * @param {File} req.file - Fichier image (champ 'photo')
 */
router.post('/jobs/:id/photos/upload', protect, authorize('snowWorker'), uploadLimiter, upload.single('photo'), async (req, res) => {
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
        });
    }
});

/**
 * POST /api/workers/jobs/:id/photos
 * Ajoute une photo avant/après via URL (version héritée).
 * @param {string} req.body.type - Type de photo ('before' ou 'after')
 * @param {string} req.body.photoUrl - URL de la photo
 */
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
        });
    }
});

// --- Vérification d'identité ---

// Configure multer for verification documents
const verificationUpload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB max per document
    },
    fileFilter: function (req, file, cb) {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Seules les images sont acceptées'), false);
        }
    }
});

/**
 * GET /api/workers/verification/status
 * Retourne le statut de vérification d'identité du déneigeur.
 * Inclut les résultats d'analyse IA et le nombre de tentatives restantes.
 */
router.get('/verification/status', protect, authorize('snowWorker'), async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        const verification = user.workerProfile?.identityVerification || {};

        // Check if can resubmit
        const resubmitInfo = await identityVerificationService.canResubmit(req.user.id);

        res.json({
            success: true,
            data: {
                status: verification.status || 'not_submitted',
                submittedAt: verification.submittedAt || null,
                verifiedAt: verification.verifiedAt || null,
                expiresAt: verification.expiresAt || null,
                decision: verification.decision ? {
                    result: verification.decision.result,
                    reason: verification.decision.reason,
                    decidedAt: verification.decision.decidedAt,
                } : null,
                aiAnalysis: verification.aiAnalysis ? {
                    overallScore: verification.aiAnalysis.overallScore,
                    issues: verification.aiAnalysis.issues,
                } : null,
                canResubmit: resubmitInfo.canResubmit,
                attemptsRemaining: resubmitInfo.attemptsRemaining,
            },
        });
    } catch (error) {
        console.error('Error getting verification status:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération du statut de vérification',
        });
    }
});

/**
 * POST /api/workers/verification/submit
 * Soumet les documents d'identité (recto, verso, selfie) pour vérification.
 * Déclenche l'analyse IA en arrière-plan.
 */
router.post(
    '/verification/submit',
    protect,
    authorize('snowWorker'),
    uploadLimiter,
    verificationUpload.fields([
        { name: 'idFront', maxCount: 1 },
        { name: 'idBack', maxCount: 1 },
        { name: 'selfie', maxCount: 1 },
    ]),
    async (req, res) => {
        try {
            const user = await User.findById(req.user.id);
            const verification = user.workerProfile?.identityVerification;

            // Check if can submit
            if (verification?.status === 'pending') {
                return res.status(400).json({
                    success: false,
                    message: 'Une vérification est déjà en cours',
                });
            }

            if (verification?.status === 'approved') {
                return res.status(400).json({
                    success: false,
                    message: 'Votre identité est déjà vérifiée',
                });
            }

            // Check attempts
            const resubmitInfo = await identityVerificationService.canResubmit(req.user.id);
            if (!resubmitInfo.canResubmit && verification?.status === 'rejected') {
                return res.status(400).json({
                    success: false,
                    message: resubmitInfo.reason,
                });
            }

            // Validate required files
            if (!req.files?.idFront?.[0] || !req.files?.selfie?.[0]) {
                return res.status(400).json({
                    success: false,
                    message: 'La pièce d\'identité (recto) et le selfie sont requis',
                });
            }

            // Upload documents to Cloudinary
            const uploadPromises = [];
            const documents = {};

            // ID Front
            const idFrontResult = await uploadFromBuffer(
                req.files.idFront[0].buffer,
                `deneige-auto/verification/${req.user.id}`,
                `id-front-${Date.now()}`
            );
            if (idFrontResult.success) {
                documents.idFront = {
                    url: idFrontResult.url,
                    publicId: idFrontResult.publicId,
                    uploadedAt: new Date(),
                };
            }

            // ID Back (optional)
            if (req.files?.idBack?.[0]) {
                const idBackResult = await uploadFromBuffer(
                    req.files.idBack[0].buffer,
                    `deneige-auto/verification/${req.user.id}`,
                    `id-back-${Date.now()}`
                );
                if (idBackResult.success) {
                    documents.idBack = {
                        url: idBackResult.url,
                        publicId: idBackResult.publicId,
                        uploadedAt: new Date(),
                    };
                }
            }

            // Selfie
            const selfieResult = await uploadFromBuffer(
                req.files.selfie[0].buffer,
                `deneige-auto/verification/${req.user.id}`,
                `selfie-${Date.now()}`
            );
            if (selfieResult.success) {
                documents.selfie = {
                    url: selfieResult.url,
                    publicId: selfieResult.publicId,
                    uploadedAt: new Date(),
                };
            }

            // Update user with documents
            const attemptsCount = (verification?.attemptsCount || 0) + 1;
            await User.findByIdAndUpdate(req.user.id, {
                $set: {
                    'workerProfile.identityVerification.documents': documents,
                    'workerProfile.identityVerification.status': 'pending',
                    'workerProfile.identityVerification.submittedAt': new Date(),
                    'workerProfile.identityVerification.attemptsCount': attemptsCount,
                },
            });

            // Trigger AI analysis (async - don't wait)
            identityVerificationService.analyzeIdentityDocuments(req.user.id)
                .then(result => {
                    console.log(`✅ Identity verification analyzed for user ${req.user.id}: ${result.status}`);
                })
                .catch(err => {
                    console.error(`❌ Error analyzing identity for user ${req.user.id}:`, err.message);
                });

            res.json({
                success: true,
                message: 'Documents soumis avec succès. Vérification en cours...',
                data: {
                    status: 'pending',
                    submittedAt: new Date(),
                    attemptsCount,
                },
            });
        } catch (error) {
            console.error('Error submitting verification:', error);
            res.status(500).json({
                success: false,
                message: 'Erreur lors de la soumission des documents',
            });
        }
    }
);

module.exports = router;
