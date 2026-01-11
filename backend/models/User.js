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
        match: [/^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$/, 'Email invalide'],
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
    // User preferences (app settings)
    userPreferences: {
        soundEnabled: {
            type: Boolean,
            default: true,
        },
        darkThemeEnabled: {
            type: Boolean,
            default: true,
        },
    },

    // Client-specific tracking (anti-abus et historique)
    clientProfile: {
        // Historique des annulations
        totalCancellations: {
            type: Number,
            default: 0,
        },
        lateCancellations: {
            type: Number,
            default: 0, // Annulations après que le worker soit en route
        },
        cancellationHistory: [{
            reservationId: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Reservation',
            },
            status: String, // Status de la réservation au moment de l'annulation
            fee: Number,
            cancelledAt: {
                type: Date,
                default: Date.now,
            },
        }],

        // Historique des litiges
        totalDisputes: {
            type: Number,
            default: 0,
        },
        disputesWon: {
            type: Number,
            default: 0,
        },
        disputesLost: {
            type: Number,
            default: 0,
        },

        // No-shows signalés
        noShowReports: {
            type: Number,
            default: 0,
        },

        // Avertissements
        warningCount: {
            type: Number,
            default: 0,
        },
        warnings: [{
            reason: String,
            issuedAt: {
                type: Date,
                default: Date.now,
            },
            issuedBy: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User',
            },
        }],

        // Score de fiabilité (0-100)
        reliabilityScore: {
            type: Number,
            default: 100,
            min: 0,
            max: 100,
        },

        // Statistiques
        totalReservations: {
            type: Number,
            default: 0,
        },
        completedReservations: {
            type: Number,
            default: 0,
        },
        totalSpent: {
            type: Number,
            default: 0,
        },

        // Chargebacks Stripe
        chargebackCount: {
            type: Number,
            default: 0,
        },
        chargebackHistory: [{
            stripeDisputeId: String,
            amount: Number,
            status: String,
            reason: String,
            createdAt: Date,
            resolvedAt: Date,
        }],
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
        // Worker notification preferences
        notificationPreferences: {
            newJobs: {
                type: Boolean,
                default: true,
            },
            urgentJobs: {
                type: Boolean,
                default: true,
            },
            tips: {
                type: Boolean,
                default: true,
            },
        },

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

        // Tracking des no-shows
        noShowCount: {
            type: Number,
            default: 0,
        },
        noShowHistory: [{
            reservationId: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Reservation',
            },
            reportedAt: {
                type: Date,
                default: Date.now,
            },
            disputeId: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Dispute',
            },
            resolved: {
                type: Boolean,
                default: false,
            },
            resolution: String, // 'confirmed', 'dismissed', 'pending'
        }],

        // Tracking des litiges
        totalDisputes: {
            type: Number,
            default: 0,
        },
        disputesAgainst: {
            type: Number,
            default: 0, // Litiges ouverts contre ce worker
        },
        disputesWon: {
            type: Number,
            default: 0,
        },
        disputesLost: {
            type: Number,
            default: 0,
        },

        // Retards
        lateArrivals: {
            type: Number,
            default: 0,
        },
        onTimePercentage: {
            type: Number,
            default: 100,
            min: 0,
            max: 100,
        },

        // Score de fiabilité (0-100)
        reliabilityScore: {
            type: Number,
            default: 100,
            min: 0,
            max: 100,
        },

        // Qualité du travail
        qualityScore: {
            type: Number,
            default: 100,
            min: 0,
            max: 100,
        },
        qualityComplaints: {
            type: Number,
            default: 0,
        },
    },

    resetPasswordToken: String,
    resetPasswordExpire: Date,
    resetTokenUsed: {
        type: Boolean,
        default: false,
    },
    // Refresh token pour JWT
    refreshToken: {
        type: String,
        select: false, // Ne pas inclure par défaut dans les requêtes
    },
    refreshTokenExpire: {
        type: Date,
        select: false,
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

// Geospatial index for worker location queries
userSchema.index({ 'workerProfile.currentLocation': '2dsphere' });

// Performance indexes for common queries
// Note: email index is auto-created by unique: true in schema
userSchema.index({ role: 1 });                                         // Role-based queries
userSchema.index({ role: 1, 'workerProfile.isAvailable': 1 });         // Admin: available workers
userSchema.index({ role: 1, 'workerProfile.totalJobsCompleted': -1 }); // Admin: top workers ranking
userSchema.index({ role: 1, isActive: 1 });                            // Active users by role

// Hash le mot de passe avant de sauvegarder
userSchema.pre('save', async function (next) {
    // Ne pas hasher si le mot de passe n'a pas été modifié
    if (!this.isModified('password')) {
        return next();
    }

    // Ne pas re-hasher si le flag skipPasswordHash est défini
    // (cas où le mot de passe vient de phoneVerification déjà hashé)
    if (this.skipPasswordHash) {
        this.skipPasswordHash = undefined; // Supprimer le flag temporaire
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

    // Réinitialiser le flag "utilisé" pour ce nouveau token
    this.resetTokenUsed = false;

    return resetToken;
};

// Générer un refresh token
userSchema.methods.generateRefreshToken = function () {
    const refreshToken = crypto.randomBytes(40).toString('hex');

    // Hasher le refresh token pour le stocker
    this.refreshToken = crypto
        .createHash('sha256')
        .update(refreshToken)
        .digest('hex');

    // Expiration dans 30 jours
    this.refreshTokenExpire = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    return refreshToken;
};

// Vérifier un refresh token
userSchema.methods.verifyRefreshToken = function (candidateToken) {
    const hashedToken = crypto
        .createHash('sha256')
        .update(candidateToken)
        .digest('hex');

    return this.refreshToken === hashedToken && this.refreshTokenExpire > Date.now();
};

// Invalider le refresh token (logout)
userSchema.methods.invalidateRefreshToken = function () {
    this.refreshToken = undefined;
    this.refreshTokenExpire = undefined;
};

// Méthode pour obtenir l'objet utilisateur sans le mot de passe
userSchema.methods.toJSON = function () {
    const user = this.toObject();
    delete user.password;
    delete user.resetPasswordToken;
    delete user.resetPasswordExpire;
    delete user.refreshToken;
    delete user.refreshTokenExpire;
    delete user.__v;
    return user;
};

module.exports = mongoose.model('User', userSchema);