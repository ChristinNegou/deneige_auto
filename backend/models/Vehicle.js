/**
 * Modèle Mongoose pour les véhicules des clients.
 * Stocke les informations du véhicule (marque, modèle, plaque) et le véhicule par défaut.
 */

const mongoose = require('mongoose');

// --- Schéma principal ---

const vehicleSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: [true, 'L\'utilisateur est requis'],
    },
    make: {
        type: String,
        required: [true, 'La marque est requise'],
        trim: true,
    },
    model: {
        type: String,
        required: [true, 'Le modèle est requis'],
        trim: true,
    },
    year: {
        type: Number,
        required: [true, 'L\'année est requise'],
        min: [1900, 'Année invalide'],
        max: [new Date().getFullYear() + 1, 'Année invalide'],
    },
    color: {
        type: String,
        required: [true, 'La couleur est requise'],
        trim: true,
    },
    licensePlate: {
        type: String,
        required: [true, 'La plaque d\'immatriculation est requise'],
        trim: true,
        uppercase: true,
    },
    type: {
        type: String,
        enum: ['sedan', 'suv', 'truck', 'van', 'coupe', 'hatchback', 'car'],
        required: [true, 'Le type de véhicule est requis'],
        default: 'sedan',
    },
    photoUrl: {
        type: String,
        default: null,
    },
    isDefault: {
        type: Boolean,
        default: false,
    },
    isActive: {
        type: Boolean,
        default: true,
    },
}, {
    timestamps: true,
});

// --- Index ---

vehicleSchema.index({ userId: 1, isActive: 1 });
vehicleSchema.index({ licensePlate: 1 });

// --- Propriétés virtuelles ---

vehicleSchema.virtual('displayName').get(function() {
    return `${this.make} ${this.model} (${this.year})`;
});

// Méthode pour obtenir l'émoji selon le type
vehicleSchema.virtual('icon').get(function() {
    const icons = {
        sedan: '🚗',
        suv: '🚙',
        truck: '🛻',
        van: '🚐',
        coupe: '🏎️',
        hatchback: '🚗',
        car: '🚗',

    };
    return icons[this.type] || '🚗';
});

// --- Middleware pre-save ---

// S'assure qu'un seul véhicule par défaut existe par utilisateur
vehicleSchema.pre('save', async function(next) {
    if (this.isDefault && this.isModified('isDefault')) {
        await this.constructor.updateMany(
            { userId: this.userId, _id: { $ne: this._id } },
            { isDefault: false }
        );
    }
    next();
});

// Options pour inclure les virtuals dans JSON
vehicleSchema.set('toJSON', { virtuals: true });
vehicleSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Vehicle', vehicleSchema);