const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const userSchema = new mongoose.Schema({
    email: {
        type: String,
        required: [true, 'L\'email est requis'],
        unique: true,
        lowercase: true,
        trim: true,
        match: [/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/, 'Email invalide'],
    },
    password: {
        type: String,
        required: [true, 'Le mot de passe est requis'],
        minlength: [6, 'Le mot de passe doit contenir au moins 6 caractères'],
        select: false,
    },
    firstName: {
        type: String,
        required: [true, 'Le prénom est requis'],
        trim: true,
    },
    lastName: {
        type: String,
        required: [true, 'Le nom est requis'],
        trim: true,
    },
    phoneNumber: {
        type: String,
        required: [true, 'Le numéro de téléphone est requis'],
        trim: true,
        index: true,
    },
    phoneVerified: {
        type: Boolean,
        default: false,
    },
    role: {
        type: String,
        enum: ['client', 'snowWorker', 'admin'],
        default: 'client',
    },
    stripeCustomerId: {
        type: String,
        default: null,
    },
    photoUrl: {
        type: String,
    },
    isActive: {
        type: Boolean,
        default: true,
    },
    // Suspension fields (for all user types)
    isSuspended: {
        type: Boolean,
        default: false,
    },
    suspendedUntil: {
        type: Date,
        default: null,
    },
    suspensionReason: {
        type: String,
        default: null,
    },
    // Firebase Cloud Messaging token for push notifications
    fcmToken: {
        type: String,
        default: null,
    },
    // Notification preferences
    notificationSettings: {
        pushEnabled: {
            type: Boolean,
            default: true,
        },
        emailEnabled: {
            type: Boolean,
            default: true,
        },
        smsEnabled: {
            type: Boolean,
            default: false,
        },
    },

    // Worker-specific profile (only used when role === 'snowWorker')
    workerProfile: {
        isAvailable: {
            type: Boolean,
            default: false,
        },
        currentLocation: {
            type: {
                type: String,
                enum: ['Point'],
                default: 'Point',
            },
            coordinates: {
                type: [Number], // [longitude, latitude]
                default: [0, 0],
            },
        },
        preferredZones: [{
            name: {
                type: String,
                required: true,
            },
            centerLat: {
                type: Number,
                required: true,
            },
            centerLng: {
                type: Number,
                required: true,
            },
            radiusKm: {
                type: Number,
                default: 5,
            },
        }],
        maxActiveJobs: {
            type: Number,
            default: 3,
        },
        vehicleType: {
            type: String,
            enum: ['car', 'truck', 'atv', 'other'],
            default: 'car',
        },
        equipmentList: [{
            type: String,
        }],

        // Worker statistics
        totalJobsCompleted: {
            type: Number,
            default: 0,
        },
        totalEarnings: {
            type: Number,
            default: 0,
        },
        totalTipsReceived: {
            type: Number,
            default: 0,
        },
        averageRating: {
            type: Number,
            default: 0,
            min: 0,
            max: 5,
        },
        totalRatingsCount: {
            type: Number,
            default: 0,
        },

        // Payout information
        stripeConnectId: {
            type: String,
        },
        bankAccountLast4: {
            type: String,
        },

        // Cancellation tracking (suivi des annulations)
        totalCancellations: {
            type: Number,
            default: 0,
        },
        cancellationHistory: [{
            reservationId: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Reservation',
            },
            reason: {
                type: String,
                required: true,
            },
            cancelledAt: {
                type: Date,
                default: Date.now,
            },
        }],
        warningCount: {
            type: Number,
            default: 0,
        },
        isSuspended: {
            type: Boolean,
            default: false,
        },
        suspendedUntil: {
            type: Date,
            default: null,
        },
        suspensionReason: {
            type: String,
            default: null,
        },
    },

    resetPasswordToken: String,
    resetPasswordExpire: Date,
    createdAt: {
        type: Date,
        default: Date.now,
    },
    updatedAt: {
        type: Date,
        default: Date.now,
    },
});

// Geospatial index for worker location queries
userSchema.index({ 'workerProfile.currentLocation': '2dsphere' });

// Hash le mot de passe avant de sauvegarder
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) {
        return next();
    }

    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Méthode pour comparer les mots de passe
userSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

// Générer et hasher le token de réinitialisation de mot de passe
userSchema.methods.getResetPasswordToken = function () {
    // Générer un token aléatoire
    const resetToken = crypto.randomBytes(32).toString('hex');

    // Hasher le token et le stocker dans la base de données
    this.resetPasswordToken = crypto
        .createHash('sha256')
        .update(resetToken)
        .digest('hex');

    // Définir l'expiration du token (10 minutes)
    this.resetPasswordExpire = Date.now() + 10 * 60 * 1000;

    return resetToken;
};

// Méthode pour obtenir l'objet utilisateur sans le mot de passe
userSchema.methods.toJSON = function () {
    const user = this.toObject();
    delete user.password;
    delete user.resetPasswordToken;
    delete user.resetPasswordExpire;
    delete user.__v;
    return user;
};

module.exports = mongoose.model('User', userSchema);