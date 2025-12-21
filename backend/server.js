const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/database');
const path = require('path');

// Charger les variables d'environnement
dotenv.config();

// Connecter à la base de données
connectDB();

// Initialiser Express
const app = express();

// Middleware
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

//  Servir les fichiers statiques
app.use(express.static(path.join(__dirname, 'public')));


// Logging middleware amélioré
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.log(`\n📝 [${timestamp}]`);
    console.log(`   Method: ${req.method}`);
    console.log(`   Path: ${req.path}`);
    console.log(`   IP: ${req.ip}`);
    if (Object.keys(req.body).length > 0) {
        console.log(`   Body:`, JSON.stringify(req.body, null, 2));
    }
    next();
});

// Routes API
app.use('/api/auth', require('./routes/auth'));
app.use('/api/reservations', require('./routes/reservations'));
app.use('/api/vehicles', require('./routes/vehicles'));
app.use('/api/parking-spots', require('./routes/parking-spots'));
app.use('/api/payments', require('./routes/payments'));
// ✅ Route pour la page de réinitialisation
app.get('/reset-password', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'reset-password.html'));
});


// Route de test
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: '🚀 API Déneige Auto - Serveur en ligne',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

// Route de santé
app.get('/health', (req, res) => {
    res.json({
        success: true,
        status: 'healthy',
        database: 'connected',
        uptime: process.uptime()
    });
});

// Route 404
app.use((req, res) => {
    console.log(`❌ Route non trouvée: ${req.method} ${req.path}`);
    res.status(404).json({
        success: false,
        message: 'Route non trouvée',
        path: req.path
    });
});

// Gestion des erreurs globales
app.use((err, req, res, next) => {
    console.error('❌ Erreur serveur:', err.stack);
    res.status(500).json({
        success: false,
        message: 'Erreur serveur',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// Démarrer le serveur
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Écouter sur toutes les interfaces réseau
const server = app.listen(PORT, HOST, () => {
    console.log('\n' + '='.repeat(50));
    console.log('🚀 SERVEUR DÉMARRÉ AVEC SUCCÈS');
    console.log('='.repeat(50));
    console.log(`📍 URL locale:     http://localhost:${PORT}`);
    console.log(`📍 URL réseau:     http://192.168.x.x:${PORT}`);
    console.log(`📍 URL Android:    http://10.0.2.2:${PORT}`);
    console.log(`🌍 Environnement:  ${process.env.NODE_ENV || 'development'}`);
    console.log(`⏰ Heure démarrage: ${new Date().toLocaleString('fr-CA')}`);
    console.log('='.repeat(50) + '\n');
    console.log('📋 Routes disponibles:');
    console.log(`   GET  /              - Page d'accueil`);
    console.log(`   GET  /health        - État du serveur`);
    console.log(`   POST /api/auth/register`);
    console.log(`   POST /api/auth/login`);
    console.log(`   POST /api/auth/forgot-password`);
    console.log(`   PUT  /api/auth/reset-password/:token`);
    console.log(`   GET  /api/auth/me`);
    console.log(`   POST /api/auth/logout`);
    console.log(`   PUT  /api/auth/update-profile`);
    console.log(`   GET  /api/reservations`);
    console.log(`   POST /api/reservations`);
    console.log(`   GET  /api/reservations/:id`);
    console.log(`   DELETE /api/reservations/:id`);
    console.log(`   GET  /api/vehicles`);
    console.log(`   POST /api/vehicles`);
    console.log(`   GET  /api/parking-spots`);

    console.log('\n' + '='.repeat(50) + '\n');
});

// Gestion de l'arrêt gracieux
process.on('SIGTERM', () => {
    console.log('\n⚠️  SIGTERM reçu. Arrêt du serveur...');
    server.close(() => {
        console.log('✅ Serveur arrêté proprement');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('\n⚠️  SIGINT reçu (Ctrl+C). Arrêt du serveur...');
    server.close(() => {
        console.log('✅ Serveur arrêté proprement');
        process.exit(0);
    });
});