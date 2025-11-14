
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Vehicle = require('../models/Vehicle');

// @route   GET /api/vehicles
// @desc    Obtenir tous les véhicules de l'utilisateur
// @access  Private
router.get('/', protect, async (req, res) => {
    try {
        const vehicles = await Vehicle.find({
            userId: req.user.id,
            isActive: true,
        }).sort({ isDefault: -1, createdAt: -1 });

        res.status(200).json({
            success: true,
            count: vehicles.length,
            vehicles,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des véhicules:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des véhicules',
        });
    }
});

// @route   GET /api/vehicles/:id
// @desc    Obtenir un véhicule par ID
// @access  Private
router.get('/:id', protect, async (req, res) => {
    try {
        const vehicle = await Vehicle.findOne({
            _id: req.params.id,
            userId: req.user.id,
        });

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Véhicule non trouvé',
            });
        }

        res.status(200).json({
            success: true,
            vehicle,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération du véhicule:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération du véhicule',
        });
    }
});

// @route   POST /api/vehicles
// @desc    Ajouter un nouveau véhicule
// @access  Private
router.post('/', protect, async (req, res) => {
    try {
        const { make, model, year, color, licensePlate, type, photoUrl, isDefault } = req.body;

        // Vérifier si la plaque existe déjà
        const existingVehicle = await Vehicle.findOne({ licensePlate });
        if (existingVehicle) {
            return res.status(409).json({
                success: false,
                message: 'Cette plaque d\'immatriculation existe déjà',
            });
        }

        const vehicle = await Vehicle.create({
            userId: req.user.id,
            make,
            model,
            year,
            color,
            licensePlate,
            type,
            photoUrl,
            isDefault: isDefault || false,
        });

        res.status(201).json({
            success: true,
            vehicle,
            message: 'Véhicule ajouté avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de l\'ajout du véhicule:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Erreur lors de l\'ajout du véhicule',
        });
    }
});

// @route   PUT /api/vehicles/:id
// @desc    Mettre à jour un véhicule
// @access  Private
router.put('/:id', protect, async (req, res) => {
    try {
        const vehicle = await Vehicle.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            req.body,
            { new: true, runValidators: true }
        );

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Véhicule non trouvé',
            });
        }

        res.status(200).json({
            success: true,
            vehicle,
            message: 'Véhicule mis à jour avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour du véhicule:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour du véhicule',
        });
    }
});

// @route   DELETE /api/vehicles/:id
// @desc    Supprimer un véhicule (soft delete)
// @access  Private
router.delete('/:id', protect, async (req, res) => {
    try {
        const vehicle = await Vehicle.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            { isActive: false },
            { new: true }
        );

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Véhicule non trouvé',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Véhicule supprimé avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de la suppression du véhicule:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la suppression du véhicule',
        });
    }
});

module.exports = router;