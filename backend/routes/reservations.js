
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Reservation = require('../models/Reservation');

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
            .populate('vehicleId')
            .populate('parkingSpotId')
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
            .populate('vehicleId')
            .populate('parkingSpotId')
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
            departureTime,
            deadlineTime,
            serviceOptions,
            snowDepthCm,
            totalPrice,
            paymentMethod,
        } = req.body;

        const reservation = await Reservation.create({
            userId: req.user.id,
            vehicleId,
            parkingSpotId,
            departureTime: new Date(departureTime),
            deadlineTime: new Date(deadlineTime),
            serviceOptions: serviceOptions || [],
            snowDepthCm,
            basePrice: totalPrice,
            totalPrice,
            paymentMethod,
        });

        await reservation.populate('vehicleId');
        await reservation.populate('parkingSpotId');

        res.status(201).json({
            success: true,
            reservation,
            message: 'Réservation créée avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de la création de la réservation:', error);
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
        const reservation = await Reservation.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            req.body,
            { new: true, runValidators: true }
        )
            .populate('vehicleId')
            .populate('parkingSpotId')
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

module.exports = router;