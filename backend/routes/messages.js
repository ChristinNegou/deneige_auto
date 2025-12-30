const express = require('express');
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
        const { limit = 50, before } = req.query;

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
            limit: parseInt(limit),
            before: before ? new Date(before) : null,
        });

        // Marquer les messages comme lus
        await Message.markAsRead(reservationId, req.user.id);

        res.status(200).json({
            success: true,
            messages: messages.reverse(), // Ordre chronologique
            hasMore: messages.length === parseInt(limit),
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
        const { content, messageType = 'text', imageUrl, location } = req.body;

        if (!content && messageType === 'text') {
            return res.status(400).json({
                success: false,
                message: 'Le contenu du message est requis',
            });
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

        // Vérifier que la réservation est dans un état permettant le chat
        const allowedStatuses = ['pending', 'assigned', 'en-route', 'in-progress'];
        if (!allowedStatuses.includes(reservation.status)) {
            return res.status(400).json({
                success: false,
                message: 'Le chat n\'est plus disponible pour cette réservation',
            });
        }

        // Créer le message
        const message = await Message.create({
            reservationId,
            senderId: req.user.id,
            senderRole: isClient ? 'client' : 'worker',
            content,
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

        // Créer une notification pour le destinataire
        await Notification.create({
            userId: recipientId,
            type: 'newMessage',
            title: 'Nouveau message',
            message: `${senderName}: ${content.substring(0, 50)}${content.length > 50 ? '...' : ''}`,
            priority: 'normal',
            reservationId: reservation._id,
            metadata: {
                messageId: message._id,
                senderRole: isClient ? 'client' : 'worker',
            },
        });

        // Émettre l'événement Socket.IO (si le socket est disponible)
        const io = req.app.get('io');
        if (io) {
            // Envoyer au room de la réservation
            io.to(`reservation:${reservationId}`).emit('message:new', {
                message: populatedMessage,
            });

            // Aussi envoyer au destinataire spécifiquement
            io.to(`user:${recipientId}`).emit('message:new', {
                message: populatedMessage,
                reservationId,
            });
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
            io.to(`reservation:${reservationId}`).emit('message:read', {
                readerId: req.user.id,
                reservationId,
            });
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
