/**
 * Routes de gestion des réservations de déneigement.
 * Inclut la création, modification, annulation, notation, pourboire et paiement.
 * @module routes/reservations
 */

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Reservation = require('../models/Reservation');
const { notifyNearbyWorkers } = require('../services/dispatchService');
const Notification = require('../models/Notification');
const User = require('../models/User');
const Vehicle = require('../models/Vehicle');
const ParkingSpot = require('../models/ParkingSpot');
const { minimumTotal } = require('../services/pricingService');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { recordPaidTip } = require('../services/payoutService');
const { PLATFORM_FEE_PERCENT, WORKER_PERCENT, CANCELLATION_POLICY } = require('../config/constants');
const { safeNotify } = require('../utils/errorHandler');

// --- Liste et détails des réservations ---

/**
 * GET /api/reservations
 * Retourne les réservations de l'utilisateur avec pagination et filtres optionnels.
 * @param {string} [req.query.upcoming] - Filtrer les réservations à venir ('true')
 * @param {string} [req.query.status] - Filtrer par statut
 * @param {number} [req.query.page=1] - Numéro de page
 * @param {number} [req.query.limit=20] - Nombre par page (max 100)
 * @returns {Object} Liste paginée de réservations
 */
router.get('/', protect, async (req, res) => {
    try {
        const { upcoming, status, page = 1, limit = 20 } = req.query;
        const pageNum = Math.max(1, parseInt(page));
        const limitNum = Math.min(100, Math.max(1, parseInt(limit)));
        const skip = (pageNum - 1) * limitNum;

        const query = { userId: req.user.id };

        if (upcoming === 'true') {
            query.status = { $in: ['pending', 'assigned', 'enRoute', 'inProgress'] };
            query.departureTime = { $gte: new Date() };
        }

        if (status) {
            query.status = status;
        }

        const [reservations, total] = await Promise.all([
            Reservation.find(query)
                .populate('vehicle')
                .populate('parkingSpot')
                .populate('workerId', 'firstName lastName phoneNumber photoUrl workerProfile.identityVerification.status')
                .sort({ departureTime: -1 })
                .skip(skip)
                .limit(limitNum)
                .lean(),
            Reservation.countDocuments(query),
        ]);

        res.status(200).json({
            success: true,
            count: reservations.length,
            total,
            page: pageNum,
            pages: Math.ceil(total / limitNum),
            reservations,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des réservations:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des réservations',
        });
    }
});

/**
 * GET /api/reservations/:id
 * Retourne le détail d'une réservation par son ID (avec véhicule, place et déneigeur).
 */
router.get('/:id', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOne({
            _id: req.params.id,
            userId: req.user.id,
        })
            .populate('vehicle')
            .populate('parkingSpot')
            .populate('workerId', 'firstName lastName phoneNumber photoUrl workerProfile.identityVerification.status')
            .lean();

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        res.status(200).json({
            success: true,
            reservation,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération de la réservation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de la réservation',
        });
    }
});

// --- Création de réservation ---

/**
 * Rembourse un paiement Stripe qui n'a pas abouti a une reservation (la
 * carte est debitee avant la creation). Ne rembourse que si le paiement
 * appartient au client, a reussi, et n'est rattache a aucune reservation.
 * @returns {Promise<boolean>} true si le remboursement a ete emis
 */
const refundOrphanPayment = async (paymentIntentId, userId) => {
    if (!paymentIntentId) return false;
    try {
        if (await Reservation.exists({ paymentIntentId })) return false;
        const intent = await stripe.paymentIntents.retrieve(paymentIntentId);
        if (intent.status !== 'succeeded' || intent.metadata?.userId !== String(userId)) {
            return false;
        }
        await stripe.refunds.create(
            { payment_intent: paymentIntentId, reason: 'requested_by_customer' },
            { idempotencyKey: `orphan_refund_${paymentIntentId}` },
        );
        console.warn('💸 Paiement rembourse (reservation non creee):', paymentIntentId);
        return true;
    } catch (refundError) {
        console.error('❌ Remboursement automatique impossible:', paymentIntentId, refundError.message);
        return false;
    }
};

/**
 * Verifie aupres de Stripe qu'un paiement est reel, reussi, au nom du client,
 * pas deja utilise, et qu'il couvre le prix de la reservation.
 * @returns {Promise<{ok: true} | {ok: false, status: number, code: string, message: string}>}
 */
const verifyPayment = async (paymentIntentId, userId, totalPrice) => {
    const refuse = (code, message) => ({ ok: false, status: 402, code, message });

    let intent;
    try {
        intent = await stripe.paymentIntents.retrieve(paymentIntentId);
    } catch (error) {
        return refuse('PAYMENT_NOT_FOUND', 'Paiement introuvable.');
    }
    if (intent.metadata?.userId !== String(userId)) {
        return refuse('PAYMENT_NOT_OWNED', 'Ce paiement ne correspond pas à votre compte.');
    }
    if (intent.status !== 'succeeded') {
        return refuse('PAYMENT_NOT_COMPLETED', 'Le paiement n’a pas été complété.');
    }
    if (intent.metadata?.type === 'tip') {
        return refuse('PAYMENT_NOT_OWNED', 'Ce paiement ne correspond pas à une réservation.');
    }
    if (await Reservation.exists({ $or: [{ paymentIntentId }, { tipPaymentIntentId: paymentIntentId }] })) {
        return refuse('PAYMENT_ALREADY_USED', 'Ce paiement a déjà servi pour une autre réservation.');
    }
    // 1 cent de tolerance pour les arrondis
    const received = intent.amount_received ?? intent.amount ?? 0;
    if (received < Math.round(totalPrice * 100) - 1) {
        return refuse('PAYMENT_AMOUNT_MISMATCH', 'Le montant payé ne correspond pas au prix de la réservation.');
    }
    return { ok: true };
};

/** Reponse d'echec de creation, avec remboursement si le client a deja paye. */
const failCreation = async (res, req, status, message, code) => {
    const refunded = await refundOrphanPayment(req.body.paymentIntentId, req.user.id);
    return res.status(status).json({
        success: false,
        code,
        refunded,
        message: refunded
            ? `${message} Votre paiement a été remboursé automatiquement.`
            : message,
    });
};

/**
 * POST /api/reservations
 * Crée une nouvelle réservation de déneigement avec localisation GPS obligatoire.
 * Gère les places de parking manuelles, personnalisées et par référence.
 * @param {string} req.body.vehicleId - ID du véhicule
 * @param {string} req.body.departureTime - Heure de départ (ISO 8601)
 * @param {string} req.body.deadlineTime - Heure limite (ISO 8601)
 * @param {number} req.body.latitude - Latitude GPS (obligatoire)
 * @param {number} req.body.longitude - Longitude GPS (obligatoire)
 * @param {number} req.body.totalPrice - Prix total
 * @returns {Object} Réservation créée avec détails
 */
router.post('/', protect, async (req, res) => {
    try {
        const {
            vehicleId,
            parkingSpotId,
            parkingSpotNumber, // ✅ Ajouté ici
            customLocation,
            departureTime,
            deadlineTime,
            serviceOptions,
            snowDepthCm,
            totalPrice,
            paymentMethod,
            paymentIntentId, // ✅ ID du paiement Stripe
            // Localisation GPS pour le système déneigeur
            latitude,
            longitude,
            address,
        } = req.body;

        console.log('📝 Nouvelle réservation:', {
            userId: req.user.id,
            vehicleId,
            parkingSpotId,
            parkingSpotNumber,
            customLocation,
            departureTime,
            totalPrice,
            paymentIntentId,
        });

        // ✅ Gérer les différents cas de place de parking
        let finalParkingSpotId = null;
        let finalParkingSpotNumber = null;
        let finalCustomLocation = null;

        if (parkingSpotId && parkingSpotId.startsWith('manual-')) {
            // Place manuelle avec numéro
            finalParkingSpotNumber = parkingSpotId.replace('manual-', '');
            console.log('✅ Place manuelle:', finalParkingSpotNumber);
        } else if (parkingSpotId && parkingSpotId.startsWith('custom-')) {
            // Emplacement personnalisé
            finalCustomLocation = parkingSpotId.replace('custom-', '');
            console.log('✅ Emplacement personnalisé:', finalCustomLocation);
        } else if (parkingSpotId) {
            // ID de place valide
            finalParkingSpotId = parkingSpotId;
            console.log('✅ Place de parking ID:', finalParkingSpotId);
        } else if (parkingSpotNumber) {
            // Numéro fourni directement
            finalParkingSpotNumber = parkingSpotNumber;
            console.log('✅ Numéro de place fourni:', parkingSpotNumber);
        } else if (customLocation) {
            // Emplacement fourni directement
            finalCustomLocation = customLocation;
            console.log('✅ Emplacement fourni:', customLocation);
        }

        // Vérifier que les coordonnées GPS sont fournies (OBLIGATOIRE)
        if (!latitude || !longitude) {
            return failCreation(res, req, 400,
                'La localisation GPS est requise pour créer une réservation.', 'LOCATION_REQUIRED');
        }

        // Le vehicule doit appartenir au client (il fixe aussi le prix plancher)
        const vehicle = vehicleId
            ? await Vehicle.findOne({ _id: vehicleId, userId: req.user.id }).lean().catch(() => null)
            : null;
        if (!vehicle) {
            return failCreation(res, req, 400, 'Véhicule introuvable.', 'VEHICLE_NOT_FOUND');
        }

        // Le prix vient de l'application : on refuse un montant sous le plancher
        const parkingSpotDoc = finalParkingSpotId
            ? await ParkingSpot.findById(finalParkingSpotId).lean().catch(() => null)
            : null;
        const floor = minimumTotal({
            vehicleType: vehicle.type,
            parkingLevel: parkingSpotDoc?.level,
            snowDepthCm,
            serviceOptions,
        });
        if (!(Number(totalPrice) >= floor)) {
            return failCreation(res, req, 400,
                'Le prix de la réservation est invalide. Recommencez la réservation.', 'INVALID_PRICE');
        }

        // Une reservation n'est "payee" que si Stripe le confirme
        if (paymentIntentId) {
            const payment = await verifyPayment(paymentIntentId, req.user.id, Number(totalPrice));
            if (!payment.ok) {
                return failCreation(res, req, payment.status, payment.message, payment.code);
            }
        }

        // Construire l'objet location GeoJSON
        const locationData = {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)], // GeoJSON: [lng, lat]
            address: address || finalCustomLocation || 'Adresse non spécifiée',
        };

        const reservation = await Reservation.create({
            userId: req.user.id,
            vehicle: vehicleId,
            parkingSpot: finalParkingSpotId,
            parkingSpotNumber: finalParkingSpotNumber,
            customLocation: finalCustomLocation,
            departureTime: new Date(departureTime),
            deadlineTime: new Date(deadlineTime),
            serviceOptions: serviceOptions || [],
            snowDepthCm,
            basePrice: totalPrice,
            totalPrice,
            paymentMethod,
            paymentIntentId: paymentIntentId || null,
            paymentStatus: paymentIntentId ? 'paid' : 'pending',
            // Localisation GPS (obligatoire)
            location: locationData,
        });

        // ✅ IMPORTANT: Populer les relations avant de renvoyer
        await reservation.populate('vehicle');
        if (finalParkingSpotId) {
            await reservation.populate('parkingSpot');
        }

        console.log('✅ Réservation créée avec succès:', reservation._id);

        // Prevenir les deneigeurs proches, sans retarder la reponse au client
        if (reservation.paymentStatus === 'paid') {
            notifyNearbyWorkers(reservation).catch((err) =>
                console.error('⚠️ Notification des déneigeurs échouée:', err.message));
        }

        // ✅ Créer l'ID de parking avec le numéro/emplacement pour l'édition future
        const manualSpotId = finalCustomLocation
            ? `custom-${finalCustomLocation}`
            : finalParkingSpotNumber
                ? `manual-${finalParkingSpotNumber}`
                : 'manual';

        res.status(201).json({
            success: true,
            reservation: {
                id: reservation._id.toString(),
                userId: reservation.userId.toString(),
                workerId: reservation.workerId?.toString(),
                vehicle: reservation.vehicle, // ✅ Déjà populé
                parkingSpot: reservation.parkingSpot || {
                    // ✅ Créer un objet factice si place manuelle (avec ID complet)
                    id: manualSpotId,
                    spotNumber: finalParkingSpotNumber || finalCustomLocation || 'N/A',
                    level: 'outdoor',
                    displayName: finalParkingSpotNumber || finalCustomLocation || 'N/A',
                    fullDisplayName: finalParkingSpotNumber || finalCustomLocation || 'N/A',
                    isAssigned: false,
                    isActive: true,
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString(),
                },
                departureTime: reservation.departureTime.toISOString(),
                deadlineTime: reservation.deadlineTime?.toISOString(),
                status: reservation.status,
                serviceOptions: reservation.serviceOptions,
                basePrice: reservation.basePrice,
                totalPrice: reservation.totalPrice,
                isPriority: reservation.isPriority,
                snowDepthCm: reservation.snowDepthCm,
                paymentMethod: reservation.paymentMethod,
                paymentStatus: reservation.paymentStatus,
                createdAt: reservation.createdAt.toISOString(),
            },
            message: 'Réservation créée avec succès',
        });
    } catch (error) {
        console.error('❌ Erreur lors de la création de la réservation:', error);
        return failCreation(res, req, 500,
            'La réservation n’a pas pu être enregistrée.', 'CREATION_FAILED');
    }
});

// --- Modification de réservation ---

/** Delai minimum avant le depart, comme dans l'application. */
const MIN_LEAD_MINUTES = 60;

/**
 * Ce qui determine le prix d'une reservation (hors neige, non modifiable) :
 * deux signatures differentes = deux prix differents.
 */
const priceSignature = ({ vehicle, parkingSpotDoc, serviceOptions }) => {
    const { PRICING } = require('../config/constants');
    const vehicleFactor = PRICING.VEHICLE_FACTORS[vehicle?.type] ?? 'other';
    const parkingFactor = parkingSpotDoc ? (PRICING.PARKING_FACTORS[parkingSpotDoc.level] ?? 'other') : 1;
    const options = [...(serviceOptions || [])].sort().join(',');
    return `${vehicleFactor}|${parkingFactor}|${options}`;
};

/**
 * PUT /api/reservations/:id
 * Met à jour une réservation existante (véhicule, place de parking, localisation).
 * Mappe les champs du frontend vers le schéma backend.
 */
router.put('/:id', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOne({ _id: req.params.id, userId: req.user.id })
            .populate('vehicle')
            .populate('parkingSpot');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Une fois un deneigeur assigne, la reservation est figee
        if (reservation.status !== 'pending') {
            return res.status(409).json({
                success: false,
                code: 'NOT_EDITABLE',
                message: 'Cette réservation ne peut plus être modifiée : un déneigeur l’a déjà acceptée.',
            });
        }

        // Seuls ces champs sont modifiables ; prix, statut, paiement et
        // deneigeur ne viennent jamais du client.
        const {
            vehicleId,
            parkingSpotId,
            parkingSpotNumber,
            departureTime,
            deadlineTime,
            serviceOptions,
            latitude,
            longitude,
            address,
        } = req.body;

        const next = {
            vehicle: reservation.vehicle,
            parkingSpotDoc: reservation.parkingSpot,
            serviceOptions: Array.isArray(serviceOptions) ? serviceOptions : reservation.serviceOptions,
        };

        if (vehicleId && String(vehicleId) !== String(reservation.vehicle?._id)) {
            next.vehicle = await Vehicle.findOne({ _id: vehicleId, userId: req.user.id }).catch(() => null);
            if (!next.vehicle) {
                return res.status(400).json({ success: false, code: 'VEHICLE_NOT_FOUND', message: 'Véhicule introuvable.' });
            }
        }

        // Place de parking : memes formats qu'a la creation
        let parkingUpdate = null;
        if (parkingSpotId) {
            if (parkingSpotId === 'manual' || parkingSpotId.startsWith('manual-')) {
                parkingUpdate = {
                    parkingSpot: null,
                    parkingSpotNumber: parkingSpotId === 'manual' ? parkingSpotNumber : parkingSpotId.replace('manual-', ''),
                    customLocation: null,
                };
                next.parkingSpotDoc = null;
            } else if (parkingSpotId.startsWith('custom-')) {
                parkingUpdate = { parkingSpot: null, parkingSpotNumber: null, customLocation: parkingSpotId.replace('custom-', '') };
                next.parkingSpotDoc = null;
            } else if (parkingSpotId.length === 24) {
                next.parkingSpotDoc = await ParkingSpot.findById(parkingSpotId).lean().catch(() => null);
                if (!next.parkingSpotDoc) {
                    return res.status(400).json({ success: false, code: 'PARKING_NOT_FOUND', message: 'Place introuvable.' });
                }
                parkingUpdate = { parkingSpot: parkingSpotId, parkingSpotNumber: null, customLocation: null };
            }
        }

        // Le prix paye ne change pas : on refuse ce qui le modifierait
        if (priceSignature(next) !== priceSignature({
            vehicle: reservation.vehicle,
            parkingSpotDoc: reservation.parkingSpot,
            serviceOptions: reservation.serviceOptions,
        })) {
            return res.status(409).json({
                success: false,
                code: 'PRICE_CHANGE_NOT_ALLOWED',
                message: 'Ce changement modifierait le prix payé. Annulez cette réservation et créez-en une nouvelle.',
            });
        }

        if (departureTime) {
            const departure = new Date(departureTime);
            const earliest = Date.now() + MIN_LEAD_MINUTES * 60 * 1000;
            if (Number.isNaN(departure.getTime()) || departure.getTime() < earliest) {
                return res.status(400).json({
                    success: false,
                    code: 'INVALID_DEPARTURE',
                    message: `Le départ doit être dans au moins ${MIN_LEAD_MINUTES} minutes.`,
                });
            }
            reservation.departureTime = departure;
            reservation.deadlineTime = deadlineTime
                ? new Date(deadlineTime)
                : new Date(departure.getTime() - 30 * 60 * 1000);
        }

        reservation.vehicle = next.vehicle._id;
        reservation.serviceOptions = next.serviceOptions;
        if (parkingUpdate) Object.assign(reservation, parkingUpdate);
        if (latitude && longitude) {
            reservation.location = {
                type: 'Point',
                coordinates: [parseFloat(longitude), parseFloat(latitude)],
                address: address || reservation.location?.address || 'Adresse mise à jour',
            };
        }

        // save() (et non findOneAndUpdate) : l'equipement requis est recalcule
        await reservation.save();
        await reservation.populate(['vehicle', 'parkingSpot', 'workerId']);

        // ✅ Formater la réponse avec parkingSpot factice si place manuelle
        const responseReservation = reservation.toObject();
        if (!responseReservation.parkingSpot && (responseReservation.parkingSpotNumber || responseReservation.customLocation)) {
            const spotNumber = responseReservation.parkingSpotNumber || responseReservation.customLocation || 'N/A';
            const spotId = responseReservation.customLocation
                ? `custom-${spotNumber}`
                : `manual-${spotNumber}`;
            responseReservation.parkingSpot = {
                id: spotId,
                spotNumber: spotNumber,
                level: 'outdoor',
                displayName: spotNumber,
                fullDisplayName: spotNumber,
                isAssigned: false,
                isActive: true,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString(),
            };
        }

        res.status(200).json({
            success: true,
            reservation: responseReservation,
            message: 'Réservation mise à jour avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de la réservation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour de la réservation',
        });
    }
});

// --- Annulation simple ---

/**
 * DELETE /api/reservations/:id
 * Annule une réservation (statut pending ou assigned uniquement).
 * @param {string} [req.body.reason] - Raison de l'annulation
 */
router.delete('/:id', protect, async (req, res) => {
    try {
        const { reason } = req.body;

        const reservation = await Reservation.findOneAndUpdate(
            {
                _id: req.params.id,
                userId: req.user.id,
                status: { $in: ['pending', 'assigned'] },
            },
            {
                status: 'cancelled',
                cancelledAt: new Date(),
                cancelReason: reason || 'Annulée par l\'utilisateur',
            },
            { new: true }
        );

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou ne peut pas être annulée',
            });
        }

        // Envoyer notification d'annulation
        await Notification.notifyReservationCancelled(
            reservation,
            reason || 'Annulée par l\'utilisateur'
        );

        res.status(200).json({
            success: true,
            reservation,
            message: 'Réservation annulée avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de l\'annulation de la réservation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'annulation de la réservation',
        });
    }
});

// --- Assignation et progression du travail ---

/**
 * PATCH /api/reservations/:id/assign
 * Assigne le déneigeur authentifié à une réservation (mise à jour atomique).
 * Vérifie la limite de jobs actifs du déneigeur.
 */
router.patch('/:id/assign', protect, async (req, res) => {
    try {
        // Vérifier que le worker n'a pas trop de jobs actifs
        const activeJobsCount = await Reservation.countDocuments({
            workerId: req.user.id,
            status: { $in: ['assigned', 'enRoute', 'inProgress'] },
        });

        const worker = await User.findById(req.user.id);
        const maxActiveJobs = worker?.workerProfile?.maxActiveJobs || 3;

        if (activeJobsCount >= maxActiveJobs) {
            return res.status(400).json({
                success: false,
                message: `Vous avez déjà ${maxActiveJobs} jobs actifs. Complétez-en un avant d'en accepter un nouveau.`,
            });
        }

        // Atomic update: seulement si le job est pending et non assigné
        const reservation = await Reservation.findOneAndUpdate(
            {
                _id: req.params.id,
                status: 'pending',
                workerId: null, // Empêche la double assignation
            },
            {
                workerId: req.user.id,
                status: 'assigned',
                assignedAt: new Date(),
            },
            { new: true }
        ).populate('userId', 'firstName lastName');

        if (!reservation) {
            // Vérifier si le job existe mais est déjà pris
            const existingJob = await Reservation.findById(req.params.id);
            if (existingJob && existingJob.workerId) {
                return res.status(409).json({
                    success: false,
                    message: 'Ce job a déjà été accepté par un autre déneigeur',
                });
            }
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou non disponible',
            });
        }

        // Envoyer notification au client
        await Notification.notifyReservationAssigned(reservation, req.user);

        res.status(200).json({
            success: true,
            reservation,
            message: 'Réservation assignée avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de l\'assignation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'assignation',
        });
    }
});

/**
 * PATCH /api/reservations/:id/en-route
 * Notifie le client que le déneigeur est en route.
 */
router.patch('/:id/en-route', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOne({
            _id: req.params.id,
            workerId: req.user.id,
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Envoyer notification au client
        await Notification.notifyWorkerEnRoute(reservation, req.user);

        res.status(200).json({
            success: true,
            message: 'Notification envoyée',
        });
    } catch (error) {
        console.error('Erreur:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi de la notification',
        });
    }
});

/**
 * PATCH /api/reservations/:id/start
 * Passe la réservation au statut 'inProgress' et notifie le client.
 */
router.patch('/:id/start', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOneAndUpdate(
            {
                _id: req.params.id,
                workerId: req.user.id,
            },
            {
                status: 'inProgress',
            },
            { new: true }
        );

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Envoyer notification au client
        await Notification.notifyWorkStarted(reservation, req.user);

        res.status(200).json({
            success: true,
            reservation,
            message: 'Travail démarré',
        });
    } catch (error) {
        console.error('Erreur:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du démarrage',
        });
    }
});

// --- Complétion et paiement ---
// La fin d'un deneigement passe par PATCH /api/workers/jobs/:id/complete
// (photo obligatoire, versement via services/payoutService).

/**
 * POST /api/reservations/create-intent
 * Crée un Payment Intent Stripe pour le paiement d'une réservation.
 * @param {number} req.body.amount - Montant en dollars CAD
 * @returns {Object} clientSecret et paymentIntentId
 */
router.post('/create-intent', protect, async (req, res) => {
    try {
        const { amount } = req.body; // Montant en dollars

        const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(amount * 100), // Stripe utilise les cents
            currency: 'cad',
            metadata: {
                userId: req.user.id,
            },
        });

        res.status(200).json({
            success: true,
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
        });
    } catch (error) {
        console.error('Erreur Stripe:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du traitement du paiement',
        });
    }
});

// --- Logique métier d'annulation ---

// Raisons valables d'annulation pour les déneigeurs
const VALID_WORKER_CANCELLATION_REASONS = [
    'vehicle_breakdown',      // Panne de véhicule
    'medical_emergency',      // Urgence médicale
    'severe_weather',         // Conditions météo dangereuses
    'road_blocked',           // Route bloquée/inaccessible
    'family_emergency',       // Urgence familiale
    'equipment_failure',      // Équipement défaillant
    'other',                  // Autre (nécessite description)
];

/**
 * PATCH /api/reservations/:id/cancel-by-worker
 * Annulation par le déneigeur avec suivi des avertissements et pénalités.
 * Requiert une raison valable. Limite de 3 annulations avant suspension.
 * @param {string} req.body.reason - Code de raison (ex: vehicle_breakdown, medical_emergency)
 * @param {string} [req.body.details] - Détails supplémentaires
 */
router.patch('/:id/cancel-by-worker', protect, async (req, res) => {
    try {
        const { reason, reasonCode, description } = req.body;

        // Vérifier que l'utilisateur est un déneigeur
        if (req.user.role !== 'snowWorker') {
            return res.status(403).json({
                success: false,
                message: 'Seuls les déneigeurs peuvent utiliser cette fonctionnalité',
            });
        }

        // Vérifier si le déneigeur est suspendu
        const worker = await User.findById(req.user.id);
        if (worker.workerProfile?.isSuspended) {
            const suspendedUntil = worker.workerProfile.suspendedUntil;
            if (suspendedUntil && new Date() < suspendedUntil) {
                return res.status(403).json({
                    success: false,
                    message: `Votre compte est suspendu jusqu'au ${suspendedUntil.toLocaleDateString('fr-CA')}`,
                    suspendedUntil,
                });
            }
            // Lever la suspension si elle est expirée
            worker.workerProfile.isSuspended = false;
            worker.workerProfile.suspendedUntil = null;
            worker.workerProfile.suspensionReason = null;
            await worker.save();
        }

        // Valider la raison
        if (!reasonCode || !VALID_WORKER_CANCELLATION_REASONS.includes(reasonCode)) {
            return res.status(400).json({
                success: false,
                message: 'Une raison valable est requise pour annuler',
                validReasons: VALID_WORKER_CANCELLATION_REASONS,
            });
        }

        if (reasonCode === 'other' && (!description || description.length < 10)) {
            return res.status(400).json({
                success: false,
                message: 'Veuillez fournir une description détaillée (minimum 10 caractères)',
            });
        }

        // Trouver la réservation assignée à ce déneigeur
        const reservation = await Reservation.findOne({
            _id: req.params.id,
            workerId: req.user.id,
            status: { $in: ['assigned', 'enRoute', 'inProgress'] },
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou vous n\'êtes pas assigné à cette tâche',
            });
        }

        const fullReason = reasonCode === 'other'
            ? `${reason || 'Autre raison'}: ${description}`
            : reason || reasonCode;

        // Mettre à jour la réservation
        reservation.status = 'cancelled';
        reservation.cancelledAt = new Date();
        reservation.cancelledBy = 'worker';
        reservation.cancelReason = fullReason;
        reservation.workerId = null; // Libérer la réservation pour un autre déneigeur

        // Réinitialiser pour permettre une nouvelle assignation
        reservation.assignedAt = null;
        reservation.workerEnRouteAt = null;
        reservation.startedAt = null;

        await reservation.save();

        // Mettre à jour le profil du déneigeur
        worker.workerProfile.totalCancellations = (worker.workerProfile.totalCancellations || 0) + 1;
        worker.workerProfile.cancellationHistory = worker.workerProfile.cancellationHistory || [];
        worker.workerProfile.cancellationHistory.push({
            reservationId: reservation._id,
            reason: fullReason,
            cancelledAt: new Date(),
        });

        // Calculer les conséquences
        let consequence = null;
        const totalCancellations = worker.workerProfile.totalCancellations;

        if (totalCancellations >= CANCELLATION_POLICY.SUSPENSION_THRESHOLD) {
            // Suspension
            const suspendedUntil = new Date();
            suspendedUntil.setDate(suspendedUntil.getDate() + CANCELLATION_POLICY.SUSPENSION_DAYS);

            worker.workerProfile.isSuspended = true;
            worker.workerProfile.suspendedUntil = suspendedUntil;
            worker.workerProfile.suspensionReason = `Trop d'annulations (${totalCancellations})`;
            worker.workerProfile.warningCount = 0; // Reset après suspension

            consequence = {
                type: 'suspension',
                message: `Votre compte a été suspendu pour ${CANCELLATION_POLICY.SUSPENSION_DAYS} jours en raison de trop d'annulations`,
                suspendedUntil,
            };
        } else if (totalCancellations >= CANCELLATION_POLICY.WARNING_THRESHOLD) {
            // Avertissement
            worker.workerProfile.warningCount = (worker.workerProfile.warningCount || 0) + 1;

            const remainingBeforeSuspension = CANCELLATION_POLICY.SUSPENSION_THRESHOLD - totalCancellations;
            consequence = {
                type: 'warning',
                message: `Avertissement: Vous avez ${totalCancellations} annulations. Encore ${remainingBeforeSuspension} et votre compte sera suspendu.`,
                warningCount: worker.workerProfile.warningCount,
            };
        }

        await worker.save();

        // Notifier le client
        await Notification.notifyReservationCancelled(
            reservation,
            `Annulée par le déneigeur: ${fullReason}`
        );

        // Notifier le déneigeur de la conséquence
        if (consequence) {
            await Notification.create({
                userId: worker._id,
                type: consequence.type === 'suspension' ? 'systemNotification' : 'systemNotification',
                title: consequence.type === 'suspension' ? '⚠️ Compte suspendu' : '⚠️ Avertissement',
                message: consequence.message,
                priority: 'high',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Réservation annulée. Vous ne serez pas payé pour cette tâche.',
            reservation: {
                id: reservation._id,
                status: reservation.status,
                cancelledAt: reservation.cancelledAt,
                cancelReason: reservation.cancelReason,
            },
            consequence,
            stats: {
                totalCancellations: worker.workerProfile.totalCancellations,
                warningCount: worker.workerProfile.warningCount,
                isSuspended: worker.workerProfile.isSuspended,
            },
        });

    } catch (error) {
        console.error('Erreur lors de l\'annulation par le déneigeur:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'annulation',
        });
    }
});

/**
 * PATCH /api/reservations/:id/cancel-by-client
 * Annulation par le client avec pénalités graduelles selon l'avancement du travail.
 * Gratuit si pending, pénalité croissante si assigned/enRoute/inProgress.
 * @param {string} [req.body.reason] - Raison de l'annulation
 */
router.patch('/:id/cancel-by-client', protect, async (req, res) => {
    try {
        const { reason } = req.body;

        const reservation = await Reservation.findOne({
            _id: req.params.id,
            userId: req.user.id,
            status: { $nin: ['completed', 'cancelled'] },
        }).populate('workerId', 'firstName lastName photoUrl');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou déjà terminée/annulée',
            });
        }

        const previousStatus = reservation.status;
        let cancellationFeePercent = 0;
        let cancellationFeeAmount = 0;
        let refundAmount = 0;
        let message = '';

        // Calculer les frais selon le statut
        switch (previousStatus) {
            case 'pending':
                // Pas encore assigné - remboursement complet
                cancellationFeePercent = 0;
                refundAmount = reservation.paymentStatus === 'paid' ? reservation.totalPrice : 0;
                message = 'Réservation annulée. Remboursement complet.';
                break;

            case 'assigned':
                // Assigné mais pas en route - remboursement complet
                cancellationFeePercent = 0;
                refundAmount = reservation.paymentStatus === 'paid' ? reservation.totalPrice : 0;
                message = 'Réservation annulée. Remboursement complet.';
                break;

            case 'enRoute':
                // Déneigeur en route - 50% de frais
                cancellationFeePercent = CANCELLATION_POLICY.EN_ROUTE_FEE_PERCENT;
                cancellationFeeAmount = reservation.totalPrice * (cancellationFeePercent / 100);
                refundAmount = reservation.paymentStatus === 'paid'
                    ? reservation.totalPrice - cancellationFeeAmount
                    : 0;
                message = `Réservation annulée. Le déneigeur était en route, vous êtes facturé ${cancellationFeePercent}% (${cancellationFeeAmount.toFixed(2)}$).`;
                break;

            case 'inProgress':
                // Travail en cours - 100% facturé
                cancellationFeePercent = CANCELLATION_POLICY.IN_PROGRESS_FEE_PERCENT;
                cancellationFeeAmount = reservation.totalPrice;
                refundAmount = 0;
                message = `Réservation annulée. Le travail avait commencé, vous êtes facturé ${cancellationFeePercent}% (${cancellationFeeAmount.toFixed(2)}$).`;
                break;

            default:
                return res.status(400).json({
                    success: false,
                    message: 'Cette réservation ne peut pas être annulée',
                });
        }

        // Mettre à jour la réservation
        reservation.status = 'cancelled';
        reservation.cancelledAt = new Date();
        reservation.cancelledBy = 'client';
        reservation.cancelReason = reason || 'Annulée par le client';
        reservation.cancellationFee = {
            amount: cancellationFeeAmount,
            percentage: cancellationFeePercent,
            charged: cancellationFeeAmount > 0,
            chargedAt: cancellationFeeAmount > 0 ? new Date() : null,
        };
        reservation.refundAmount = refundAmount;
        reservation.refundedAt = refundAmount > 0 ? new Date() : null;

        // Mettre à jour le statut de paiement
        if (reservation.paymentStatus === 'paid') {
            if (refundAmount === reservation.totalPrice) {
                reservation.paymentStatus = 'refunded';
            } else if (refundAmount > 0) {
                reservation.paymentStatus = 'partially_refunded';
            }
            // Si refundAmount === 0, garder 'paid' car le client paie tout
        }

        await reservation.save();

        // Traiter le remboursement via Stripe si applicable
        let stripeRefund = null;
        if (refundAmount > 0 && reservation.paymentIntentId) {
            try {
                stripeRefund = await stripe.refunds.create({
                    payment_intent: reservation.paymentIntentId,
                    amount: Math.round(refundAmount * 100), // En cents
                    reason: 'requested_by_customer',
                });
                console.log('✅ Remboursement Stripe créé:', stripeRefund.id);
            } catch (stripeError) {
                console.error('❌ Erreur remboursement Stripe:', stripeError);
                // Continuer même si le remboursement échoue (à traiter manuellement)
            }
        }

        // Payer le déneigeur si des frais sont appliqués et qu'il était assigné
        if (cancellationFeeAmount > 0 && reservation.workerId) {
            const platformFee = cancellationFeeAmount * PLATFORM_FEE_PERCENT;
            const workerAmount = cancellationFeeAmount * WORKER_PERCENT;

            reservation.payout = {
                status: 'pending',
                workerAmount,
                platformFee,
                stripeFee: 0,
            };

            // Transférer au déneigeur via Stripe Connect si configuré
            const workerId = reservation.workerId._id || reservation.workerId;
            const worker = await User.findById(workerId).select('workerProfile');

            if (worker?.workerProfile?.stripeConnectId) {
                try {
                    const transfer = await stripe.transfers.create(
                        {
                            amount: Math.round(workerAmount * 100), // En cents
                            currency: 'cad',
                            destination: worker.workerProfile.stripeConnectId,
                            description: `Compensation annulation réservation #${reservation._id}`,
                            metadata: {
                                reservationId: reservation._id.toString(),
                                workerId: workerId.toString(),
                                type: 'cancellation_compensation',
                                originalAmount: cancellationFeeAmount,
                                platformFee: platformFee,
                            },
                        },
                        {
                            idempotencyKey: `cancel_transfer_${reservation._id}`, // une seule compensation
                        }
                    );

                    reservation.payout.status = 'paid';
                    reservation.payout.stripeTransferId = transfer.id;
                    reservation.payout.processedAt = new Date();
                    console.log('✅ Compensation annulation transférée au déneigeur:', transfer.id);

                    // Mettre à jour les stats du déneigeur
                    await User.findByIdAndUpdate(workerId, {
                        $inc: {
                            'workerProfile.totalEarnings': workerAmount,
                        },
                    });
                } catch (transferError) {
                    console.error('❌ Erreur transfert compensation:', transferError.message);
                    // Le payout reste en 'pending' pour traitement manuel ultérieur
                    reservation.payout.error = transferError.message;
                }
            } else {
                console.log('⚠️ Déneigeur sans compte Stripe Connect, payout en attente');
                reservation.payout.status = 'pending_account';
            }

            await reservation.save();
        }

        // Les notifications ne doivent jamais faire echouer une annulation
        // deja enregistree (et deja remboursee)
        if (reservation.workerId) {
            await safeNotify(() => Notification.create({
                userId: reservation.workerId._id || reservation.workerId,
                type: 'reservationCancelled',
                title: '❌ Réservation annulée par le client',
                message: cancellationFeeAmount > 0
                    ? `Le client a annulé. Vous recevrez ${(cancellationFeeAmount * 0.75).toFixed(2)}$ de compensation.`
                    : 'Le client a annulé la réservation.',
                priority: 'high',
                metadata: {
                    reservationId: reservation._id,
                    cancellationFee: cancellationFeeAmount,
                    workerCompensation: cancellationFeeAmount * 0.75,
                },
            }), 'reservationCancelled:worker');
        }

        await safeNotify(() => Notification.create({
            userId: req.user.id,
            type: 'reservationCancelled',
            title: '✅ Réservation annulée',
            message: message,
            priority: 'normal',
            metadata: {
                reservationId: reservation._id,
                cancellationFee: cancellationFeeAmount,
                refundAmount,
            },
        }), 'reservationCancelled:client');

        res.status(200).json({
            success: true,
            message,
            reservation: {
                id: reservation._id,
                status: reservation.status,
                previousStatus,
                cancelledAt: reservation.cancelledAt,
                cancelReason: reservation.cancelReason,
            },
            billing: {
                originalPrice: reservation.totalPrice,
                cancellationFeePercent,
                cancellationFeeAmount,
                refundAmount,
                finalCharge: cancellationFeeAmount,
            },
            stripeRefund: stripeRefund ? {
                id: stripeRefund.id,
                status: stripeRefund.status,
            } : null,
        });

    } catch (error) {
        console.error('Erreur lors de l\'annulation par le client:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'annulation',
        });
    }
});

/**
 * GET /api/reservations/worker/cancellation-reasons
 * Retourne la liste des raisons valables d'annulation pour les déneigeurs.
 */
router.get('/worker/cancellation-reasons', protect, (req, res) => {
    const reasons = {
        vehicle_breakdown: {
            code: 'vehicle_breakdown',
            label: 'Panne de véhicule',
            description: 'Mon véhicule est en panne ou a un problème mécanique',
        },
        medical_emergency: {
            code: 'medical_emergency',
            label: 'Urgence médicale',
            description: 'J\'ai une urgence médicale personnelle',
        },
        severe_weather: {
            code: 'severe_weather',
            label: 'Conditions météo dangereuses',
            description: 'Les conditions météo rendent le trajet dangereux',
        },
        road_blocked: {
            code: 'road_blocked',
            label: 'Route bloquée',
            description: 'La route vers le client est bloquée ou inaccessible',
        },
        family_emergency: {
            code: 'family_emergency',
            label: 'Urgence familiale',
            description: 'J\'ai une urgence familiale',
        },
        equipment_failure: {
            code: 'equipment_failure',
            label: 'Équipement défaillant',
            description: 'Mon équipement de déneigement est défaillant',
        },
        other: {
            code: 'other',
            label: 'Autre raison',
            description: 'Autre raison (nécessite une description)',
            requiresDescription: true,
        },
    };

    res.json({
        success: true,
        reasons,
        policy: {
            warningThreshold: CANCELLATION_POLICY.WARNING_THRESHOLD,
            suspensionThreshold: CANCELLATION_POLICY.SUSPENSION_THRESHOLD,
            suspensionDays: CANCELLATION_POLICY.SUSPENSION_DAYS,
            note: 'Les annulations fréquentes peuvent entraîner des avertissements et une suspension temporaire.',
        },
    });
});

/**
 * GET /api/reservations/client/cancellation-policy
 * Retourne la politique d'annulation et les pénalités par statut.
 */
router.get('/client/cancellation-policy', protect, (req, res) => {
    res.json({
        success: true,
        policy: {
            pending: {
                status: 'pending',
                label: 'En attente',
                feePercent: 0,
                description: 'Remboursement complet - Aucun déneigeur assigné',
            },
            assigned: {
                status: 'assigned',
                label: 'Assignée',
                feePercent: 0,
                description: 'Remboursement complet - Déneigeur pas encore en route',
            },
            enRoute: {
                status: 'enRoute',
                label: 'En route',
                feePercent: CANCELLATION_POLICY.EN_ROUTE_FEE_PERCENT,
                description: `Frais de ${CANCELLATION_POLICY.EN_ROUTE_FEE_PERCENT}% - Le déneigeur est en route vers vous`,
            },
            inProgress: {
                status: 'inProgress',
                label: 'En cours',
                feePercent: CANCELLATION_POLICY.IN_PROGRESS_FEE_PERCENT,
                description: `Frais de ${CANCELLATION_POLICY.IN_PROGRESS_FEE_PERCENT}% - Le travail a déjà commencé`,
            },
        },
    });
});

// --- Système de notation ---

/**
 * POST /api/reservations/:id/rate
 * Permet au client de noter un déneigeur (1-5) après un job complété.
 * Met à jour la moyenne du déneigeur et envoie une notification.
 * @param {number} req.body.rating - Note de 1 à 5
 * @param {string} [req.body.review] - Commentaire optionnel
 */
router.post('/:id/rate', protect, async (req, res) => {
    try {
        const { rating, review } = req.body;
        const reservationId = req.params.id;

        // Validation de la note
        if (!rating || rating < 1 || rating > 5) {
            return res.status(400).json({
                success: false,
                message: 'La note doit être entre 1 et 5 étoiles',
            });
        }

        // Récupérer la réservation
        const reservation = await Reservation.findById(reservationId);

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Vérifier que c'est bien le client de cette réservation
        if (reservation.userId.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Vous ne pouvez noter que vos propres réservations',
            });
        }

        // Vérifier que le job est complété
        if (reservation.status !== 'completed') {
            return res.status(400).json({
                success: false,
                message: 'Vous ne pouvez noter qu\'un job complété',
            });
        }

        // Vérifier qu'il n'y a pas déjà une note
        if (reservation.rating) {
            return res.status(400).json({
                success: false,
                message: 'Vous avez déjà noté ce job',
            });
        }

        // Vérifier qu'il y a un déneigeur assigné
        if (!reservation.workerId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun déneigeur assigné à ce job',
            });
        }

        // Sauvegarder la note sur la réservation
        reservation.rating = rating;
        if (review && review.trim()) {
            reservation.review = review.trim();
        }
        reservation.ratedAt = new Date();
        await reservation.save();

        // Mettre à jour la moyenne du déneigeur
        const worker = await User.findById(reservation.workerId);
        if (worker && worker.workerProfile) {
            const currentRatingsCount = worker.workerProfile.totalRatingsCount || 0;
            const currentAverage = worker.workerProfile.averageRating || 0;

            // Calculer la nouvelle moyenne
            const newRatingsCount = currentRatingsCount + 1;
            const newAverage = ((currentAverage * currentRatingsCount) + rating) / newRatingsCount;

            // Utiliser findByIdAndUpdate pour éviter la validation complète du modèle
            await User.findByIdAndUpdate(
                reservation.workerId,
                {
                    $set: {
                        'workerProfile.totalRatingsCount': newRatingsCount,
                        'workerProfile.averageRating': Math.round(newAverage * 10) / 10,
                    },
                },
                { runValidators: false }
            );

            // Envoyer une notification au déneigeur
            await Notification.create({
                userId: worker._id,
                type: 'rating',
                title: 'Nouvelle évaluation',
                message: `Vous avez reçu une note de ${rating}/5${review ? ' avec un commentaire' : ''}.`,
                priority: 'normal',
                data: {
                    reservationId: reservation._id,
                    rating,
                    hasReview: !!review,
                },
            });

            console.log(`⭐ Nouvelle note: ${rating}/5 pour ${worker.firstName} ${worker.lastName}. Moyenne: ${worker.workerProfile.averageRating}`);
        }

        res.status(200).json({
            success: true,
            message: 'Merci pour votre évaluation !',
            rating: {
                rating,
                review: reservation.review,
                ratedAt: reservation.ratedAt,
            },
            workerNewAverage: worker?.workerProfile?.averageRating,
        });

    } catch (error) {
        console.error('Erreur lors de la notation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'enregistrement de la note',
        });
    }
});

/**
 * GET /api/reservations/:id/rating
 * Récupère la note et l'avis laissés pour une réservation.
 */
router.get('/:id/rating', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findById(req.params.id)
            .select('rating review ratedAt workerId userId')
            .populate('workerId', 'firstName lastName workerProfile.averageRating')
            .lean();

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Vérifier les permissions (client ou worker de cette réservation)
        const isClient = reservation.userId.toString() === req.user.id;
        const isWorker = reservation.workerId?._id?.toString() === req.user.id;
        const isAdmin = req.user.role === 'admin';

        if (!isClient && !isWorker && !isAdmin) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé',
            });
        }

        res.status(200).json({
            success: true,
            hasRating: !!reservation.rating,
            rating: reservation.rating,
            review: reservation.review,
            ratedAt: reservation.ratedAt,
            worker: reservation.workerId ? {
                id: reservation.workerId._id,
                name: `${reservation.workerId.firstName} ${reservation.workerId.lastName}`,
                averageRating: reservation.workerId.workerProfile?.averageRating || 0,
            } : null,
        });

    } catch (error) {
        console.error('Erreur récupération note:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de la note',
        });
    }
});

/**
 * GET /api/reservations/worker/:workerId/reviews
 * Retourne tous les avis publics d'un déneigeur avec pagination.
 */
router.get('/worker/:workerId/reviews', async (req, res) => {
    try {
        const { page = 1, limit = 10 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const [reviews, total] = await Promise.all([
            Reservation.find({
                workerId: req.params.workerId,
                rating: { $exists: true, $ne: null },
            })
                .select('rating review ratedAt userId')
                .populate('userId', 'firstName lastName')
                .sort({ ratedAt: -1 })
                .skip(skip)
                .limit(parseInt(limit))
                .lean(),
            Reservation.countDocuments({
                workerId: req.params.workerId,
                rating: { $exists: true, $ne: null },
            }),
        ]);

        // Récupérer les stats du worker
        const worker = await User.findById(req.params.workerId)
            .select('firstName lastName workerProfile.averageRating workerProfile.totalRatingsCount')
            .lean();

        res.status(200).json({
            success: true,
            worker: worker ? {
                id: worker._id,
                name: `${worker.firstName} ${worker.lastName}`,
                averageRating: worker.workerProfile?.averageRating || 0,
                totalRatings: worker.workerProfile?.totalRatingsCount || 0,
            } : null,
            reviews: reviews.map(r => ({
                rating: r.rating,
                review: r.review,
                ratedAt: r.ratedAt,
                client: r.userId ? `${r.userId.firstName} ${r.userId.lastName?.charAt(0) || ''}.` : 'Client',
            })),
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / parseInt(limit)),
            },
        });

    } catch (error) {
        console.error('Erreur récupération avis:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des avis',
        });
    }
});

// --- Pourboire ---

/**
 * Verifie qu'un client peut laisser un pourboire sur cette reservation.
 * @returns {Promise<{reservation: object} | {status: number, message: string}>}
 */
const checkTipAllowed = async (reservationId, userId, amount) => {
    const value = Number(amount);
    if (!Number.isFinite(value) || value < 1) {
        return { status: 400, message: 'Le pourboire doit être d’au moins 1 $' };
    }
    if (value > 500) {
        return { status: 400, message: 'Le pourboire ne peut pas dépasser 500 $' };
    }
    const reservation = await Reservation.findById(reservationId).catch(() => null);
    if (!reservation) return { status: 404, message: 'Réservation non trouvée' };
    if (reservation.userId.toString() !== String(userId)) {
        return { status: 403, message: 'Vous ne pouvez donner un pourboire que sur vos propres réservations' };
    }
    if (reservation.status !== 'completed') {
        return { status: 400, message: 'Vous ne pouvez donner un pourboire que sur une réservation terminée' };
    }
    if (!reservation.workerId) {
        return { status: 400, message: 'Aucun déneigeur assigné à cette réservation' };
    }
    if (reservation.tipAmount > 0 || reservation.tipPaymentIntentId) {
        return { status: 400, message: 'Un pourboire a déjà été donné pour cette réservation' };
    }
    return { reservation, amount: Math.round(value * 100) / 100 };
};

/**
 * POST /api/reservations/:id/tip/intent
 * Prepare le paiement d'un pourboire : le client le paie par carte, puis
 * l'app appelle POST /:id/tip avec le paymentIntentId.
 * @param {number} req.body.amount - Montant du pourboire (1 $ a 500 $)
 */
router.post('/:id/tip/intent', protect, async (req, res) => {
    try {
        const check = await checkTipAllowed(req.params.id, req.user.id, req.body.amount);
        if (check.status) return res.status(check.status).json({ success: false, message: check.message });

        const params = {
            amount: Math.round(check.amount * 100),
            currency: 'cad',
            automatic_payment_methods: { enabled: true },
            description: `Pourboire pour la réservation #${check.reservation._id}`,
            metadata: {
                type: 'tip',
                reservationId: check.reservation._id.toString(),
                userId: req.user.id.toString(),
                amount: String(check.amount),
            },
        };
        if (req.user.stripeCustomerId) params.customer = req.user.stripeCustomerId;

        const intent = await stripe.paymentIntents.create(params, {
            idempotencyKey: `tip_intent_${check.reservation._id}_${params.amount}_${req.user.id}_${Date.now()}`,
        });

        res.json({ success: true, clientSecret: intent.client_secret, paymentIntentId: intent.id });
    } catch (error) {
        console.error('Erreur préparation pourboire:', error);
        res.status(500).json({ success: false, message: 'Le paiement du pourboire n’a pas pu être préparé.' });
    }
});

/**
 * POST /api/reservations/:id/tip
 * Enregistre un pourboire PAYE (100 % au deneigeur) et le lui verse.
 * @param {number} req.body.amount - Montant du pourboire
 * @param {string} req.body.paymentIntentId - Paiement Stripe du pourboire
 */
router.post('/:id/tip', protect, async (req, res) => {
    try {
        const { paymentIntentId } = req.body;
        const check = await checkTipAllowed(req.params.id, req.user.id, req.body.amount);
        if (check.status) return res.status(check.status).json({ success: false, message: check.message });

        if (!paymentIntentId) {
            return res.status(402).json({
                success: false,
                code: 'TIP_PAYMENT_REQUIRED',
                message: 'Le pourboire doit être payé par carte.',
            });
        }

        let intent;
        try {
            intent = await stripe.paymentIntents.retrieve(paymentIntentId);
        } catch (e) {
            return res.status(402).json({ success: false, code: 'PAYMENT_NOT_FOUND', message: 'Paiement introuvable.' });
        }
        const valid = intent.status === 'succeeded'
            && intent.metadata?.type === 'tip'
            && intent.metadata?.reservationId === check.reservation._id.toString()
            && intent.metadata?.userId === String(req.user.id)
            && (intent.amount_received ?? intent.amount) === Math.round(check.amount * 100);
        if (!valid) {
            return res.status(402).json({
                success: false,
                code: 'TIP_PAYMENT_INVALID',
                message: 'Ce paiement ne correspond pas à ce pourboire.',
            });
        }

        const result = await recordPaidTip(check.reservation._id, check.amount, paymentIntentId);
        if (!result.ok) {
            await stripe.refunds.create({ payment_intent: paymentIntentId }).catch(() => {});
            return res.status(409).json({
                success: false,
                message: 'Un pourboire a déjà été donné pour cette réservation. Ce paiement a été remboursé.',
            });
        }

        const worker = result.reservation.workerId;
        res.json({
            success: true,
            message: 'Pourboire envoyé',
            tipAmount: check.amount,
            workerName: worker?.firstName ? `${worker.firstName} ${worker.lastName}` : undefined,
        });
    } catch (error) {
        console.error('Erreur ajout pourboire:', error);
        res.status(500).json({ success: false, message: 'Erreur lors de l’envoi du pourboire' });
    }
});

module.exports = router;