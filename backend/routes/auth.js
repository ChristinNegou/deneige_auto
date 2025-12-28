const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const { sendPasswordResetEmail } = require('../config/email');

// Fonction pour générer un token JWT
const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE,
    });
};

// @route   POST /api/auth/register
// @desc    Enregistrer un nouvel utilisateur
// @access  Public
router.post('/register', async (req, res) => {
    try {
        const { email, password, firstName, lastName, phoneNumber, role } = req.body;

        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: 'Cet email est déjà utilisé',
            });
        }

        // Preparer les donnees utilisateur
        const userData = {
            email,
            password,
            firstName,
            lastName,
            phoneNumber,
            role: role || 'client',
        };

        // Initialiser workerProfile pour les deneigeurs
        if (role === 'snowWorker') {
            userData.workerProfile = {
                isAvailable: false,
                currentLocation: {
                    type: 'Point',
                    coordinates: [0, 0],
                },
                preferredZones: [],
                maxActiveJobs: 3,
                vehicleType: 'car',
                equipmentList: [],
                totalJobsCompleted: 0,
                totalEarnings: 0,
                totalTipsReceived: 0,
                averageRating: 0,
                totalRatingsCount: 0,
            };
        }

        const user = await User.create(userData);

        const token = generateToken(user._id, user.role);

        res.status(201).json({
            success: true,
            user: {
                id: user._id,
                email: user.email,
                name: `${user.firstName} ${user.lastName}`,
                firstName: user.firstName,
                lastName: user.lastName,
                phoneNumber: user.phoneNumber,
                role: user.role,
                photoUrl: user.photoUrl,
                createdAt: user.createdAt,
            },
            token,
        });
    } catch (error) {
        console.error('Erreur lors de l\'inscription:', error);
        res.status(400).json({
            success: false,
            message: error.message || 'Erreur lors de l\'inscription',
        });
    }
});

// @route   POST /api/auth/login
// @desc    Connecter un utilisateur
// @access  Public
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Veuillez fournir un email et un mot de passe',
            });
        }

        const user = await User.findOne({ email }).select('+password');

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Email ou mot de passe incorrect',
            });
        }

        const isPasswordValid = await user.comparePassword(password);

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Email ou mot de passe incorrect',
            });
        }

        const token = generateToken(user._id, user.role);

        res.status(200).json({
            success: true,
            user: {
                id: user._id,
                email: user.email,
                name: `${user.firstName} ${user.lastName}`,
                firstName: user.firstName,
                lastName: user.lastName,
                phoneNumber: user.phoneNumber,
                role: user.role,
                photoUrl: user.photoUrl,
                createdAt: user.createdAt,
            },
            token,
        });
    } catch (error) {
        console.error('Erreur lors de la connexion:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la connexion',
        });
    }
});

// @route   POST /api/auth/forgot-password
// @desc    Envoyer un email de réinitialisation de mot de passe
// @access  Public
router.post('/forgot-password', async (req, res) => {
    console.log('\n========================================');
    console.log('[DEBUG] Route /forgot-password appelée');
    console.log('[DEBUG] Body reçu:', req.body);
    console.log('========================================\n');

    try {
        const { email } = req.body;

        if (!email) {
            console.log('[!] Email manquant dans la requête');

            return res.status(400).json({
                success: false,
                message: 'Veuillez fournir un email',
            });
        }
        console.log('[*] Recherche de l\'utilisateur avec email:', email);
        const user = await User.findOne({ email });

        if (!user) {
            console.log('[!] Utilisateur non trouvé pour email:', email);
            // Pour des raisons de sécurité, ne pas révéler si l'email existe ou non
            return res.status(200).json({
                success: true,
                message: 'Si cet email existe, un lien de réinitialisation a été envoyé',
            });
        }

        console.log('[OK] Utilisateur trouvé:', user.firstName, user.lastName);

        // Générer le token de réinitialisation
        const resetToken = user.getResetPasswordToken();
        console.log('[OK] Token généré:', resetToken.substring(0, 10) + '...');

        // Sauvegarder le token dans la base de données
        await user.save({ validateBeforeSave: false });
        console.log('[OK] Token sauvegardé dans la base de données');

        try {
            console.log('[*] Tentative d\'envoi de l\'email...');


            // Envoyer l'email
            await sendPasswordResetEmail(user, resetToken);
            console.log('[OK] Email envoyé avec succès !');

            res.status(200).json({
                success: true,
                message: 'Email de réinitialisation envoyé avec succès',
            });
        } catch (error) {
            console.error('Erreur lors de l\'envoi de l\'email:', error);
            console.error('[X] Détails de l\'erreur:', error.message);

            // Supprimer le token si l'envoi échoue
            user.resetPasswordToken = undefined;
            user.resetPasswordExpire = undefined;
            await user.save({ validateBeforeSave: false });

            return res.status(500).json({
                success: false,
                message: 'Erreur lors de l\'envoi de l\'email',
            });
        }
    } catch (error) {
        console.error('Erreur lors de la réinitialisation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la réinitialisation du mot de passe',
        });
    }
});

// @route   PUT /api/auth/reset-password/:resetToken
// @desc    Réinitialiser le mot de passe
// @access  Public
router.put('/reset-password/:resetToken', async (req, res) => {
    try {
        const { password } = req.body;

        if (!password || password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Le mot de passe doit contenir au moins 6 caractères',
            });
        }

        // Hasher le token pour le comparer avec celui en base de données
        const resetPasswordToken = crypto
            .createHash('sha256')
            .update(req.params.resetToken)
            .digest('hex');

        const user = await User.findOne({
            resetPasswordToken,
            resetPasswordExpire: { $gt: Date.now() },
        });

        if (!user) {
            return res.status(400).json({
                success: false,
                message: 'Token invalide ou expiré',
            });
        }

        // Définir le nouveau mot de passe
        user.password = password;
        user.resetPasswordToken = undefined;
        user.resetPasswordExpire = undefined;
        await user.save();

        // Générer un nouveau token JWT
        const token = generateToken(user._id, user.role);

        res.status(200).json({
            success: true,
            message: 'Mot de passe réinitialisé avec succès',
            token,
        });
    } catch (error) {
        console.error('Erreur lors de la réinitialisation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la réinitialisation du mot de passe',
        });
    }
});

// @route   GET /api/auth/me
// @desc    Obtenir l'utilisateur actuel
// @access  Private
router.get('/me', protect, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        res.status(200).json({
            success: true,
            id: user._id,
            email: user.email,
            name: `${user.firstName} ${user.lastName}`,
            firstName: user.firstName,
            lastName: user.lastName,
            phoneNumber: user.phoneNumber,
            role: user.role,
            photoUrl: user.photoUrl,
            createdAt: user.createdAt,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération de l\'utilisateur:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de l\'utilisateur',
        });
    }
});

// @route   POST /api/auth/logout
// @desc    Déconnecter l'utilisateur
// @access  Private
router.post('/logout', protect, async (req, res) => {
    try {
        res.status(200).json({
            success: true,
            message: 'Déconnexion réussie',
        });
    } catch (error) {
        console.error('Erreur lors de la déconnexion:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la déconnexion',
        });
    }
});

// @route   PUT /api/auth/update-profile
// @desc    Mettre à jour le profil utilisateur
// @access  Private
router.put('/update-profile', protect, async (req, res) => {
    try {
        const { firstName, lastName, phoneNumber, photoUrl } = req.body;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            {
                firstName,
                lastName,
                phoneNumber,
                photoUrl,
                updatedAt: Date.now(),
            },
            { new: true, runValidators: true }
        );

        res.status(200).json({
            success: true,
            user: {
                id: user._id,
                email: user.email,
                name: `${user.firstName} ${user.lastName}`,
                firstName: user.firstName,
                lastName: user.lastName,
                phoneNumber: user.phoneNumber,
                role: user.role,
                photoUrl: user.photoUrl,
                createdAt: user.createdAt,
            },
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour du profil:', error);
        res.status(400).json({
            success: false,
            message: error.message || 'Erreur lors de la mise à jour du profil',
        });
    }
});

module.exports = router;