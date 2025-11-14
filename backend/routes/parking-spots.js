const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const ParkingSpot = require('../models/ParkingSpot');

// @route   GET /api/parking-spots
// @desc    Obtenir toutes les places de parking
// @access  Private
router.get('/', protect, async (req, res) => {
    try {
        const { availableOnly } = req.query;

        const query = {};
        if (availableOnly === 'true') {
            query.isAvailable = true;
        }

        const parkingSpots = await ParkingSpot.find(query)
            .populate('assignedTo', 'firstName lastName email')
            .sort({ level: 1, spotNumber: 1 });

        res.status(200).json({
            success: true,
            count: parkingSpots.length,
            parkingSpots,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des places:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des places',
        });
    }
});

// @route   GET /api/parking-spots/:id
// @desc    Obtenir une place de parking par ID
// @access  Private
router.get('/:id', protect, async (req, res) => {
    try {
        const parkingSpot = await ParkingSpot.findById(req.params.id)
            .populate('assignedTo', 'firstName lastName email');

        if (!parkingSpot) {
            return res.status(404).json({
                success: false,
                message: 'Place non trouvée',
            });
        }

        res.status(200).json({
            success: true,
            parkingSpot,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération de la place:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de la place',
        });
    }
});

module.exports = router;