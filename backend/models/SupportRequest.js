/**
 * Modèle Mongoose pour les demandes de support utilisateur.
 * Permet aux utilisateurs de signaler des bugs, poser des questions ou faire des suggestions.
 */

const mongoose = require('mongoose');

// --- Schéma principal ---

const supportRequestSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    userEmail: {
        type: String,
        required: true,
    },
    userName: {
        type: String,
        required: true,
    },
    subject: {
        type: String,
        enum: ['bug', 'question', 'suggestion', 'other'],
        required: [true, 'Le sujet est requis'],
    },
    message: {
        type: String,
        required: [true, 'Le message est requis'],
        minlength: [10, 'Le message doit contenir au moins 10 caractères'],
        maxlength: [2000, 'Le message ne peut pas dépasser 2000 caractères'],
    },
    status: {
        type: String,
        enum: ['pending', 'in_progress', 'resolved', 'closed'],
        default: 'pending',
    },
    adminNotes: {
        type: String,
        default: null,
    },
    resolvedAt: {
        type: Date,
        default: null,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
    updatedAt: {
        type: Date,
        default: Date.now,
    },
});

// --- Index ---

supportRequestSchema.index({ userId: 1, createdAt: -1 });

// Index pour l'admin (recherche par status)
supportRequestSchema.index({ status: 1, createdAt: -1 });

// --- Méthodes d'instance ---

/**
 * Retourne le libellé français du sujet de la demande.
 * @returns {string} Libellé du sujet
 */
supportRequestSchema.methods.getSubjectLabel = function () {
    const labels = {
        bug: 'Signalement de bug',
        question: 'Question',
        suggestion: 'Suggestion',
        other: 'Autre',
    };
    return labels[this.subject] || this.subject;
};

/**
 * Retourne le libellé français du statut de la demande.
 * @returns {string} Libellé du statut
 */
supportRequestSchema.methods.getStatusLabel = function () {
    const labels = {
        pending: 'En attente',
        in_progress: 'En cours',
        resolved: 'Résolu',
        closed: 'Fermé',
    };
    return labels[this.status] || this.status;
};

module.exports = mongoose.model('SupportRequest', supportRequestSchema);
