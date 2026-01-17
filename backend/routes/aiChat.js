/**
 * Routes pour le chat IA avec Claude
 */

const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const { protect } = require('../middleware/auth');
const AIChatConversation = require('../models/AIChatConversation');
const Vehicle = require('../models/Vehicle');
const Reservation = require('../models/Reservation');
const { generateResponse, generateStreamingResponse, isClaudeConfigured, isAIEnabled } = require('../services/claudeService');
const { buildUserContext, welcomeMessages, getQuickActionsForRole } = require('../config/aiPrompts');

// Rate limiter spécifique pour le chat IA
const aiChatLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 20, // 20 messages par minute
    message: {
        success: false,
        message: 'Trop de messages envoyés. Veuillez patienter avant de réessayer.',
        code: 'RATE_LIMITED'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// Middleware pour vérifier si l'IA est activée
const checkAIEnabled = (req, res, next) => {
    if (!isAIEnabled()) {
        return res.status(503).json({
            success: false,
            message: 'Les fonctionnalités IA sont temporairement désactivées',
            code: 'AI_DISABLED'
        });
    }
    next();
};

// @route   GET /api/ai-chat/status
// @desc    Vérifier le statut du service IA
// @access  Private
router.get('/status', protect, (req, res) => {
    res.json({
        success: true,
        enabled: isAIEnabled(),
        configured: isClaudeConfigured(),
        quickActions: getQuickActionsForRole(req.user.role)
    });
});

// @route   GET /api/ai-chat/conversations
// @desc    Récupérer les conversations de l'utilisateur
// @access  Private
router.get('/conversations', protect, async (req, res) => {
    try {
        const { page = 1, limit = 20, status = 'active' } = req.query;

        const conversations = await AIChatConversation.getUserConversations(
            req.user.id,
            { page: parseInt(page), limit: parseInt(limit), status }
        );

        const total = await AIChatConversation.countUserConversations(req.user.id, status);

        res.json({
            success: true,
            conversations,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / parseInt(limit))
            }
        });
    } catch (error) {
        console.error('Erreur récupération conversations IA:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des conversations'
        });
    }
});

// @route   POST /api/ai-chat/conversations
// @desc    Créer une nouvelle conversation
// @access  Private
router.post('/conversations', protect, checkAIEnabled, async (req, res) => {
    try {
        const { context = {} } = req.body;

        // Créer la conversation
        const conversation = await AIChatConversation.create({
            userId: req.user.id,
            context: {
                reservationId: context.reservationId || null,
                vehicleId: context.vehicleId || null
            }
        });

        // Ajouter un message de bienvenue de l'assistant
        const welcomeMessage = welcomeMessages[Math.floor(Math.random() * welcomeMessages.length)];
        conversation.addMessage('assistant', welcomeMessage, {
            simulated: true,
            model: 'system'
        });

        await conversation.save();

        res.status(201).json({
            success: true,
            conversation: {
                id: conversation._id,
                title: conversation.title,
                messages: conversation.messages,
                createdAt: conversation.createdAt
            },
            quickActions: getQuickActionsForRole(req.user.role)
        });
    } catch (error) {
        console.error('Erreur création conversation IA:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la création de la conversation'
        });
    }
});

// @route   GET /api/ai-chat/conversations/:id
// @desc    Récupérer une conversation spécifique
// @access  Private
router.get('/conversations/:id', protect, async (req, res) => {
    try {
        const conversation = await AIChatConversation.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!conversation) {
            return res.status(404).json({
                success: false,
                message: 'Conversation non trouvée'
            });
        }

        res.json({
            success: true,
            conversation: {
                id: conversation._id,
                title: conversation.title,
                messages: conversation.messages,
                context: conversation.context,
                totalTokens: conversation.totalTokens,
                createdAt: conversation.createdAt,
                lastMessageAt: conversation.lastMessageAt
            }
        });
    } catch (error) {
        console.error('Erreur récupération conversation IA:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de la conversation'
        });
    }
});

// @route   POST /api/ai-chat/conversations/:id/messages
// @desc    Envoyer un message dans une conversation
// @access  Private
router.post('/conversations/:id/messages', protect, checkAIEnabled, aiChatLimiter, async (req, res) => {
    try {
        const { content } = req.body;

        // Validation du contenu
        if (!content || typeof content !== 'string') {
            return res.status(400).json({
                success: false,
                message: 'Le contenu du message est requis'
            });
        }

        if (content.length > 2000) {
            return res.status(400).json({
                success: false,
                message: 'Le message ne peut pas dépasser 2000 caractères'
            });
        }

        // Récupérer la conversation
        const conversation = await AIChatConversation.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!conversation) {
            return res.status(404).json({
                success: false,
                message: 'Conversation non trouvée'
            });
        }

        // Ajouter le message utilisateur
        conversation.addMessage('user', content.trim());

        // Construire le contexte utilisateur
        const [vehicles, reservations] = await Promise.all([
            Vehicle.find({ userId: req.user.id }).lean(),
            Reservation.find({
                userId: req.user.id,
                status: { $in: ['pending', 'assigned', 'enRoute', 'inProgress'] }
            }).lean()
        ]);

        const userContext = buildUserContext(
            req.user,
            vehicles,
            reservations,
            null // TODO: Intégrer la météo si disponible
        );

        // Préparer les messages pour Claude
        const messagesForClaude = conversation.getMessagesForClaude(20);

        // Générer la réponse IA
        const result = await generateResponse(messagesForClaude, userContext);

        if (!result.success) {
            // En cas d'erreur, ne pas perdre le message utilisateur
            await conversation.save();

            return res.status(503).json({
                success: false,
                message: result.error || 'Erreur lors de la génération de la réponse',
                code: result.code,
                userMessageSaved: true
            });
        }

        // Ajouter la réponse de l'assistant
        conversation.addMessage('assistant', result.response, {
            tokens: {
                input: result.usage?.inputTokens || 0,
                output: result.usage?.outputTokens || 0
            },
            model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
            simulated: result.simulated || false
        });

        await conversation.save();

        // Émettre via Socket.IO si disponible
        const io = req.app.get('io');
        if (io) {
            try {
                io.to(`user:${req.user.id}`).emit('ai:message:new', {
                    conversationId: conversation._id,
                    message: conversation.messages[conversation.messages.length - 1]
                });
            } catch (socketError) {
                console.error('[Socket.IO] Erreur émission ai:message:new:', socketError.message);
            }
        }

        res.json({
            success: true,
            message: conversation.messages[conversation.messages.length - 1],
            usage: result.usage,
            simulated: result.simulated
        });

    } catch (error) {
        console.error('Erreur envoi message IA:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi du message'
        });
    }
});

// @route   POST /api/ai-chat/conversations/:id/messages/stream
// @desc    Envoyer un message avec réponse en streaming
// @access  Private
router.post('/conversations/:id/messages/stream', protect, checkAIEnabled, aiChatLimiter, async (req, res) => {
    try {
        const { content } = req.body;

        // Validation
        if (!content || typeof content !== 'string' || content.length > 2000) {
            return res.status(400).json({
                success: false,
                message: 'Contenu invalide (requis, max 2000 caractères)'
            });
        }

        // Récupérer la conversation
        const conversation = await AIChatConversation.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!conversation) {
            return res.status(404).json({
                success: false,
                message: 'Conversation non trouvée'
            });
        }

        // Ajouter le message utilisateur
        conversation.addMessage('user', content.trim());

        // Construire le contexte
        const [vehicles, reservations] = await Promise.all([
            Vehicle.find({ userId: req.user.id }).lean(),
            Reservation.find({
                userId: req.user.id,
                status: { $in: ['pending', 'assigned', 'enRoute', 'inProgress'] }
            }).lean()
        ]);

        const userContext = buildUserContext(req.user, vehicles, reservations, null);
        const messagesForClaude = conversation.getMessagesForClaude(20);

        // Configurer le streaming SSE
        res.setHeader('Content-Type', 'text/event-stream');
        res.setHeader('Cache-Control', 'no-cache');
        res.setHeader('Connection', 'keep-alive');
        res.setHeader('X-Accel-Buffering', 'no');

        // Callback pour chaque chunk
        const onChunk = (text) => {
            res.write(`data: ${JSON.stringify({ type: 'chunk', text })}\n\n`);
        };

        // Générer la réponse en streaming
        const result = await generateStreamingResponse(messagesForClaude, userContext, onChunk);

        if (!result.success) {
            res.write(`data: ${JSON.stringify({ type: 'error', error: result.error })}\n\n`);
            res.end();
            await conversation.save();
            return;
        }

        // Ajouter la réponse complète à la conversation
        conversation.addMessage('assistant', result.response, {
            tokens: {
                input: result.usage?.inputTokens || 0,
                output: result.usage?.outputTokens || 0
            },
            model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
            simulated: result.simulated || false
        });

        await conversation.save();

        // Envoyer l'événement de fin
        res.write(`data: ${JSON.stringify({
            type: 'done',
            messageId: conversation.messages[conversation.messages.length - 1]._id,
            usage: result.usage
        })}\n\n`);

        res.end();

    } catch (error) {
        console.error('Erreur streaming message IA:', error);
        res.write(`data: ${JSON.stringify({ type: 'error', error: 'Erreur serveur' })}\n\n`);
        res.end();
    }
});

// @route   DELETE /api/ai-chat/conversations/:id
// @desc    Supprimer/archiver une conversation
// @access  Private
router.delete('/conversations/:id', protect, async (req, res) => {
    try {
        const conversation = await AIChatConversation.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!conversation) {
            return res.status(404).json({
                success: false,
                message: 'Conversation non trouvée'
            });
        }

        // Archiver au lieu de supprimer (pour audit)
        conversation.status = 'archived';
        await conversation.save();

        res.json({
            success: true,
            message: 'Conversation archivée'
        });
    } catch (error) {
        console.error('Erreur suppression conversation IA:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la suppression de la conversation'
        });
    }
});

// @route   GET /api/ai-chat/conversations/:id/messages
// @desc    Récupérer l'historique des messages d'une conversation
// @access  Private
router.get('/conversations/:id/messages', protect, async (req, res) => {
    try {
        const { limit = 50, before } = req.query;

        const conversation = await AIChatConversation.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!conversation) {
            return res.status(404).json({
                success: false,
                message: 'Conversation non trouvée'
            });
        }

        let messages = conversation.messages;

        // Filtrer par date si spécifié
        if (before) {
            const beforeDate = new Date(before);
            messages = messages.filter(m => m.timestamp < beforeDate);
        }

        // Limiter le nombre de messages
        messages = messages.slice(-parseInt(limit));

        res.json({
            success: true,
            messages,
            hasMore: messages.length === parseInt(limit)
        });
    } catch (error) {
        console.error('Erreur récupération messages IA:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des messages'
        });
    }
});

module.exports = router;
