/**
 * Routes pour la vérification de numéro de téléphone
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const PhoneVerification = require('../models/PhoneVerification');
const User = require('../models/User');
const {
    generateVerificationCode,
    formatPhoneNumber,
    isValidPhoneNumber,
    sendVerificationCode,
    isTwilioConfigured
} = require('../services/twilioService');
const { smsLimiter } = require('../middleware/rateLimiter');
const { validateSendCode, validateVerifyCode } = require('../middleware/validators');

/**
 * @route   POST /api/phone/send-code
 * @desc    Envoie un code de vérification par SMS et stocke les données d'inscription
 * @access  Public
 */
router.post('/send-code', smsLimiter, validateSendCode, async (req, res) => {
    try {
        const { phoneNumber, email, password, firstName, lastName, role } = req.body;

        // Valider les champs requis
        if (!phoneNumber) {
            return res.status(400).json({
                success: false,
                message: 'Le numéro de téléphone est requis'
            });
        }

        // Valider le format du numéro
        if (!isValidPhoneNumber(phoneNumber)) {
            return res.status(400).json({
                success: false,
                message: 'Format de numéro de téléphone invalide. Utilisez le format: +1 (XXX) XXX-XXXX'
            });
        }

        const formattedPhone = formatPhoneNumber(phoneNumber);

        // Vérifier si le numéro est déjà utilisé par un compte existant
        const existingUser = await User.findOne({ phoneNumber: formattedPhone });
        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: 'Ce numéro de téléphone est déjà associé à un compte'
            });
        }

        // Vérifier si l'email est déjà utilisé
        if (email) {
            const existingEmail = await User.findOne({ email: email.toLowerCase() });
            if (existingEmail) {
                return res.status(409).json({
                    success: false,
                    message: 'Cet email est déjà utilisé'
                });
            }
        }

        // Vérifier si on peut renvoyer un code
        const canResend = await PhoneVerification.canResendCode(formattedPhone);
        if (!canResend.canResend) {
            return res.status(429).json({
                success: false,
                message: canResend.message,
                remainingSeconds: canResend.remainingSeconds
            });
        }

        // Générer le code
        const code = generateVerificationCode();

        // Préparer les données d'inscription en attente
        // Hasher le mot de passe pour ne pas le stocker en clair dans PhoneVerification
        let pendingRegistration = null;
        if (email && password && firstName && lastName) {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);
            pendingRegistration = {
                email: email.toLowerCase(),
                password: hashedPassword, // Mot de passe hashé pour sécurité
                passwordHashed: true, // Flag pour indiquer que le mdp est déjà hashé
                firstName,
                lastName,
                role: role || 'client'
            };
        }

        // Sauvegarder la vérification
        await PhoneVerification.createOrUpdate(formattedPhone, code, pendingRegistration);

        // Envoyer le SMS
        const smsResult = await sendVerificationCode(formattedPhone, code);

        // Réponse
        const response = {
            success: true,
            message: 'Code de vérification envoyé',
            phoneNumber: formattedPhone,
            expiresIn: 15 * 60, // 15 minutes en secondes
            twilioConfigured: isTwilioConfigured()
        };

        // En mode dev, inclure le code pour faciliter les tests
        if (smsResult.simulated) {
            response.devCode = code;
            response.simulated = true;
        }

        res.status(200).json(response);

    } catch (error) {
        console.error('Erreur lors de l\'envoi du code:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi du code de vérification',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * @route   POST /api/phone/verify-code
 * @desc    Vérifie le code et crée le compte si valide
 * @access  Public
 */
router.post('/verify-code', validateVerifyCode, async (req, res) => {
    try {
        const { phoneNumber, code } = req.body;

        if (!phoneNumber || !code) {
            return res.status(400).json({
                success: false,
                message: 'Le numéro de téléphone et le code sont requis'
            });
        }

        const formattedPhone = formatPhoneNumber(phoneNumber);

        // Vérifier le code
        const verificationResult = await PhoneVerification.verifyCode(formattedPhone, code);

        if (!verificationResult.success) {
            return res.status(400).json({
                success: false,
                message: verificationResult.message,
                expired: verificationResult.expired,
                maxAttempts: verificationResult.maxAttempts,
                attemptsRemaining: verificationResult.attemptsRemaining
            });
        }

        // Si des données d'inscription sont en attente, créer le compte
        if (verificationResult.pendingRegistration) {
            const { email, password, firstName, lastName, role, passwordHashed } = verificationResult.pendingRegistration;

            // Vérifier une dernière fois que l'email n'existe pas
            const existingUser = await User.findOne({ email });
            if (existingUser) {
                return res.status(409).json({
                    success: false,
                    message: 'Cet email est déjà utilisé'
                });
            }

            // Préparer les données utilisateur
            const userData = {
                email,
                password,
                firstName,
                lastName,
                phoneNumber: formattedPhone,
                phoneVerified: true,
                role,
                skipPasswordHash: passwordHashed === true, // Flag pour ne pas re-hasher le mdp
            };

            // Initialiser workerProfile pour les déneigeurs
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

            // Créer l'utilisateur
            const user = await User.create(userData);

            // Générer le token JWT
            const token = jwt.sign(
                { id: user._id, role: user.role },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRE || '7d' }
            );

            // Supprimer la vérification
            await PhoneVerification.deleteOne({ phoneNumber: formattedPhone });

            return res.status(201).json({
                success: true,
                message: 'Compte créé avec succès',
                accountCreated: true,
                token,
                user: {
                    id: user._id,
                    email: user.email,
                    name: `${user.firstName} ${user.lastName}`,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    phoneNumber: user.phoneNumber,
                    role: user.role,
                    photoUrl: user.photoUrl || null,
                    createdAt: user.createdAt
                }
            });
        }

        // Pas de données d'inscription, juste confirmation de vérification
        res.status(200).json({
            success: true,
            message: 'Numéro de téléphone vérifié avec succès',
            verified: true
        });

    } catch (error) {
        console.error('Erreur lors de la vérification:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la vérification du code',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * @route   POST /api/phone/resend-code
 * @desc    Renvoie un nouveau code de vérification
 * @access  Public
 */
router.post('/resend-code', smsLimiter, async (req, res) => {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({
                success: false,
                message: 'Le numéro de téléphone est requis'
            });
        }

        const formattedPhone = formatPhoneNumber(phoneNumber);

        // Vérifier si on peut renvoyer
        const canResend = await PhoneVerification.canResendCode(formattedPhone);
        if (!canResend.canResend) {
            return res.status(429).json({
                success: false,
                message: canResend.message,
                remainingSeconds: canResend.remainingSeconds
            });
        }

        // Récupérer les données d'inscription en attente
        const existingVerification = await PhoneVerification.findOne({ phoneNumber: formattedPhone });
        const pendingRegistration = existingVerification?.pendingRegistration;

        // Générer nouveau code
        const code = generateVerificationCode();

        // Mettre à jour
        await PhoneVerification.createOrUpdate(formattedPhone, code, pendingRegistration);

        // Envoyer le SMS
        const smsResult = await sendVerificationCode(formattedPhone, code);

        const response = {
            success: true,
            message: 'Nouveau code envoyé',
            expiresIn: 15 * 60
        };

        if (smsResult.simulated) {
            response.devCode = code;
            response.simulated = true;
        }

        res.status(200).json(response);

    } catch (error) {
        console.error('Erreur lors du renvoi:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du renvoi du code',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * @route   GET /api/phone/status/:phoneNumber
 * @desc    Vérifie le statut de vérification d'un numéro
 * @access  Public
 */
router.get('/status/:phoneNumber', async (req, res) => {
    try {
        const formattedPhone = formatPhoneNumber(req.params.phoneNumber);

        const verification = await PhoneVerification.findOne({ phoneNumber: formattedPhone });

        if (!verification) {
            return res.json({
                success: true,
                hasVerification: false
            });
        }

        res.json({
            success: true,
            hasVerification: true,
            verified: verification.verified,
            expired: new Date() > verification.expiresAt,
            attemptsRemaining: 3 - verification.attempts
        });

    } catch (error) {
        console.error('Erreur lors de la vérification du statut:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la vérification du statut'
        });
    }
});

/**
 * @route   POST /api/phone/send-change-code
 * @desc    Envoie un code de vérification pour changer de numéro de téléphone (utilisateur connecté)
 * @access  Private
 */
const { protect } = require('../middleware/auth');

router.post('/send-change-code', protect, smsLimiter, async (req, res) => {
    try {
        const { phoneNumber } = req.body;
        const userId = req.user.id;

        if (!phoneNumber) {
            return res.status(400).json({
                success: false,
                message: 'Le numéro de téléphone est requis'
            });
        }

        // Valider le format du numéro
        if (!isValidPhoneNumber(phoneNumber)) {
            return res.status(400).json({
                success: false,
                message: 'Format de numéro de téléphone invalide'
            });
        }

        const formattedPhone = formatPhoneNumber(phoneNumber);

        // Vérifier si le numéro est déjà utilisé par un autre compte
        const existingUser = await User.findOne({
            phoneNumber: formattedPhone,
            _id: { $ne: userId }
        });
        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: 'Ce numéro de téléphone est déjà associé à un autre compte'
            });
        }

        // Vérifier si on peut renvoyer un code
        const canResend = await PhoneVerification.canResendCode(formattedPhone);
        if (!canResend.canResend) {
            return res.status(429).json({
                success: false,
                message: canResend.message,
                remainingSeconds: canResend.remainingSeconds
            });
        }

        // Générer le code
        const code = generateVerificationCode();

        // Sauvegarder la vérification avec l'ID utilisateur pour le changement de numéro
        await PhoneVerification.createOrUpdate(formattedPhone, code, {
            isPhoneChange: true,
            userId: userId
        });

        // Envoyer le SMS
        const smsResult = await sendVerificationCode(formattedPhone, code);

        const response = {
            success: true,
            message: 'Code de vérification envoyé au nouveau numéro',
            phoneNumber: formattedPhone,
            expiresIn: 15 * 60,
            twilioConfigured: isTwilioConfigured()
        };

        if (smsResult.simulated) {
            response.devCode = code;
            response.simulated = true;
        }

        res.status(200).json(response);

    } catch (error) {
        console.error('Erreur lors de l\'envoi du code de changement:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi du code de vérification'
        });
    }
});

/**
 * @route   POST /api/phone/verify-change-code
 * @desc    Vérifie le code et met à jour le numéro de téléphone
 * @access  Private
 */
router.post('/verify-change-code', protect, async (req, res) => {
    try {
        const { phoneNumber, code } = req.body;
        const userId = req.user.id;

        if (!phoneNumber || !code) {
            return res.status(400).json({
                success: false,
                message: 'Le numéro de téléphone et le code sont requis'
            });
        }

        const formattedPhone = formatPhoneNumber(phoneNumber);

        // Vérifier le code
        const verificationResult = await PhoneVerification.verifyCode(formattedPhone, code);

        if (!verificationResult.success) {
            return res.status(400).json({
                success: false,
                message: verificationResult.message,
                expired: verificationResult.expired,
                maxAttempts: verificationResult.maxAttempts,
                attemptsRemaining: verificationResult.attemptsRemaining
            });
        }

        // Vérifier que c'est bien un changement de numéro pour cet utilisateur
        const pendingData = verificationResult.pendingRegistration;
        if (!pendingData?.isPhoneChange || pendingData?.userId !== userId) {
            return res.status(400).json({
                success: false,
                message: 'Vérification invalide pour ce compte'
            });
        }

        // Mettre à jour le numéro de téléphone de l'utilisateur
        const user = await User.findByIdAndUpdate(
            userId,
            {
                phoneNumber: formattedPhone,
                phoneVerified: true,
                updatedAt: Date.now()
            },
            { new: true }
        );

        // Supprimer la vérification
        await PhoneVerification.deleteOne({ phoneNumber: formattedPhone });

        res.status(200).json({
            success: true,
            message: 'Numéro de téléphone mis à jour avec succès',
            user: {
                id: user._id,
                email: user.email,
                name: `${user.firstName} ${user.lastName}`,
                firstName: user.firstName,
                lastName: user.lastName,
                phoneNumber: user.phoneNumber,
                role: user.role,
                photoUrl: user.photoUrl || null,
                createdAt: user.createdAt
            }
        });

    } catch (error) {
        console.error('Erreur lors de la vérification du changement:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la vérification du code'
        });
    }
});

module.exports = router;
