const cloudinary = require('cloudinary').v2;

// Configuration Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Upload une image vers Cloudinary
 * @param {string} filePath - Chemin du fichier local ou buffer
 * @param {object} options - Options d'upload
 * @returns {Promise<object>} - Résultat de l'upload
 */
const uploadImage = async (filePath, options = {}) => {
    const defaultOptions = {
        folder: 'deneige-auto/jobs',
        resource_type: 'image',
        transformation: [
            { width: 1200, height: 1200, crop: 'limit' }, // Limite la taille max
            { quality: 'auto:good' }, // Compression automatique
            { fetch_format: 'auto' }, // Format optimal (webp si supporté)
        ],
    };

    const uploadOptions = { ...defaultOptions, ...options };

    try {
        const result = await cloudinary.uploader.upload(filePath, uploadOptions);
        return {
            success: true,
            url: result.secure_url,
            publicId: result.public_id,
            width: result.width,
            height: result.height,
        };
    } catch (error) {
        console.error('Erreur upload Cloudinary:', error);
        throw error;
    }
};

/**
 * Upload depuis un buffer (pour multer memory storage)
 * @param {Buffer} buffer - Buffer de l'image
 * @param {object} options - Options d'upload
 * @returns {Promise<object>} - Résultat de l'upload
 */
const uploadFromBuffer = (buffer, options = {}) => {
    return new Promise((resolve, reject) => {
        const uploadOptions = {
            folder: 'deneige-auto/jobs',
            resource_type: 'image',
            transformation: [
                { width: 1200, height: 1200, crop: 'limit' },
                { quality: 'auto:good' },
                { fetch_format: 'auto' },
            ],
            ...options,
        };

        const uploadStream = cloudinary.uploader.upload_stream(
            uploadOptions,
            (error, result) => {
                if (error) {
                    console.error('Erreur upload Cloudinary:', error);
                    reject(error);
                } else {
                    resolve({
                        success: true,
                        url: result.secure_url,
                        publicId: result.public_id,
                        width: result.width,
                        height: result.height,
                    });
                }
            }
        );

        uploadStream.end(buffer);
    });
};

/**
 * Supprimer une image de Cloudinary
 * @param {string} publicId - ID public de l'image
 * @returns {Promise<object>} - Résultat de la suppression
 */
const deleteImage = async (publicId) => {
    try {
        const result = await cloudinary.uploader.destroy(publicId);
        return { success: result.result === 'ok' };
    } catch (error) {
        console.error('Erreur suppression Cloudinary:', error);
        throw error;
    }
};

module.exports = {
    cloudinary,
    uploadImage,
    uploadFromBuffer,
    deleteImage,
};
