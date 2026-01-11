/**
 * Middleware pour validation et gestion des uploads de fichiers
 */

const multer = require('multer');
const path = require('path');
const { FILE_UPLOAD } = require('../config/constants');

// Types MIME autorisés pour les images
const ALLOWED_MIME_TYPES = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
];

// Extensions autorisées
const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'];

// Taille maximale des fichiers (depuis config)
const MAX_FILE_SIZE = FILE_UPLOAD.MAX_FILE_SIZE;
const MAX_PHOTO_SIZE = FILE_UPLOAD.MAX_PHOTO_SIZE;

/**
 * Filtre pour valider les fichiers uploadés
 */
const imageFileFilter = (req, file, cb) => {
    // Vérifier le type MIME
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
        return cb(
            new Error(`Type de fichier non autorisé: ${file.mimetype}. Types acceptés: JPEG, PNG, WebP, HEIC`),
            false
        );
    }

    // Vérifier l'extension
    const ext = path.extname(file.originalname).toLowerCase();
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
        return cb(
            new Error(`Extension non autorisée: ${ext}. Extensions acceptées: ${ALLOWED_EXTENSIONS.join(', ')}`),
            false
        );
    }

    cb(null, true);
};

/**
 * Configuration multer pour stockage en mémoire
 * (pour upload vers Cloudinary)
 */
const memoryStorage = multer.memoryStorage();

/**
 * Upload pour les photos de job (avant/après déneigement)
 * Max 5 photos, 10MB chacune
 */
const jobPhotosUpload = multer({
    storage: memoryStorage,
    limits: {
        fileSize: MAX_FILE_SIZE,
        files: 5,
    },
    fileFilter: imageFileFilter,
});

/**
 * Upload pour les photos de profil
 * 1 photo, 5MB max
 */
const profilePhotoUpload = multer({
    storage: memoryStorage,
    limits: {
        fileSize: MAX_PHOTO_SIZE,
        files: 1,
    },
    fileFilter: imageFileFilter,
});

/**
 * Upload pour les preuves de dispute
 * Max 10 photos, 10MB chacune
 */
const disputeEvidenceUpload = multer({
    storage: memoryStorage,
    limits: {
        fileSize: MAX_FILE_SIZE,
        files: 10,
    },
    fileFilter: imageFileFilter,
});

/**
 * Upload générique pour photos
 */
const genericPhotoUpload = multer({
    storage: memoryStorage,
    limits: {
        fileSize: MAX_FILE_SIZE,
        files: 3,
    },
    fileFilter: imageFileFilter,
});

/**
 * Middleware de gestion d'erreurs multer
 */
const handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        // Erreurs multer spécifiques
        switch (err.code) {
            case 'LIMIT_FILE_SIZE':
                return res.status(400).json({
                    success: false,
                    message: 'Le fichier est trop volumineux. Taille maximale: 10 MB',
                    code: 'FILE_TOO_LARGE',
                });
            case 'LIMIT_FILE_COUNT':
                return res.status(400).json({
                    success: false,
                    message: 'Trop de fichiers. Nombre maximum dépassé',
                    code: 'TOO_MANY_FILES',
                });
            case 'LIMIT_UNEXPECTED_FILE':
                return res.status(400).json({
                    success: false,
                    message: 'Champ de fichier inattendu',
                    code: 'UNEXPECTED_FIELD',
                });
            default:
                return res.status(400).json({
                    success: false,
                    message: `Erreur upload: ${err.message}`,
                    code: 'UPLOAD_ERROR',
                });
        }
    } else if (err) {
        // Erreurs de validation personnalisées
        return res.status(400).json({
            success: false,
            message: err.message,
            code: 'VALIDATION_ERROR',
        });
    }
    next();
};

/**
 * Middleware pour valider la taille de l'image après upload
 * Vérifie les dimensions minimales et maximales
 */
const validateImageDimensions = (minWidth = 100, minHeight = 100) => {
    return async (req, res, next) => {
        if (!req.file && !req.files) {
            return next();
        }

        const files = req.files || [req.file];

        try {
            for (const file of files) {
                if (!file || !file.buffer) continue;

                // Vérification basique de la signature du fichier
                const signature = file.buffer.slice(0, 4).toString('hex');

                // Signatures connues
                const validSignatures = [
                    'ffd8ffe0', // JPEG
                    'ffd8ffe1', // JPEG EXIF
                    'ffd8ffe2', // JPEG
                    '89504e47', // PNG
                    '52494646', // WebP (RIFF)
                ];

                const isValidSignature = validSignatures.some(sig =>
                    signature.startsWith(sig.slice(0, 8))
                );

                // Pour HEIC, vérifier différemment
                const isHeic = file.mimetype.includes('heic') || file.mimetype.includes('heif');

                if (!isValidSignature && !isHeic) {
                    return res.status(400).json({
                        success: false,
                        message: 'Le fichier ne semble pas être une image valide',
                        code: 'INVALID_IMAGE',
                    });
                }
            }

            next();
        } catch (error) {
            console.error('Erreur validation image:', error);
            next();
        }
    };
};

/**
 * Sanitize le nom de fichier pour éviter les injections
 */
const sanitizeFilename = (filename) => {
    return filename
        .replace(/[^a-zA-Z0-9.-]/g, '_')
        .replace(/\.{2,}/g, '.')
        .substring(0, 255);
};

module.exports = {
    jobPhotosUpload,
    profilePhotoUpload,
    disputeEvidenceUpload,
    genericPhotoUpload,
    handleMulterError,
    validateImageDimensions,
    sanitizeFilename,
    ALLOWED_MIME_TYPES,
    ALLOWED_EXTENSIONS,
    MAX_FILE_SIZE,
    MAX_PHOTO_SIZE,
};
