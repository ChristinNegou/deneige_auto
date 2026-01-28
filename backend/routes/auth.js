/**
 * Routes d'authentification (inscription, connexion, refresh token, mot de passe, profil).
 * @module routes/auth
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const Vehicle = require('../models/Vehicle');
const Notification = require('../models/Notification');
const SupportRequest = require('../models/SupportRequest');
const PhoneVerification = require('../models/PhoneVerification');
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
const { profilePhotoUpload, handleMulterError } = require('../middleware/fileUpload');
const { uploadFromBuffer } = require('../config/cloudinary');
const { formatPhoneNumber } = require('../services/twilioService');

// --- Génération de tokens ---

// Fonction pour générer un token JWT (access token)
const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE || '7d', // Utiliser la variable d'env ou 7 jours par défaut
    });
};

// Fonction pour générer un token JWT longue durée (compatibilité)
const generateLongLivedToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE || '7d',
    });
};

// --- Inscription ---

/**
 * POST /api/auth/register
 * Crée un nouveau compte utilisateur (client ou déneigeur).
 * @param {string} req.body.email - Adresse courriel
 * @param {string} req.body.password - Mot de passe (min 6 caractères)
 * @param {string} req.body.firstName - Prénom
 * @param {string} req.body.lastName - Nom de famille
 * @param {string} req.body.phoneNumber - Numéro de téléphone
 * @param {string} [req.body.role='client'] - Rôle (client ou snowWorker)
 * @returns {Object} Token JWT et profil utilisateur
 */
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
                workerProfile: user.role === 'snowWorker' ? {
                    identityVerification: {
                        status: user.workerProfile?.identityVerification?.status || 'not_submitted',
                    },
                } : undefined,
            },
            token,
        });
    } catch (error) {
        console.error('Erreur lors de l\'inscription:', error);
        res.status(400).json({
            success: false,
            message: 'Erreur lors de l\'inscription',
        });
    }
});

// --- Connexion ---

/**
 * POST /api/auth/login
 * Authentifie un utilisateur et retourne les tokens JWT (access + refresh).
 * @param {string} req.body.email - Adresse courriel
 * @param {string} req.body.password - Mot de passe
 * @returns {Object} Tokens JWT, profil utilisateur et durée d'expiration
 */
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
                workerProfile: user.role === 'snowWorker' ? {
                    identityVerification: {
                        status: user.workerProfile?.identityVerification?.status || 'not_submitted',
                    },
                } : undefined,
            },
            token: accessToken,
            refreshToken: refreshToken,
            expiresIn: 604800, // 7 jours en secondes
        });
    } catch (error) {
        console.error('Erreur lors de la connexion:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la connexion',
        });
    }
});

// --- Rafraîchissement de token ---

/**
 * POST /api/auth/refresh-token
 * Rafraîchit le token d'accès via le refresh token (rotation automatique).
 * @param {string} req.body.refreshToken - Refresh token actuel
 * @returns {Object} Nouveau access token et nouveau refresh token
 */
router.post('/refresh-token', authLimiter, async (req, res) => {
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
            expiresIn: 604800, // 7 jours en secondes
        });
    } catch (error) {
        console.error('Erreur lors du refresh token:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du rafraîchissement du token',
        });
    }
});

// --- Mot de passe oublié ---

/**
 * POST /api/auth/forgot-password
 * Envoie un courriel de réinitialisation de mot de passe.
 * Retourne toujours 200 pour ne pas révéler l'existence d'un compte.
 * @param {string} req.body.email - Adresse courriel
 */
router.post('/forgot-password', forgotPasswordLimiter, validateForgotPassword, async (req, res) => {
    // Note: Ne pas logger d'informations sensibles (email, tokens) en production
    const isProduction = process.env.NODE_ENV === 'production';

    if (!isProduction) {
        console.log('[DEBUG] Route /forgot-password appelée');
    }

    try {
        const { email } = req.body;

        if (!email) {
            console.log('[!] Email manquant dans la requête');

            return res.status(400).json({
                success: false,
                message: 'Veuillez fournir un email',
            });
        }

        const user = await User.findOne({ email });

        if (!user) {
            // Pour des raisons de sécurité, ne pas révéler si l'email existe ou non
            // Ne pas logger l'email pour éviter l'exposition de données
            return res.status(200).json({
                success: true,
                message: 'Si cet email existe, un lien de réinitialisation a été envoyé',
            });
        }

        // Générer le token de réinitialisation
        const resetToken = user.getResetPasswordToken();

        // Sauvegarder le token dans la base de données
        await user.save({ validateBeforeSave: false });

        try {
            if (!isProduction) {
                console.log('[*] Tentative d\'envoi de l\'email de réinitialisation...');
            }


            // Envoyer l'email
            await sendPasswordResetEmail(user, resetToken);
            if (!isProduction) {
                console.log('[OK] Email de réinitialisation envoyé');
            }

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

// --- Réinitialisation du mot de passe ---

/**
 * PUT /api/auth/reset-password/:resetToken
 * Réinitialise le mot de passe à l'aide d'un token à usage unique.
 * @param {string} req.params.resetToken - Token de réinitialisation (hex)
 * @param {string} req.body.password - Nouveau mot de passe (min 6 caractères)
 * @returns {Object} Nouveau token JWT
 */
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

// --- Profil utilisateur ---

/**
 * GET /api/auth/me
 * Retourne le profil de l'utilisateur authentifié.
 * @returns {Object} Profil utilisateur (id, email, nom, rôle, etc.)
 */
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

// --- Déconnexion ---

/**
 * POST /api/auth/logout
 * Déconnecte l'utilisateur et invalide son refresh token.
 */
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

// --- Mise à jour du profil ---

/**
 * PUT /api/auth/update-profile
 * Met à jour le profil utilisateur (nom, téléphone, photo).
 * Vérifie l'unicité du numéro de téléphone.
 * @param {string} [req.body.firstName] - Prénom
 * @param {string} [req.body.lastName] - Nom de famille
 * @param {string} [req.body.phoneNumber] - Numéro de téléphone
 * @param {string} [req.body.photoUrl] - URL de la photo de profil
 * @returns {Object} Profil utilisateur mis à jour
 */
router.put('/update-profile', protect, validateUpdateProfile, async (req, res) => {
    try {
        const { firstName, lastName, phoneNumber, photoUrl } = req.body;

        // Si le numéro de téléphone est fourni et différent, vérifier qu'il n'est pas déjà utilisé
        if (phoneNumber) {
            const formattedPhone = formatPhoneNumber(phoneNumber);
            const existingUser = await User.findOne({
                phoneNumber: formattedPhone,
                _id: { $ne: req.user.id }
            });
            if (existingUser) {
                return res.status(409).json({
                    success: false,
                    message: 'Ce numéro de téléphone est déjà associé à un autre compte',
                    code: 'PHONE_ALREADY_USED'
                });
            }
        }

        const updateData = {
            updatedAt: Date.now(),
        };

        if (firstName !== undefined) updateData.firstName = firstName;
        if (lastName !== undefined) updateData.lastName = lastName;
        if (phoneNumber !== undefined) updateData.phoneNumber = phoneNumber ? formatPhoneNumber(phoneNumber) : phoneNumber;
        if (photoUrl !== undefined) updateData.photoUrl = photoUrl;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            updateData,
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
                workerProfile: user.role === 'snowWorker' ? {
                    identityVerification: {
                        status: user.workerProfile?.identityVerification?.status || 'not_submitted',
                    },
                } : undefined,
            },
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour du profil:', error);
        res.status(400).json({
            success: false,
            message: 'Erreur lors de la mise à jour du profil',
        });
    }
});

// --- Vérification de téléphone ---

/**
 * POST /api/auth/check-phone
 * Vérifie si un numéro de téléphone est disponible (non associé à un autre compte).
 * @param {string} req.body.phoneNumber - Numéro de téléphone à vérifier
 * @returns {Object} { available: boolean }
 */
router.post('/check-phone', protect, async (req, res) => {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({
                success: false,
                message: 'Le numéro de téléphone est requis'
            });
        }

        const formattedPhone = formatPhoneNumber(phoneNumber);

        // Vérifier si le numéro appartient à un autre utilisateur
        const existingUser = await User.findOne({
            phoneNumber: formattedPhone,
            _id: { $ne: req.user.id }
        });

        res.status(200).json({
            success: true,
            available: !existingUser,
            message: existingUser
                ? 'Ce numéro de téléphone est déjà associé à un autre compte'
                : 'Ce numéro de téléphone est disponible'
        });
    } catch (error) {
        console.error('Erreur lors de la vérification du téléphone:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la vérification du numéro de téléphone'
        });
    }
});

// --- Photo de profil ---

/**
 * POST /api/auth/upload-profile-photo
 * Téléverse une photo de profil vers Cloudinary (400x400, recadrage visage).
 * @param {File} req.file - Fichier image (multipart/form-data, champ 'photo')
 * @returns {Object} URL de la photo et profil utilisateur mis à jour
 */
router.post('/upload-profile-photo', protect, profilePhotoUpload.single('photo'), handleMulterError, async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Aucune photo fournie'
            });
        }

        // Upload vers Cloudinary
        const result = await uploadFromBuffer(req.file.buffer, {
            folder: `deneige-auto/profiles/${req.user.id}`,
            public_id: `profile_${Date.now()}`,
            transformation: [
                { width: 400, height: 400, crop: 'fill', gravity: 'face' },
                { quality: 'auto:good' }
            ]
        });

        // Mettre à jour l'utilisateur avec la nouvelle URL
        const user = await User.findByIdAndUpdate(
            req.user.id,
            { photoUrl: result.url, updatedAt: Date.now() },
            { new: true }
        );

        res.status(200).json({
            success: true,
            message: 'Photo de profil mise à jour',
            photoUrl: result.url,
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
                workerProfile: user.role === 'snowWorker' ? {
                    identityVerification: {
                        status: user.workerProfile?.identityVerification?.status || 'not_submitted',
                    },
                } : undefined,
            }
        });
    } catch (error) {
        console.error('Erreur lors de l\'upload de la photo:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'upload de la photo de profil'
        });
    }
});

/**
 * DELETE /api/auth/delete-profile-photo
 * Supprime la photo de profil de l'utilisateur (met photoUrl à null).
 */
router.delete('/delete-profile-photo', protect, async (req, res) => {
    try {
        const user = await User.findByIdAndUpdate(
            req.user.id,
            { photoUrl: null, updatedAt: Date.now() },
            { new: true }
        );

        res.status(200).json({
            success: true,
            message: 'Photo de profil supprimée',
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
                workerProfile: user.role === 'snowWorker' ? {
                    identityVerification: {
                        status: user.workerProfile?.identityVerification?.status || 'not_submitted',
                    },
                } : undefined,
            }
        });
    } catch (error) {
        console.error('Erreur lors de la suppression de la photo:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la suppression de la photo de profil'
        });
    }
});

// --- Préférences ---

/**
 * GET /api/auth/preferences
 * Retourne les préférences de notification et d'affichage de l'utilisateur.
 */
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

/**
 * PUT /api/auth/preferences
 * Met à jour les préférences de notification et d'affichage.
 * @param {boolean} [req.body.pushEnabled] - Activer/désactiver les notifications push
 * @param {boolean} [req.body.soundEnabled] - Activer/désactiver les sons
 * @param {boolean} [req.body.darkThemeEnabled] - Activer/désactiver le thème sombre
 */
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

// --- Suppression de compte ---

/**
 * DELETE /api/auth/account
 * Supprime définitivement le compte utilisateur et toutes ses données associées.
 * Requiert la confirmation par mot de passe.
 * @param {string} req.body.password - Mot de passe pour confirmer la suppression
 */
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

        // Supprimer les données associées à l'utilisateur
        const userId = req.user.id;

        // Supprimer en parallèle pour de meilleures performances
        const deletionResults = await Promise.allSettled([
            Vehicle.deleteMany({ userId }),
            Notification.deleteMany({ userId }),
            SupportRequest.deleteMany({ userId }),
            PhoneVerification.deleteMany({ userId }),
        ]);

        // Logger les résultats de suppression pour le debugging
        const deletionSummary = {
            vehicles: deletionResults[0].status === 'fulfilled' ? deletionResults[0].value.deletedCount : 0,
            notifications: deletionResults[1].status === 'fulfilled' ? deletionResults[1].value.deletedCount : 0,
            supportRequests: deletionResults[2].status === 'fulfilled' ? deletionResults[2].value.deletedCount : 0,
            phoneVerifications: deletionResults[3].status === 'fulfilled' ? deletionResults[3].value.deletedCount : 0,
        };

        console.log(`[Auth] Données supprimées pour utilisateur ${userId}:`, deletionSummary);

        // Supprimer l'utilisateur
        await User.findByIdAndDelete(userId);

        res.status(200).json({
            success: true,
            message: 'Compte supprimé avec succès',
            deletedData: deletionSummary,
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