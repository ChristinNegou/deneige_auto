/**
 * Modèle pour stocker les codes de vérification téléphonique
 */

const mongoose = require('mongoose');

const phoneVerificationSchema = new mongoose.Schema({
    phoneNumber: {
        type: String,
        required: [true, 'Le numéro de téléphone est requis'],
        trim: true,
        index: true,
    },
    code: {
        type: String,
        required: [true, 'Le code de vérification est requis'],
    },
    expiresAt: {
        type: Date,
        required: true,
        default: () => new Date(Date.now() + 15 * 60 * 1000), // 15 minutes
        index: { expires: 0 } // TTL index - suppression auto après expiration
    },
    attempts: {
        type: Number,
        default: 0,
        max: [3, 'Nombre maximum de tentatives atteint']
    },
    verified: {
        type: Boolean,
        default: false
    },
    // Données d'inscription en attente
    pendingRegistration: {
        email: String,
        password: String, // Hashé
        firstName: String,
        lastName: String,
        role: {
            type: String,
            enum: ['client', 'snowWorker'],
            default: 'client'
        }
    },
    lastSentAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// Index composé pour recherche rapide
phoneVerificationSchema.index({ phoneNumber: 1, verified: 1 });

// Méthode statique pour créer ou mettre à jour une vérification
phoneVerificationSchema.statics.createOrUpdate = async function(phoneNumber, code, pendingRegistration = null) {
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    const update = {
        code,
        expiresAt,
        attempts: 0,
        verified: false,
        lastSentAt: new Date()
    };

    if (pendingRegistration) {
        update.pendingRegistration = pendingRegistration;
    }

    return await this.findOneAndUpdate(
        { phoneNumber },
        update,
        { upsert: true, new: true }
    );
};

// Méthode statique pour vérifier un code
phoneVerificationSchema.statics.verifyCode = async function(phoneNumber, code) {
    const verification = await this.findOne({
        phoneNumber,
        verified: false
    });

    if (!verification) {
        return {
            success: false,
            message: 'Aucune demande de vérification en cours pour ce numéro'
        };
    }

    // Vérifier expiration
    if (new Date() > verification.expiresAt) {
        return {
            success: false,
            message: 'Le code a expiré. Veuillez en demander un nouveau.',
            expired: true
        };
    }

    // Vérifier nombre de tentatives
    if (verification.attempts >= 3) {
        return {
            success: false,
            message: 'Trop de tentatives. Veuillez demander un nouveau code.',
            maxAttempts: true
        };
    }

    // Incrémenter les tentatives
    verification.attempts += 1;

    // Vérifier le code
    if (verification.code !== code) {
        await verification.save();
        const remaining = 3 - verification.attempts;
        return {
            success: false,
            message: `Code incorrect. ${remaining} tentative(s) restante(s).`,
            attemptsRemaining: remaining
        };
    }

    // Code valide
    verification.verified = true;
    await verification.save();

    return {
        success: true,
        message: 'Numéro vérifié avec succès',
        pendingRegistration: verification.pendingRegistration
    };
};

// Méthode statique pour vérifier si on peut renvoyer un code
phoneVerificationSchema.statics.canResendCode = async function(phoneNumber) {
    const verification = await this.findOne({ phoneNumber });

    if (!verification) {
        return { canResend: true };
    }

    const timeSinceLastSent = Date.now() - verification.lastSentAt.getTime();
    const waitTime = 60 * 1000; // 60 secondes

    if (timeSinceLastSent < waitTime) {
        const remainingSeconds = Math.ceil((waitTime - timeSinceLastSent) / 1000);
        return {
            canResend: false,
            message: `Veuillez attendre ${remainingSeconds} secondes avant de renvoyer`,
            remainingSeconds
        };
    }

    return { canResend: true };
};

module.exports = mongoose.model('PhoneVerification', phoneVerificationSchema);
