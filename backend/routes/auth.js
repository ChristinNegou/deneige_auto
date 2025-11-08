const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

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

        // Vérifier si l'utilisateur existe déjà
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: 'Cet email est déjà utilisé',
            });
        }

        // Créer l'utilisateur
        const user = await User.create({
            email,
            password,
            firstName,
            lastName,
            phoneNumber,
            role: role || 'client',
        });

        // Générer le token
        const token = generateToken(user._id, user.role);

        // Retourner la réponse
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

        // Validation
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Veuillez fournir un email et un mot de passe',
            });
        }

        // Chercher l'utilisateur avec le mot de passe
        const user = await User.findOne({ email }).select('+password');

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Email ou mot de passe incorrect',
            });
        }

        // Vérifier le mot de passe
        const isPasswordValid = await user.comparePassword(password);

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Email ou mot de passe incorrect',
            });
        }

        // Générer le token
        const token = generateToken(user._id, user.role);

        // Retourner la réponse
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
        // Dans une vraie application, vous pourriez invalider le token ici
        // ou ajouter le token à une liste noire
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