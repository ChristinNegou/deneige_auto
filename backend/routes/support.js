const express = require('express');
const router = express.Router();
const SupportRequest = require('../models/SupportRequest');
const User = require('../models/User');
const { protect, authorize } = require('../middleware/auth');

// @route   POST /api/support/request
// @desc    Créer une nouvelle demande de support
// @access  Private
router.post('/request', protect, async (req, res) => {
    try {
        const { subject, message } = req.body;

        // Validation
        if (!subject || !message) {
            return res.status(400).json({
                success: false,
                message: 'Le sujet et le message sont requis',
            });
        }

        // Récupérer les infos de l'utilisateur
        const user = await User.findById(req.user.id);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Utilisateur non trouvé',
            });
        }

        // Créer la demande de support
        const supportRequest = await SupportRequest.create({
            userId: user._id,
            userEmail: user.email,
            userName: `${user.firstName} ${user.lastName}`,
            subject,
            message,
        });

        res.status(201).json({
            success: true,
            message: 'Votre demande a été envoyée avec succès',
            data: {
                id: supportRequest._id,
                subject: supportRequest.subject,
                subjectLabel: supportRequest.getSubjectLabel(),
                status: supportRequest.status,
                statusLabel: supportRequest.getStatusLabel(),
                createdAt: supportRequest.createdAt,
            },
        });
    } catch (error) {
        console.error('Erreur lors de la création de la demande de support:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Erreur lors de l\'envoi de la demande',
        });
    }
});

// @route   GET /api/support/my-requests
// @desc    Obtenir les demandes de support de l'utilisateur
// @access  Private
router.get('/my-requests', protect, async (req, res) => {
    try {
        const requests = await SupportRequest.find({ userId: req.user.id })
            .sort({ createdAt: -1 })
            .limit(20);

        const formattedRequests = requests.map(request => ({
            id: request._id,
            subject: request.subject,
            subjectLabel: request.getSubjectLabel(),
            message: request.message,
            status: request.status,
            statusLabel: request.getStatusLabel(),
            adminNotes: request.adminNotes,
            createdAt: request.createdAt,
            resolvedAt: request.resolvedAt,
        }));

        res.status(200).json({
            success: true,
            count: formattedRequests.length,
            data: formattedRequests,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des demandes:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des demandes',
        });
    }
});

// @route   GET /api/support/requests
// @desc    Obtenir toutes les demandes de support (Admin)
// @access  Private/Admin
router.get('/requests', protect, authorize('admin'), async (req, res) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;

        const query = {};
        if (status) {
            query.status = status;
        }

        const requests = await SupportRequest.find(query)
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit))
            .populate('userId', 'firstName lastName email phoneNumber');

        const total = await SupportRequest.countDocuments(query);

        res.status(200).json({
            success: true,
            count: requests.length,
            total,
            totalPages: Math.ceil(total / limit),
            currentPage: parseInt(page),
            data: requests,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des demandes:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des demandes',
        });
    }
});

// @route   PUT /api/support/requests/:id
// @desc    Mettre à jour le statut d'une demande (Admin)
// @access  Private/Admin
router.put('/requests/:id', protect, authorize('admin'), async (req, res) => {
    try {
        const { status, adminNotes } = req.body;

        const updateData = {
            updatedAt: Date.now(),
        };

        if (status) {
            updateData.status = status;
            if (status === 'resolved') {
                updateData.resolvedAt = Date.now();
            }
        }

        if (adminNotes !== undefined) {
            updateData.adminNotes = adminNotes;
        }

        const request = await SupportRequest.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true }
        );

        if (!request) {
            return res.status(404).json({
                success: false,
                message: 'Demande non trouvée',
            });
        }

        res.status(200).json({
            success: true,
            data: request,
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de la demande:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour de la demande',
        });
    }
});

module.exports = router;
