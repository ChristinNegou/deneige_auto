/**
 * Configuration de la connexion MongoDB.
 * Gère la connexion initiale, les événements de déconnexion et les erreurs.
 * @module config/database
 */

const mongoose = require('mongoose');

/**
 * Connecte l'application à MongoDB via la variable d'environnement MONGODB_URI.
 * Quitte le processus en cas d'échec de connexion.
 */
const connectDB = async () => {
    try {
        console.log('[*] Connexion a MongoDB...');

        const conn = await mongoose.connect(process.env.MONGODB_URI);

        console.log('[OK] MongoDB connecte avec succes!');
        console.log(`     Host: ${conn.connection.host}`);
        console.log(`     Database: ${conn.connection.name}`);
        console.log(`     Port: ${conn.connection.port}`);
    } catch (error) {
        console.error('[X] Erreur de connexion MongoDB:');
        console.error(`     Message: ${error.message}`);
        if (error.code) {
            console.error(`     Code: ${error.code}`);
        }
        process.exit(1);
    }

    // Evenements de connexion
    mongoose.connection.on('disconnected', () => {
        console.log('[!] MongoDB deconnecte');
    });

    mongoose.connection.on('error', (err) => {
        console.error('[X] Erreur MongoDB:', err);
    });
};

module.exports = connectDB;