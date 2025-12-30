const mongoose = require('mongoose');

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

// Index pour la récupération des messages par réservation
messageSchema.index({ reservationId: 1, createdAt: 1 });

// Index pour les messages non lus
messageSchema.index({ reservationId: 1, senderId: 1, isRead: 1 });

// Méthode statique pour récupérer les messages d'une conversation
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

// Méthode statique pour marquer les messages comme lus
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

// Méthode statique pour compter les messages non lus
messageSchema.statics.countUnread = async function(reservationId, userId) {
    return this.countDocuments({
        reservationId,
        senderId: { $ne: userId },
        isRead: false,
    });
};

module.exports = mongoose.model('Message', messageSchema);
