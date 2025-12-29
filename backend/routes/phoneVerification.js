/**
 * Routes pour la vérification de numéro de téléphone
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const PhoneVerification = require('../models/PhoneVerification');
const User = require('../models/User');
const {
    generateVerificationCode,
    formatPhoneNumber,
    isValidPhoneNumber,
    sendVerificationCode,
    isTwilioConfigured
} = require('../services/twilioService');

/**
 * @route   POST /api/phone/send-code
 * @desc    Envoie un code de vérification par SMS et stocke les données d'inscription
 * @access  Public
 */
router.post('/send-code', async (req, res) => {
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
        // Note: Ne pas hasher le mot de passe ici, le hook pre('save') du modèle User le fera
        let pendingRegistration = null;
        if (email && password && firstName && lastName) {
            pendingRegistration = {
                email: email.toLowerCase(),
                password: password, // Mot de passe en clair, sera haché par User.create()
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
router.post('/verify-code', async (req, res) => {
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
            const { email, password, firstName, lastName, role } = verificationResult.pendingRegistration;

            // Vérifier une dernière fois que l'email n'existe pas
            const existingUser = await User.findOne({ email });
            if (existingUser) {
                return res.status(409).json({
                    success: false,
                    message: 'Cet email est déjà utilisé'
                });
            }

            // Créer l'utilisateur
            const user = await User.create({
                email,
                password,
                firstName,
                lastName,
                phoneNumber: formattedPhone,
                phoneVerified: true,
                role
            });

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
                    firstName: user.firstName,
                    lastName: user.lastName,
                    phoneNumber: user.phoneNumber,
                    role: user.role
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
router.post('/resend-code', async (req, res) => {
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

module.exports = router;
