const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const { sendPasswordResetEmail } = require('../config/email');
const { authLimiter, registrationLimiter, forgotPasswordLimiter } = require('../middleware/rateLimiter');
const {
    validateRegister,
    validateLogin,
    validateForgotPassword,
    validateResetPassword,
    validateUpdateProfile,
} = require('../middleware/validators');

// Fonction pour générer un token JWT (access token - courte durée)
const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: '15m', // 15 minutes pour l'access token
    });
};

// Fonction pour générer un token JWT longue durée (compatibilité)
const generateLongLivedToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE || '7d',
    });
};

// @route   POST /api/auth/register
// @desc    Enregistrer un nouvel utilisateur
// @access  Public
router.post('/register', registrationLimiter, validateRegister, async (req, res) => {
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
router.post('/login', authLimiter, validateLogin, async (req, res) => {
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

        // Vérifier si l'utilisateur est suspendu
        if (user.isSuspended) {
            const suspendedUntilStr = user.suspendedUntil
                ? user.suspendedUntil.toLocaleDateString('fr-CA')
                : 'indéterminée';

            return res.status(403).json({
                success: false,
                code: 'USER_SUSPENDED',
                message: 'Votre compte est suspendu',
                suspensionDetails: {
                    reason: user.suspensionReason || 'Non spécifiée',
                    suspendedUntil: user.suspendedUntil,
                    suspendedUntilDisplay: suspendedUntilStr,
                },
            });
        }

        // Générer les tokens
        const accessToken = generateToken(user._id, user.role);
        const refreshToken = user.generateRefreshToken();
        await user.save({ validateBeforeSave: false });

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
            token: accessToken,
            refreshToken: refreshToken,
            expiresIn: 900, // 15 minutes en secondes
        });
    } catch (error) {
        console.error('Erreur lors de la connexion:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la connexion',
        });
    }
});

// @route   POST /api/auth/refresh-token
// @desc    Rafraîchir le token d'accès
// @access  Public
router.post('/refresh-token', async (req, res) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({
                success: false,
                message: 'Refresh token requis',
            });
        }

        // Hasher le token pour le comparer
        const hashedToken = crypto
            .createHash('sha256')
            .update(refreshToken)
            .digest('hex');

        // Trouver l'utilisateur avec ce refresh token
        const user = await User.findOne({
            refreshToken: hashedToken,
            refreshTokenExpire: { $gt: Date.now() },
        }).select('+refreshToken +refreshTokenExpire');

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Refresh token invalide ou expiré',
            });
        }

        // Vérifier si l'utilisateur est suspendu
        if (user.isSuspended) {
            return res.status(403).json({
                success: false,
                code: 'USER_SUSPENDED',
                message: 'Votre compte est suspendu',
            });
        }

        // Générer un nouveau access token
        const newAccessToken = generateToken(user._id, user.role);

        // Optionnel: rotation du refresh token pour plus de sécurité
        const newRefreshToken = user.generateRefreshToken();
        await user.save({ validateBeforeSave: false });

        res.status(200).json({
            success: true,
            token: newAccessToken,
            refreshToken: newRefreshToken,
            expiresIn: 900,
        });
    } catch (error) {
        console.error('Erreur lors du refresh token:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du rafraîchissement du token',
        });
    }
});

// @route   POST /api/auth/forgot-password
// @desc    Envoyer un email de réinitialisation de mot de passe
// @access  Public
router.post('/forgot-password', forgotPasswordLimiter, validateForgotPassword, async (req, res) => {
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
router.put('/reset-password/:resetToken', authLimiter, validateResetPassword, async (req, res) => {
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
            resetTokenUsed: { $ne: true }, // Vérifier que le token n'a pas déjà été utilisé
        });

        if (!user) {
            return res.status(400).json({
                success: false,
                message: 'Token invalide, expiré ou déjà utilisé',
            });
        }

        // Définir le nouveau mot de passe et marquer le token comme utilisé
        user.password = password;
        user.resetPasswordToken = undefined;
        user.resetPasswordExpire = undefined;
        user.resetTokenUsed = true; // Marquer comme utilisé pour empêcher la réutilisation
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
// @desc    Déconnecter l'utilisateur et invalider le refresh token
// @access  Private
router.post('/logout', protect, async (req, res) => {
    try {
        // Invalider le refresh token
        const user = await User.findById(req.user.id).select('+refreshToken +refreshTokenExpire');
        if (user) {
            user.invalidateRefreshToken();
            await user.save({ validateBeforeSave: false });
        }

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
router.put('/update-profile', protect, validateUpdateProfile, async (req, res) => {
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

// @route   GET /api/auth/preferences
// @desc    Obtenir les préférences utilisateur
// @access  Private
router.get('/preferences', protect, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        res.status(200).json({
            success: true,
            preferences: {
                notificationSettings: user.notificationSettings || {
                    pushEnabled: true,
                    emailEnabled: true,
                    smsEnabled: false,
                },
                userPreferences: user.userPreferences || {
                    soundEnabled: true,
                    darkThemeEnabled: true,
                },
            },
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des préférences:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des préférences',
        });
    }
});

// @route   PUT /api/auth/preferences
// @desc    Mettre à jour les préférences utilisateur
// @access  Private
router.put('/preferences', protect, async (req, res) => {
    try {
        const { pushEnabled, soundEnabled, darkThemeEnabled } = req.body;

        const updateData = {
            updatedAt: Date.now(),
        };

        // Mettre à jour notificationSettings si pushEnabled est fourni
        if (typeof pushEnabled === 'boolean') {
            updateData['notificationSettings.pushEnabled'] = pushEnabled;
        }

        // Mettre à jour userPreferences
        if (typeof soundEnabled === 'boolean') {
            updateData['userPreferences.soundEnabled'] = soundEnabled;
        }
        if (typeof darkThemeEnabled === 'boolean') {
            updateData['userPreferences.darkThemeEnabled'] = darkThemeEnabled;
        }

        const user = await User.findByIdAndUpdate(
            req.user.id,
            { $set: updateData },
            { new: true }
        );

        res.status(200).json({
            success: true,
            preferences: {
                notificationSettings: user.notificationSettings,
                userPreferences: user.userPreferences,
            },
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour des préférences:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour des préférences',
        });
    }
});

// @route   DELETE /api/auth/account
// @desc    Supprimer le compte utilisateur
// @access  Private
router.delete('/account', protect, async (req, res) => {
    try {
        const { password } = req.body;

        if (!password) {
            return res.status(400).json({
                success: false,
                message: 'Le mot de passe est requis pour confirmer la suppression',
            });
        }

        // Récupérer l'utilisateur avec le mot de passe
        const user = await User.findById(req.user.id).select('+password');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Utilisateur non trouvé',
            });
        }

        // Vérifier le mot de passe
        const isPasswordValid = await user.comparePassword(password);

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Mot de passe incorrect',
            });
        }

        // Supprimer l'utilisateur
        await User.findByIdAndDelete(req.user.id);

        // TODO: Optionnel - Supprimer les données associées (véhicules, réservations, etc.)
        // await Vehicle.deleteMany({ userId: req.user.id });
        // await Reservation.deleteMany({ client: req.user.id });

        res.status(200).json({
            success: true,
            message: 'Compte supprimé avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de la suppression du compte:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la suppression du compte',
        });
    }
});

module.exports = router;