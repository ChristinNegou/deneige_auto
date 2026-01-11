const express = require('express');
const router = express.Router();
const SupportRequest = require('../models/SupportRequest');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { protect, authorize } = require('../middleware/auth');
const { sendEmail } = require('../config/email');

// Fonction pour échapper les caractères HTML (évite XSS)
const escapeHtml = (text) => {
    if (!text) return '';
    const htmlEntities = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;',
    };
    return text.replace(/[&<>"']/g, (char) => htmlEntities[char]);
};

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
            message: 'Erreur lors de l\'envoi de la demande',
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

        // Formater les données pour le frontend
        const formattedRequests = requests.map(request => ({
            _id: request._id,
            userId: request.userId?._id || request.userId,
            userEmail: request.userId?.email || request.userEmail,
            userName: request.userId
                ? `${request.userId.firstName} ${request.userId.lastName}`
                : request.userName,
            subject: request.subject,
            message: request.message,
            status: request.status,
            adminNotes: request.adminNotes,
            resolvedAt: request.resolvedAt,
            createdAt: request.createdAt,
            updatedAt: request.updatedAt,
        }));

        res.status(200).json({
            success: true,
            requests: formattedRequests,
            total,
            page: parseInt(page),
            totalPages: Math.ceil(total / limit),
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

// @route   POST /api/support/requests/:id/respond
// @desc    Répondre à une demande de support (Admin)
// @access  Private/Admin
router.post('/requests/:id/respond', protect, authorize('admin'), async (req, res) => {
    try {
        const { message, sendEmail: shouldSendEmail, sendNotification } = req.body;

        if (!message || message.trim().length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Le message de réponse est requis',
            });
        }

        const request = await SupportRequest.findById(req.params.id);

        if (!request) {
            return res.status(404).json({
                success: false,
                message: 'Demande non trouvée',
            });
        }

        // Mettre à jour le statut si en attente
        if (request.status === 'pending') {
            request.status = 'in_progress';
        }
        request.adminNotes = request.adminNotes
            ? `${request.adminNotes}\n\n[Réponse ${new Date().toLocaleDateString('fr-CA')}]: ${message}`
            : `[Réponse ${new Date().toLocaleDateString('fr-CA')}]: ${message}`;
        request.updatedAt = Date.now();
        await request.save();

        // Envoyer un email si demandé
        if (shouldSendEmail) {
            try {
                const html = `
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <style>
                            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                            .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f4f4f4; }
                            .email-content { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                            .header { text-align: center; color: #1E3A8A; margin-bottom: 30px; }
                            .message-box { background-color: #E8F4FD; border-left: 4px solid #3B82F6; padding: 15px; margin: 20px 0; }
                            .original-request { background-color: #F3F4F6; padding: 15px; border-radius: 8px; margin-top: 20px; }
                            .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <div class="email-content">
                                <div class="header">
                                    <h1>❄️ Déneige Auto</h1>
                                    <h2>Réponse à votre demande de support</h2>
                                </div>

                                <p>Bonjour <strong>${escapeHtml(request.userName)}</strong>,</p>

                                <p>Notre équipe de support a répondu à votre demande :</p>

                                <div class="message-box">
                                    <p>${escapeHtml(message).replace(/\n/g, '<br>')}</p>
                                </div>

                                <div class="original-request">
                                    <p><strong>Votre demande originale :</strong></p>
                                    <p><em>Sujet : ${escapeHtml(request.getSubjectLabel())}</em></p>
                                    <p>${escapeHtml(request.message)}</p>
                                </div>

                                <p>Si vous avez d'autres questions, n'hésitez pas à nous contacter.</p>

                                <div class="footer">
                                    <p>L'équipe Déneige Auto</p>
                                    <p>support@deneigeauto.com</p>
                                </div>
                            </div>
                        </div>
                    </body>
                    </html>
                `;

                await sendEmail({
                    email: request.userEmail,
                    subject: `📩 Réponse à votre demande de support - ${request.getSubjectLabel()}`,
                    html,
                });
            } catch (emailError) {
                console.error('Erreur lors de l\'envoi de l\'email:', emailError);
                // Continue même si l'email échoue
            }
        }

        // Créer une notification si demandé
        if (sendNotification) {
            try {
                await Notification.create({
                    userId: request.userId,
                    type: 'systemNotification',
                    title: 'Réponse du support',
                    message: message,
                    priority: 'normal',
                    metadata: {
                        supportRequestId: request._id,
                        subject: request.getSubjectLabel(),
                        originalMessage: request.message,
                    },
                });
            } catch (notifError) {
                console.error('Erreur lors de la création de la notification:', notifError);
            }
        }

        res.status(200).json({
            success: true,
            message: 'Réponse envoyée avec succès',
            data: request,
        });
    } catch (error) {
        console.error('Erreur lors de la réponse à la demande:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi de la réponse',
        });
    }
});

// @route   DELETE /api/support/requests/:id
// @desc    Supprimer une demande de support (Admin)
// @access  Private/Admin
router.delete('/requests/:id', protect, authorize('admin'), async (req, res) => {
    try {
        const request = await SupportRequest.findById(req.params.id);

        if (!request) {
            return res.status(404).json({
                success: false,
                message: 'Demande non trouvée',
            });
        }

        await SupportRequest.findByIdAndDelete(req.params.id);

        res.status(200).json({
            success: true,
            message: 'Demande supprimée avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de la suppression de la demande:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la suppression de la demande',
        });
    }
});

module.exports = router;
