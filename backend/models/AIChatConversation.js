/**
 * Modèle Mongoose pour les conversations IA avec l'assistant Claude.
 * Gère l'historique des messages, le comptage de tokens et l'archivage automatique.
 */

const mongoose = require('mongoose');

// --- Sous-schéma pour les messages individuels ---

const aiMessageSchema = new mongoose.Schema({
    role: {
        type: String,
        enum: ['user', 'assistant'],
        required: true
    },
    content: {
        type: String,
        required: true,
        maxlength: 10000
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    metadata: {
        tokens: {
            input: { type: Number, default: 0 },
            output: { type: Number, default: 0 }
        },
        model: { type: String },
        simulated: { type: Boolean, default: false }
    }
}, { _id: true });

// --- Schéma principal ---

const aiChatConversationSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    title: {
        type: String,
        default: 'Nouvelle conversation',
        maxlength: 100
    },
    messages: [aiMessageSchema],
    context: {
        // Contexte optionnel lié à une réservation ou véhicule
        reservationId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Reservation'
        },
        vehicleId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Vehicle'
        }
    },
    status: {
        type: String,
        enum: ['active', 'archived'],
        default: 'active'
    },
    totalTokens: {
        input: { type: Number, default: 0 },
        output: { type: Number, default: 0 }
    },
    lastMessageAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// --- Index ---

aiChatConversationSchema.index({ userId: 1, lastMessageAt: -1 });

// TTL: Supprimer les conversations inactives après 30 jours
aiChatConversationSchema.index(
    { lastMessageAt: 1 },
    { expireAfterSeconds: 30 * 24 * 60 * 60 } // 30 jours
);

// --- Méthodes d'instance ---

/**
 * Génère un titre automatique basé sur le premier message utilisateur (max 50 caractères).
 * @returns {string} Le titre généré
 */
aiChatConversationSchema.methods.generateTitle = function() {
    if (this.messages.length > 0) {
        const firstUserMessage = this.messages.find(m => m.role === 'user');
        if (firstUserMessage) {
            // Prendre les 50 premiers caractères du premier message
            let title = firstUserMessage.content.substring(0, 50);
            if (firstUserMessage.content.length > 50) {
                title += '...';
            }
            this.title = title;
        }
    }
    return this.title;
};

/**
 * Ajoute un message à la conversation et met à jour les compteurs de tokens.
 * @param {string} role - Rôle de l'expéditeur ('user' ou 'assistant')
 * @param {string} content - Contenu du message
 * @param {Object} [metadata] - Métadonnées optionnelles (tokens, modèle)
 * @returns {Document} La conversation mise à jour
 */
aiChatConversationSchema.methods.addMessage = function(role, content, metadata = {}) {
    this.messages.push({
        role,
        content,
        timestamp: new Date(),
        metadata
    });

    // Mettre à jour les compteurs de tokens
    if (metadata.tokens) {
        this.totalTokens.input += metadata.tokens.input || 0;
        this.totalTokens.output += metadata.tokens.output || 0;
    }

    this.lastMessageAt = new Date();

    // Générer le titre si c'est le premier message utilisateur
    if (this.messages.filter(m => m.role === 'user').length === 1) {
        this.generateTitle();
    }

    return this;
};

/**
 * Récupère les derniers messages pour le contexte Claude
 * @param {number} limit - Nombre maximum de messages
 * @returns {Array} Messages formatés pour Claude
 */
aiChatConversationSchema.methods.getMessagesForClaude = function(limit = 20) {
    // Prendre les derniers messages, en gardant un nombre pair (user/assistant)
    const messages = this.messages.slice(-limit);

    return messages.map(m => ({
        role: m.role,
        content: m.content
    }));
};

// --- Méthodes statiques ---

/**
 * Récupère les conversations d'un utilisateur avec pagination.
 * @param {ObjectId} userId - Identifiant de l'utilisateur
 * @param {Object} [options] - Options { page, limit, status }
 * @returns {Query} Conversations triées par date du dernier message
 */
aiChatConversationSchema.statics.getUserConversations = function(userId, options = {}) {
    const { page = 1, limit = 20, status = 'active' } = options;

    return this.find({ userId, status })
        .sort({ lastMessageAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .select('title status lastMessageAt totalTokens createdAt')
        .lean();
};

/**
 * Compte les conversations d'un utilisateur filtrées par statut.
 * @param {ObjectId} userId - Identifiant de l'utilisateur
 * @param {string} [status='active'] - Statut des conversations à compter
 * @returns {Promise<number>} Nombre de conversations
 */
aiChatConversationSchema.statics.countUserConversations = function(userId, status = 'active') {
    return this.countDocuments({ userId, status });
};

/**
 * Archive automatiquement les conversations inactives depuis un nombre de jours donné.
 * @param {number} [daysOld=7] - Nombre de jours d'inactivité avant archivage
 * @returns {Promise<number>} Nombre de conversations archivées
 */
aiChatConversationSchema.statics.archiveOldConversations = async function(daysOld = 7) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await this.updateMany(
        {
            status: 'active',
            lastMessageAt: { $lt: cutoffDate }
        },
        {
            $set: { status: 'archived' }
        }
    );

    return result.modifiedCount;
};

const AIChatConversation = mongoose.model('AIChatConversation', aiChatConversationSchema);

module.exports = AIChatConversation;
