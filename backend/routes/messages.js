const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Message = require('../models/Message');
const Reservation = require('../models/Reservation');
const Notification = require('../models/Notification');

// @route   GET /api/messages/:reservationId
// @desc    Récupérer les messages d'une conversation
// @access  Private (Client ou Worker de la réservation)
router.get('/:reservationId', protect, async (req, res) => {
    try {
        const { reservationId } = req.params;
        const { before } = req.query;
        const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 100);
        if (!mongoose.isValidObjectId(reservationId)) {
            return res.status(404).json({ success: false, message: 'Réservation non trouvée' });
        }

        // Vérifier que l'utilisateur a accès à cette réservation
        const reservation = await Reservation.findById(reservationId);
        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        const isClient = reservation.userId.toString() === req.user.id;
        const isWorker = reservation.workerId?.toString() === req.user.id;

        if (!isClient && !isWorker) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé à cette conversation',
            });
        }

        // Récupérer les messages
        const messages = await Message.getConversation(reservationId, {
            limit,
            before: before ? new Date(before) : null,
        });

        // Marquer les messages comme lus
        await Message.markAsRead(reservationId, req.user.id);

        res.status(200).json({
            success: true,
            messages: messages.reverse(), // Ordre chronologique
            hasMore: messages.length === limit,
        });

    } catch (error) {
        console.error('Erreur récupération messages:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des messages',
        });
    }
});

// @route   POST /api/messages/:reservationId
// @desc    Envoyer un message dans une conversation
// @access  Private (Client ou Worker de la réservation)
router.post('/:reservationId', protect, async (req, res) => {
    try {
        const { reservationId } = req.params;
        const { messageType = 'text', imageUrl, location } = req.body;
        const content = typeof req.body.content === 'string' ? req.body.content.trim() : '';

        if (!['text', 'image', 'location'].includes(messageType)) {
            return res.status(400).json({ success: false, message: 'Type de message invalide' });
        }
        if (messageType === 'text' && !content) {
            return res.status(400).json({
                success: false,
                message: 'Le contenu du message est requis',
            });
        }
        if (content.length > 1000) {
            return res.status(400).json({ success: false, message: 'Le message ne peut pas dépasser 1000 caractères' });
        }
        if (!mongoose.isValidObjectId(reservationId)) {
            return res.status(404).json({ success: false, message: 'Réservation non trouvée' });
        }

        // Vérifier que l'utilisateur a accès à cette réservation
        const reservation = await Reservation.findById(reservationId)
            .populate('userId', 'firstName lastName')
            .populate('workerId', 'firstName lastName');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        const isClient = reservation.userId._id.toString() === req.user.id;
        const isWorker = reservation.workerId?._id.toString() === req.user.id;

        if (!isClient && !isWorker) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé à cette conversation',
            });
        }

        // Il faut un deneigeur pour qu'il y ait une conversation
        if (!reservation.workerId) {
            return res.status(400).json({
                success: false,
                message: 'Le chat sera disponible quand un déneigeur aura accepté la réservation',
            });
        }

        // Vérifier que la réservation est dans un état permettant le chat
        const allowedStatuses = ['assigned', 'enRoute', 'inProgress'];
        if (!allowedStatuses.includes(reservation.status)) {
            return res.status(400).json({
                success: false,
                message: 'Le chat n\'est plus disponible pour cette réservation',
                currentStatus: reservation.status,
                allowedStatuses: allowedStatuses,
            });
        }

        // Créer le message
        const message = await Message.create({
            reservationId,
            senderId: req.user.id,
            senderRole: isClient ? 'client' : 'worker',
            content: content || (messageType === 'image' ? 'Photo' : 'Position'),
            messageType,
            imageUrl: messageType === 'image' ? imageUrl : null,
            location: messageType === 'location' ? location : null,
        });

        // Récupérer le message avec les infos du sender
        const populatedMessage = await Message.findById(message._id)
            .populate('senderId', 'firstName lastName profilePhoto');

        // Déterminer le destinataire
        const recipientId = isClient ? reservation.workerId._id : reservation.userId._id;
        const senderName = isClient
            ? `${reservation.userId.firstName}`
            : `${reservation.workerId.firstName}`;

        // Notification (et push) pour le destinataire
        const preview = message.content;
        await Notification.createNotification({
            userId: recipientId,
            type: 'newMessage',
            title: 'Nouveau message',
            message: `${senderName}: ${preview.substring(0, 80)}${preview.length > 80 ? '…' : ''}`,
            priority: 'normal',
            reservationId: reservation._id,
            metadata: {
                messageId: message._id,
                senderRole: isClient ? 'client' : 'worker',
                senderName: senderName,
            },
        });

        // Émettre l'événement Socket.IO (si le socket est disponible)
        const io = req.app.get('io');
        if (io) {
            try {
                // Envoyer au room de la réservation
                io.to(`reservation:${reservationId}`).emit('message:new', {
                    message: populatedMessage,
                });

                // Aussi envoyer au destinataire spécifiquement
                io.to(`user:${recipientId}`).emit('message:new', {
                    message: populatedMessage,
                    reservationId,
                });
            } catch (socketError) {
                console.error('[Socket.IO] Erreur émission message:new:', {
                    reservationId,
                    recipientId,
                    error: socketError.message,
                });
            }
        } else {
            console.warn('[Socket.IO] Socket non disponible pour message:new');
        }

        res.status(201).json({
            success: true,
            message: populatedMessage,
        });

    } catch (error) {
        console.error('Erreur envoi message:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi du message',
        });
    }
});

// @route   GET /api/messages/:reservationId/unread
// @desc    Compter les messages non lus
// @access  Private
router.get('/:reservationId/unread', protect, async (req, res) => {
    try {
        const { reservationId } = req.params;

        // Vérifier l'accès
        const reservation = await Reservation.findById(reservationId);
        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        const isClient = reservation.userId.toString() === req.user.id;
        const isWorker = reservation.workerId?.toString() === req.user.id;

        if (!isClient && !isWorker) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé',
            });
        }

        const unreadCount = await Message.countUnread(reservationId, req.user.id);

        res.status(200).json({
            success: true,
            unreadCount,
        });

    } catch (error) {
        console.error('Erreur comptage messages:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du comptage des messages',
        });
    }
});

// @route   PATCH /api/messages/:reservationId/read
// @desc    Marquer tous les messages comme lus
// @access  Private
router.patch('/:reservationId/read', protect, async (req, res) => {
    try {
        const { reservationId } = req.params;

        // Vérifier l'accès
        const reservation = await Reservation.findById(reservationId);
        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        const isClient = reservation.userId.toString() === req.user.id;
        const isWorker = reservation.workerId?.toString() === req.user.id;

        if (!isClient && !isWorker) {
            return res.status(403).json({
                success: false,
                message: 'Accès non autorisé',
            });
        }

        const result = await Message.markAsRead(reservationId, req.user.id);

        // Émettre l'événement de lecture
        const io = req.app.get('io');
        if (io) {
            try {
                io.to(`reservation:${reservationId}`).emit('message:read', {
                    readerId: req.user.id,
                    reservationId,
                });
            } catch (socketError) {
                console.error('[Socket.IO] Erreur émission message:read:', {
                    reservationId,
                    error: socketError.message,
                });
            }
        }

        res.status(200).json({
            success: true,
            markedCount: result.modifiedCount,
        });

    } catch (error) {
        console.error('Erreur marquage messages:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du marquage des messages',
        });
    }
});

module.exports = router;
