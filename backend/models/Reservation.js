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
        enum: ['pending', 'assigned', 'inProgress', 'completed', 'cancelled'],
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
        enum: ['pending', 'paid', 'failed', 'refunded'],
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
    },
}, {
    timestamps: true,
});




// Index pour recherche rapide
reservationSchema.index({ userId: 1, status: 1, departureTime: -1 });
reservationSchema.index({ workerId: 1, status: 1 });
reservationSchema.index({ departureTime: 1, status: 1 });

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
    if (!this.parkingSpotId && !this.parkingSpotNumber && !this.customLocation) {
        return next(new Error('Un emplacement doit être fourni (place de parking, numéro ou description)'));
    }
    next();
});

// Options pour inclure les virtuals dans JSON
reservationSchema.set('toJSON', { virtuals: true });
reservationSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Reservation', reservationSchema);