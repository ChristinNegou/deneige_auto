const mongoose = require('mongoose');

const disputeSchema = new mongoose.Schema({
    // Type de litige
    type: {
        type: String,
        enum: [
            'no_show',           // Déneigeur pas venu
            'incomplete_work',   // Travail incomplet
            'quality_issue',     // Qualité du travail insuffisante
            'late_arrival',      // Retard significatif
            'damage',            // Dommage causé
            'wrong_location',    // Travail fait au mauvais endroit
            'overcharge',        // Surfacturation
            'unprofessional',    // Comportement non professionnel
            'payment_issue',     // Problème de paiement
            'other'              // Autre
        ],
        required: [true, 'Le type de litige est requis'],
    },

    // Réservation concernée
    reservation: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reservation',
        required: [true, 'La réservation est requise'],
    },

    // Qui a ouvert le litige
    claimant: {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        role: {
            type: String,
            enum: ['client', 'worker'],
            required: true,
        },
    },

    // Contre qui est le litige
    respondent: {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        role: {
            type: String,
            enum: ['client', 'worker'],
            required: true,
        },
    },

    // Statut du litige
    status: {
        type: String,
        enum: [
            'open',              // Ouvert - en attente de traitement
            'under_review',      // En cours d'examen par l'admin
            'pending_response',  // En attente de réponse du défendeur
            'resolved',          // Résolu
            'closed',            // Fermé sans action
            'appealed',          // En appel
            'escalated'          // Escaladé (cas graves)
        ],
        default: 'open',
    },

    // Priorité
    priority: {
        type: String,
        enum: ['low', 'medium', 'high', 'urgent'],
        default: 'medium',
    },

    // Description du problème
    description: {
        type: String,
        required: [true, 'La description est requise'],
        minlength: [20, 'La description doit contenir au moins 20 caractères'],
        maxlength: [2000, 'La description ne peut pas dépasser 2000 caractères'],
    },

    // Preuves fournies par le plaignant
    evidence: {
        photos: [{
            url: String,
            uploadedAt: {
                type: Date,
                default: Date.now,
            },
            description: String,
        }],
        // Données GPS au moment de la plainte
        gpsData: {
            claimantLocation: {
                type: {
                    type: String,
                    enum: ['Point'],
                },
                coordinates: [Number], // [longitude, latitude]
            },
            timestamp: Date,
        },
        // Timestamps importants
        timestamps: {
            reservationCreated: Date,
            workerAssigned: Date,
            workerEnRoute: Date,
            workerArrived: Date,
            workStarted: Date,
            workCompleted: Date,
            disputeOpened: Date,
        },
        // Autres documents/preuves
        documents: [{
            url: String,
            type: String,
            uploadedAt: {
                type: Date,
                default: Date.now,
            },
        }],
    },

    // Réponse du défendeur
    response: {
        text: {
            type: String,
            maxlength: 2000,
        },
        submittedAt: Date,
        photos: [{
            url: String,
            uploadedAt: {
                type: Date,
                default: Date.now,
            },
            description: String,
        }],
    },

    // Montant demandé (remboursement)
    claimedAmount: {
        type: Number,
        default: 0,
        min: 0,
    },

    // Résolution
    resolution: {
        decision: {
            type: String,
            enum: [
                'favor_claimant',      // En faveur du plaignant
                'favor_respondent',    // En faveur du défendeur
                'partial_refund',      // Remboursement partiel
                'full_refund',         // Remboursement complet
                'no_action',           // Aucune action
                'mutual_agreement',    // Accord mutuel
                'escalated_external'   // Escaladé à l'externe
            ],
        },
        refundAmount: {
            type: Number,
            default: 0,
        },
        workerPenalty: {
            type: String,
            enum: ['none', 'warning', 'suspension_3days', 'suspension_7days', 'suspension_30days', 'permanent_ban'],
            default: 'none',
        },
        clientPenalty: {
            type: String,
            enum: ['none', 'warning', 'suspension_7days', 'suspension_30days', 'permanent_ban'],
            default: 'none',
        },
        notes: String,
        resolvedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        resolvedAt: Date,
        refundProcessed: {
            type: Boolean,
            default: false,
        },
        refundProcessedAt: Date,
        stripeRefundId: String,
    },

    // Appel
    appeal: {
        isAppealed: {
            type: Boolean,
            default: false,
        },
        appealedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        appealReason: String,
        appealedAt: Date,
        appealResolution: {
            decision: String,
            notes: String,
            resolvedBy: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User',
            },
            resolvedAt: Date,
        },
    },

    // Notes internes admin
    adminNotes: [{
        note: String,
        addedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        addedAt: {
            type: Date,
            default: Date.now,
        },
    }],

    // Historique des actions
    history: [{
        action: {
            type: String,
            enum: [
                'created',
                'status_changed',
                'evidence_added',
                'response_submitted',
                'admin_note_added',
                'resolution_proposed',
                'resolved',
                'appealed',
                'appeal_resolved',
                'escalated',
                'refund_processed'
            ],
        },
        details: String,
        performedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        performedAt: {
            type: Date,
            default: Date.now,
        },
    }],

    // Stripe chargeback info (si applicable)
    stripeDispute: {
        disputeId: String,
        status: String,
        amount: Number,
        reason: String,
        createdAt: Date,
        evidenceSubmittedAt: Date,
        resolvedAt: Date,
    },

    // Délais
    deadlines: {
        responseDeadline: Date,       // Date limite pour réponse du défendeur
        resolutionDeadline: Date,     // Date limite pour résolution
        appealDeadline: Date,         // Date limite pour appel
    },

    // Notifications envoyées
    notificationsSent: {
        claimantNotified: {
            type: Boolean,
            default: false,
        },
        respondentNotified: {
            type: Boolean,
            default: false,
        },
        adminNotified: {
            type: Boolean,
            default: false,
        },
    },

    // Auto-resolution flags
    autoResolution: {
        eligible: {
            type: Boolean,
            default: false,
        },
        reason: String,
        processedAt: Date,
    },

}, {
    timestamps: true,
});

// Index pour recherche rapide
disputeSchema.index({ status: 1, priority: -1, createdAt: -1 });
disputeSchema.index({ 'claimant.user': 1, status: 1 });
disputeSchema.index({ 'respondent.user': 1, status: 1 });
disputeSchema.index({ reservation: 1 });
disputeSchema.index({ type: 1, status: 1 });

// Méthode pour ajouter à l'historique
disputeSchema.methods.addHistory = function(action, details, userId) {
    this.history.push({
        action,
        details,
        performedBy: userId,
        performedAt: new Date(),
    });
};

// Méthode pour ajouter une note admin
disputeSchema.methods.addAdminNote = function(note, adminId) {
    this.adminNotes.push({
        note,
        addedBy: adminId,
        addedAt: new Date(),
    });
    this.addHistory('admin_note_added', note.substring(0, 100), adminId);
};

// Méthode pour vérifier si le litige peut être résolu automatiquement
disputeSchema.methods.checkAutoResolution = function() {
    // No-show automatique si le worker n'a jamais marqué "en route"
    if (this.type === 'no_show') {
        const timestamps = this.evidence?.timestamps || {};
        if (!timestamps.workerEnRoute && !timestamps.workerArrived) {
            this.autoResolution.eligible = true;
            this.autoResolution.reason = 'Worker never marked as en route or arrived';
            return true;
        }
    }
    return false;
};

// Méthode statique pour obtenir les statistiques des litiges
disputeSchema.statics.getStats = async function() {
    const stats = await this.aggregate([
        {
            $group: {
                _id: '$status',
                count: { $sum: 1 },
            },
        },
    ]);

    const typeStats = await this.aggregate([
        {
            $group: {
                _id: '$type',
                count: { $sum: 1 },
            },
        },
    ]);

    return { byStatus: stats, byType: typeStats };
};

// Virtuals
disputeSchema.virtual('isOverdue').get(function() {
    if (this.deadlines?.resolutionDeadline) {
        return new Date() > this.deadlines.resolutionDeadline &&
               !['resolved', 'closed'].includes(this.status);
    }
    return false;
});

disputeSchema.virtual('responseOverdue').get(function() {
    if (this.deadlines?.responseDeadline && !this.response?.submittedAt) {
        return new Date() > this.deadlines.responseDeadline;
    }
    return false;
});

// Options pour inclure les virtuals dans JSON
disputeSchema.set('toJSON', { virtuals: true });
disputeSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Dispute', disputeSchema);
