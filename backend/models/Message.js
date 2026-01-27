/**
 * Modèle Mongoose pour les messages de chat entre client et déneigeur.
 * Supporte les messages texte, images, localisation et messages système.
 */

const mongoose = require('mongoose');

// --- Schéma principal ---

const messageSchema = new mongoose.Schema({
    reservationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reservation',
        required: true,
        index: true,
    },
    senderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    senderRole: {
        type: String,
        enum: ['client', 'worker'],
        required: true,
    },
    content: {
        type: String,
        required: true,
        maxlength: 1000,
        trim: true,
    },
    messageType: {
        type: String,
        enum: ['text', 'image', 'location', 'system'],
        default: 'text',
    },
    imageUrl: {
        type: String,
        default: null,
    },
    location: {
        latitude: Number,
        longitude: Number,
    },
    isRead: {
        type: Boolean,
        default: false,
    },
    readAt: {
        type: Date,
        default: null,
    },
}, {
    timestamps: true,
});

// --- Index ---

messageSchema.index({ reservationId: 1, createdAt: 1 });

// Index pour les messages non lus
messageSchema.index({ reservationId: 1, senderId: 1, isRead: 1 });

// --- Méthodes statiques ---

/**
 * Récupère les messages d'une conversation liée à une réservation, avec pagination par curseur.
 * @param {ObjectId} reservationId - Identifiant de la réservation
 * @param {Object} [options] - Options de pagination { limit, before }
 * @returns {Promise<Array>} Messages triés du plus récent au plus ancien
 */
messageSchema.statics.getConversation = async function(reservationId, options = {}) {
    const { limit = 50, before = null } = options;

    const query = { reservationId };
    if (before) {
        query.createdAt = { $lt: before };
    }

    return this.find(query)
        .sort({ createdAt: -1 })
        .limit(limit)
        .populate('senderId', 'firstName lastName profilePhoto')
        .lean();
};

/**
 * Marque tous les messages non lus d'un autre expéditeur comme lus.
 * @param {ObjectId} reservationId - Identifiant de la réservation
 * @param {ObjectId} readerId - Identifiant du lecteur (messages de l'autre partie)
 * @returns {Promise<Object>} Résultat de la mise à jour
 */
messageSchema.statics.markAsRead = async function(reservationId, readerId) {
    return this.updateMany(
        {
            reservationId,
            senderId: { $ne: readerId },
            isRead: false,
        },
        {
            isRead: true,
            readAt: new Date(),
        }
    );
};

/**
 * Compte les messages non lus envoyés par l'autre partie.
 * @param {ObjectId} reservationId - Identifiant de la réservation
 * @param {ObjectId} userId - Identifiant de l'utilisateur qui lit
 * @returns {Promise<number>} Nombre de messages non lus
 */
messageSchema.statics.countUnread = async function(reservationId, userId) {
    return this.countDocuments({
        reservationId,
        senderId: { $ne: userId },
        isRead: false,
    });
};

module.exports = mongoose.model('Message', messageSchema);
