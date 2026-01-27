/**
 * Routes CRUD pour les véhicules des clients (ajout, modification, suppression, photo).
 * @module routes/vehicles
 */

const express = require('express');
const router = express.Router();
const multer = require('multer');
const { protect } = require('../middleware/auth');
const Vehicle = require('../models/Vehicle');
const { uploadFromBuffer } = require('../config/cloudinary');

// Configure multer with memory storage for Cloudinary uploads
const vehiclePhotoUpload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB max
    },
    fileFilter: function (req, file, cb) {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Seules les images sont acceptées'), false);
        }
    }
});

// --- Liste et détails ---

/**
 * GET /api/vehicles
 * Retourne tous les véhicules actifs de l'utilisateur, triés par défaut en premier.
 */
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

/**
 * GET /api/vehicles/:id
 * Retourne un véhicule par son ID (appartenant à l'utilisateur).
 */
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

// --- Création ---

/**
 * POST /api/vehicles
 * Ajoute un nouveau véhicule. Vérifie l'unicité de la plaque d'immatriculation.
 * @param {string} req.body.make - Marque
 * @param {string} req.body.model - Modèle
 * @param {string} req.body.color - Couleur
 * @param {string} req.body.licensePlate - Plaque d'immatriculation (unique)
 */
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
            message: 'Erreur lors de l\'ajout du véhicule',
        });
    }
});

// --- Modification et suppression ---

/**
 * PUT /api/vehicles/:id
 * Met à jour les informations d'un véhicule.
 */
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

/**
 * DELETE /api/vehicles/:id
 * Supprime un véhicule (suppression douce via isActive=false).
 */
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

// --- Photo du véhicule ---

/**
 * POST /api/vehicles/:id/photo
 * Téléverse une photo du véhicule vers Cloudinary.
 * @param {File} req.file - Fichier image (champ 'photo', max 5 Mo)
 */
router.post('/:id/photo', protect, vehiclePhotoUpload.single('photo'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Photo requise',
            });
        }

        // Verify vehicle belongs to user
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

        // Upload vers Cloudinary
        const cloudinaryResult = await uploadFromBuffer(req.file.buffer, {
            folder: 'deneige-auto/vehicles',
            public_id: `vehicle-${req.params.id}-${Date.now()}`,
        });

        const photoUrl = cloudinaryResult.url;

        // Update vehicle with new photo URL
        const updatedVehicle = await Vehicle.findByIdAndUpdate(
            req.params.id,
            { photoUrl: photoUrl },
            { new: true }
        );

        console.log(`📸 Vehicle photo uploaded to Cloudinary: ${photoUrl}`);

        res.json({
            success: true,
            message: 'Photo du véhicule mise à jour',
            data: {
                photoUrl: photoUrl,
                vehicle: updatedVehicle,
            },
        });
    } catch (error) {
        console.error('Error uploading vehicle photo:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'upload de la photo',
            error: error.message,
        });
    }
});

module.exports = router;