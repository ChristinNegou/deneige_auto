const mongoose = require('mongoose');

const reservationSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: [true, 'L\'utilisateur est requis'],
    },
    vehicle: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Vehicle',
        required: [true, 'Le véhicule est requis'],
    },
    parkingSpot: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'ParkingSpot',
        default: null,
    },
    parkingSpotNumber: {
        type: String,
        trim: true,
        uppercase: true,
        default: null,
    },
    customLocation: {
        type: String,
        trim: true,
        default: null,
    },

    workerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null,
    },
    departureTime: {
        type: Date,
        required: [true, 'L\'heure de départ est requise'],
    },
    deadlineTime: {
        type: Date,
        required: [true, 'L\'heure limite est requise'],
    },
    status: {
        type: String,
        enum: ['pending', 'assigned', 'enRoute', 'inProgress', 'completed', 'cancelled'],
        default: 'pending',
    },
    serviceOptions: [{
        type: String,
        enum: ['windowScraping', 'doorDeicing', 'wheelClearance'],
    }],
    snowDepthCm: {
        type: Number,
        min: 0,
        default: null,
    },
    basePrice: {
        type: Number,
        required: [true, 'Le prix de base est requis'],
        min: 0,
    },
    totalPrice: {
        type: Number,
        required: [true, 'Le prix total est requis'],
        min: 0,
    },
    isPriority: {
        type: Boolean,
        default: false,
    },
    urgencyMultiplier: {
        type: Number,
        default: 1.0,
        min: 1.0,
    },
    paymentMethod: {
        type: String,
        enum: ['card', 'cash', 'subscription'],
        required: [true, 'La méthode de paiement est requise'],
    },
    paymentStatus: {
        type: String,
        enum: ['pending', 'paid', 'failed', 'refunded', 'partially_refunded'],
        default: 'pending',
    },
    paymentIntentId: {
        type: String,
        default: null,
    },
    completedAt: {
        type: Date,
        default: null,
    },
    cancelledAt: {
        type: Date,
        default: null,
    },
    cancelReason: {
        type: String,
        default: null,
    },
    cancelledBy: {
        type: String,
        enum: ['client', 'worker', 'system', null],
        default: null,
    },
    // Frais d'annulation facturés au client
    cancellationFee: {
        amount: {
            type: Number,
            default: 0,
        },
        percentage: {
            type: Number,
            default: 0,
        },
        charged: {
            type: Boolean,
            default: false,
        },
        chargedAt: {
            type: Date,
            default: null,
        },
    },
    // Montant remboursé au client
    refundAmount: {
        type: Number,
        default: 0,
    },
    refundedAt: {
        type: Date,
        default: null,
    },
    notes: {
        type: String,
        trim: true,
    },
    workerNotes: {
        type: String,
        trim: true,
    },
    photos: [{
        url: String,
        uploadedAt: {
            type: Date,
            default: Date.now,
        },
        type: {
            type: String,
            enum: ['before', 'after'],
        },
    }],
    rating: {
        type: Number,
        min: 1,
        max: 5,
        default: null,
    },
    review: {
        type: String,
        trim: true,
        maxlength: 500,
    },
    ratedAt: {
        type: Date,
        default: null,
    },

    // Tip from client to worker
    tip: {
        amount: {
            type: Number,
            default: 0,
            min: 0,
        },
        paidAt: {
            type: Date,
            default: null,
        },
        paymentIntentId: {
            type: String,
            default: null,
        },
    },

    // Payout information (versement au déneigeur)
    payout: {
        status: {
            type: String,
            enum: ['pending', 'pending_account', 'pending_payment', 'processing', 'completed', 'paid', 'failed'],
            default: 'pending',
        },
        workerAmount: {
            type: Number,
            default: 0,
        },
        platformFee: {
            type: Number,
            default: 0,
        },
        tipAmount: {
            type: Number,
            default: 0,
        },
        stripeFee: {
            type: Number,
            default: 0,
        },
        stripeTransferId: {
            type: String,
            default: null,
        },
        processedAt: {
            type: Date,
            default: null,
        },
        paidAt: {
            type: Date,
            default: null,
        },
        note: {
            type: String,
            default: null,
        },
        error: {
            type: String,
            default: null,
        },
    },

    // Tip amount (pourboire - montant simple pour faciliter les calculs)
    tipAmount: {
        type: Number,
        default: 0,
        min: 0,
    },

    // Geolocation for proximity-based job discovery
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point',
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            default: [0, 0],
        },
        address: {
            type: String,
            trim: true,
        },
    },

    // Worker tracking timestamps
    assignedAt: {
        type: Date,
        default: null,
    },
    workerEnRouteAt: {
        type: Date,
        default: null,
    },
    workerArrivedAt: {
        type: Date,
        default: null,
    },
    startedAt: {
        type: Date,
        default: null,
    },
    estimatedArrivalTime: {
        type: Date,
        default: null,
    },

    // Worker's last known location during job
    workerLocation: {
        type: {
            type: String,
            enum: ['Point'],
        },
        coordinates: {
            type: [Number],
        },
    },

    // Equipment required for this job (computed from service options and snow depth)
    requiredEquipment: [{
        type: String,
        enum: ['shovel', 'brush', 'ice_scraper', 'salt_spreader', 'snow_blower'],
    }],

    // ============== DISPUTE & VERIFICATION TRACKING ==============

    // Litige associé
    dispute: {
        hasDispute: {
            type: Boolean,
            default: false,
        },
        disputeId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Dispute',
        },
        disputeType: String,
        disputeStatus: String,
        disputeOpenedAt: Date,
        disputeResolvedAt: Date,
    },

    // No-show tracking
    noShow: {
        reported: {
            type: Boolean,
            default: false,
        },
        reportedAt: Date,
        reportedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        confirmed: {
            type: Boolean,
            default: false,
        },
        confirmedAt: Date,
    },

    // Vérification de qualité du travail
    qualityVerification: {
        // Vérification GPS - worker était-il vraiment sur place?
        gpsVerified: {
            type: Boolean,
            default: false,
        },
        gpsData: [{
            coordinates: [Number], // [longitude, latitude]
            timestamp: Date,
            accuracy: Number, // en mètres
            event: {
                type: String,
                enum: ['enRoute', 'arrived', 'workStarted', 'workCompleted'],
            },
        }],
        distanceFromJobSite: Number, // distance en mètres au moment de la completion

        // Vérification du temps
        timeVerification: {
            expectedDuration: Number, // en minutes
            actualDuration: Number,   // en minutes
            isSuspicious: {
                type: Boolean,
                default: false,
            },
            suspiciousReason: String,
        },

        // Vérification des photos
        photoVerification: {
            beforePhotoCount: {
                type: Number,
                default: 0,
            },
            afterPhotoCount: {
                type: Number,
                default: 0,
            },
            photosValidated: {
                type: Boolean,
                default: false,
            },
            validationNotes: String,
        },

        // Score de qualité pour cette réservation (0-100)
        qualityScore: {
            type: Number,
            min: 0,
            max: 100,
        },

        // Client confirmation
        clientConfirmed: {
            type: Boolean,
            default: false,
        },
        clientConfirmedAt: Date,
        clientSatisfied: {
            type: Boolean,
            default: null,
        },
    },

    // Tracking de ponctualité
    punctuality: {
        scheduledArrival: Date,      // Heure d'arrivée prévue
        actualArrival: Date,         // Heure d'arrivée réelle
        delayMinutes: {
            type: Number,
            default: 0,
        },
        isLate: {
            type: Boolean,
            default: false,
        },
        lateNotified: {              // Worker a-t-il notifié son retard?
            type: Boolean,
            default: false,
        },
        lateReason: String,
    },

    // Flags d'alerte
    flags: {
        suspiciousActivity: {
            type: Boolean,
            default: false,
        },
        requiresReview: {
            type: Boolean,
            default: false,
        },
        flagReasons: [String],
        flaggedAt: Date,
        reviewedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        reviewedAt: Date,
        reviewNotes: String,
    },
}, {
    timestamps: true,
});




// ============================================
// INDEX OPTIMIZATIONS
// ============================================

// Index composés pour les requêtes fréquentes
reservationSchema.index({ userId: 1, status: 1, departureTime: -1 });
reservationSchema.index({ workerId: 1, status: 1 });
reservationSchema.index({ departureTime: 1, status: 1 });
reservationSchema.index({ status: 1, createdAt: -1 }); // Pour admin dashboard
reservationSchema.index({ paymentStatus: 1, status: 1 }); // Pour rapports paiements
reservationSchema.index({ 'payout.status': 1, workerId: 1 }); // Pour versements workers

// Index pour requêtes de date (rapports, stats)
reservationSchema.index({ createdAt: -1 });
reservationSchema.index({ completedAt: -1 });

// Index pour recherche par paymentIntentId (webhooks Stripe)
reservationSchema.index({ paymentIntentId: 1 }, { sparse: true });

// Index pour les disputes
reservationSchema.index({ 'dispute.hasDispute': 1, 'dispute.disputeStatus': 1 });

// Index pour jobs expirés (cron job)
reservationSchema.index({ status: 1, deadlineTime: 1 });

// Geospatial index for location-based job discovery
reservationSchema.index({ 'location': '2dsphere' });

// Méthode virtuelle pour savoir si c'est urgent
reservationSchema.virtual('isUrgent').get(function() {
    const now = new Date();
    const hoursUntilDeparture = (this.departureTime - now) / (1000 * 60 * 60);
    return hoursUntilDeparture < 4; // Moins de 4 heures
});

// Méthode virtuelle pour l'icône du statut
reservationSchema.virtual('statusIcon').get(function() {
    const icons = {
        pending: '⏳',
        assigned: '👷',
        enRoute: '🚗',
        inProgress: '🚧',
        completed: '✅',
        cancelled: '❌',
    };
    return icons[this.status] || '❓';
});

// Méthode virtuelle pour le nom d'affichage du statut
reservationSchema.virtual('statusDisplayName').get(function() {
    const names = {
        pending: 'En attente',
        assigned: 'Assignée',
        enRoute: 'En route',
        inProgress: 'En cours',
        completed: 'Terminée',
        cancelled: 'Annulée',
    };
    return names[this.status] || 'Inconnu';
});

// Middleware pour calculer le prix en fonction de l'urgence
reservationSchema.pre('save', function(next) {
    if (this.isModified('isPriority') || this.isModified('basePrice')) {
        if (this.isPriority) {
            this.urgencyMultiplier = 1.4; // +40%
            this.totalPrice = this.basePrice * this.urgencyMultiplier;
        }
    }
    next();
});

// Middleware pour calculer l'équipement requis
reservationSchema.pre('save', function(next) {
    // Base equipment always required
    const required = ['shovel', 'brush'];

    // Check service options
    if (this.serviceOptions && this.serviceOptions.length > 0) {
        if (this.serviceOptions.includes('windowScraping')) {
            required.push('ice_scraper');
        }
        if (this.serviceOptions.includes('doorDeicing')) {
            required.push('salt_spreader');
        }
    }

    // Check snow depth - heavy snow requires snow blower
    if (this.snowDepthCm && this.snowDepthCm > 15) {
        required.push('snow_blower');
    }

    this.requiredEquipment = [...new Set(required)]; // Remove duplicates
    next();
});

// Méthode statique pour obtenir les réservations à venir
reservationSchema.statics.getUpcoming = function(userId) {
    return this.find({
        userId,
        status: { $in: ['pending', 'assigned', 'inProgress'] },
        departureTime: { $gte: new Date() },
    })
        .populate('vehicleId')
        .populate('parkingSpotId')
        .populate('workerId', 'firstName lastName phoneNumber')
        .sort({ departureTime: 1 });
};

// Validation: au moins un emplacement doit être défini
reservationSchema.pre('save', function(next) {
    if (!this.parkingSpot && !this.parkingSpotNumber && !this.customLocation) {
        return next(new Error('Un emplacement doit être fourni (place de parking, numéro ou description)'));
    }
    next();
});

// Options pour inclure les virtuals dans JSON
reservationSchema.set('toJSON', { virtuals: true });
reservationSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Reservation', reservationSchema);