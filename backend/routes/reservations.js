
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Reservation = require('../models/Reservation');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);


// @route   GET /api/reservations
// @desc    Obtenir toutes les réservations de l'utilisateur
// @access  Private
router.get('/', protect, async (req, res) => {
    try {
        const { upcoming, status } = req.query;

        const query = { userId: req.user.id };

        if (upcoming === 'true') {
            query.status = { $in: ['pending', 'assigned', 'inProgress'] };
            query.departureTime = { $gte: new Date() };
        }

        if (status) {
            query.status = status;
        }

        const reservations = await Reservation.find(query)
            .populate('vehicle')
            .populate('parkingSpot')
            .populate('workerId', 'firstName lastName phoneNumber')
            .sort({ departureTime: -1 });

        res.status(200).json({
            success: true,
            count: reservations.length,
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

// @route   GET /api/reservations/:id
// @desc    Obtenir une réservation par ID
// @access  Private
router.get('/:id', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOne({
            _id: req.params.id,
            userId: req.user.id,
        })
            .populate('vehicle')
            .populate('parkingSpot')
            .populate('workerId', 'firstName lastName phoneNumber');

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

// @route   POST /api/reservations
// @desc    Créer une nouvelle réservation
// @access  Private
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
        } = req.body;

        console.log('📝 Nouvelle réservation:', {
            userId: req.user.id,
            vehicleId,
            parkingSpotId,
            parkingSpotNumber,
            customLocation,
            departureTime,
            totalPrice,
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
        });

        // ✅ IMPORTANT: Populer les relations avant de renvoyer
        await reservation.populate('vehicle');
        if (finalParkingSpotId) {
            await reservation.populate('parkingSpot');
        }

        console.log('✅ Réservation créée avec succès:', reservation._id);

        res.status(201).json({
            success: true,
            reservation: {
                id: reservation._id.toString(),
                userId: reservation.userId.toString(),
                workerId: reservation.workerId?.toString(),
                vehicle: reservation.vehicle, // ✅ Déjà populé
                parkingSpot: reservation.parkingSpot || {
                    // ✅ Créer un objet factice si place manuelle
                    id: 'manual',
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
        res.status(500).json({
            success: false,
            message: error.message || 'Erreur lors de la création de la réservation',
        });
    }
});

// @route   PUT /api/reservations/:id
// @desc    Mettre à jour une réservation
// @access  Private
router.put('/:id', protect, async (req, res) => {
    try {
        // Mapper les champs du frontend vers le schéma backend
        const updateData = { ...req.body };
        if (updateData.vehicleId) {
            updateData.vehicle = updateData.vehicleId;
            delete updateData.vehicleId;
        }
        if (updateData.parkingSpotId) {
            updateData.parkingSpot = updateData.parkingSpotId;
            delete updateData.parkingSpotId;
        }

        const reservation = await Reservation.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            updateData,
            { new: true, runValidators: true }
        )
            .populate('vehicle')
            .populate('parkingSpot')
            .populate('workerId');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        res.status(200).json({
            success: true,
            reservation,
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

// @route   DELETE /api/reservations/:id
// @desc    Annuler une réservation
// @access  Private
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

// @route   POST /api/payments/create-intent
// @desc    Créer un Payment Intent Stripe
// @access  Private
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
            message: error.message,
        });
    }
});

module.exports = router;