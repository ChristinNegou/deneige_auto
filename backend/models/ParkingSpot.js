const mongoose = require('mongoose');

const parkingSpotSchema = new mongoose.Schema({
    spotNumber: {
        type: String,
        required: [true, 'Le numéro de place est requis'],
        unique: true,
        trim: true,
    },
    level: {
        type: String,
        enum: ['underground', 'ground', 'covered', 'outdoor'],
        required: [true, 'Le niveau est requis'],
        default: 'outdoor',
    },
    section: {
        type: String,
        trim: true,
    },
    isAvailable: {
        type: Boolean,
        default: true,
    },
    assignedTo: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null,
    },
    dimensions: {
        length: {
            type: Number,
            default: 5.0, // mètres
        },
        width: {
            type: Number,
            default: 2.5, // mètres
        },
    },
    hasRoof: {
        type: Boolean,
        default: false,
    },
    notes: {
        type: String,
        trim: true,
    },
    priceAdjustment: {
        type: Number,
        default: 0, // Ajustement de prix (+/-)
    },
}, {
    timestamps: true,
});

// Index pour recherche rapide
//parkingSpotSchema.index({ spotNumber: 1 });
parkingSpotSchema.index({ assignedTo: 1 });
parkingSpotSchema.index({ isAvailable: 1, level: 1 });

// Méthode virtuelle pour le nom d'affichage
parkingSpotSchema.virtual('displayName').get(function() {
    return `Place ${this.spotNumber}${this.section ? ` - ${this.section}` : ''}`;
});

// Méthode virtuelle pour l'icône selon le niveau
parkingSpotSchema.virtual('icon').get(function() {
    const icons = {
        underground: '🅿️',
        ground: '🏢',
        covered: '🏠',
        outdoor: '🌳',
    };
    return icons[this.level] || '🅿️';
});

// Méthode virtuelle pour le nom d'affichage du niveau
parkingSpotSchema.virtual('levelDisplayName').get(function() {
    const names = {
        underground: 'Souterrain',
        ground: 'Rez-de-chaussée',
        covered: 'Couvert',
        outdoor: 'Extérieur',
    };
    return names[this.level] || 'Inconnu';
});

// Options pour inclure les virtuals dans JSON
parkingSpotSchema.set('toJSON', { virtuals: true });
parkingSpotSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('ParkingSpot', parkingSpotSchema);