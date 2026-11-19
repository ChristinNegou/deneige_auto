/**
 * Point d'entrée du serveur Deneige Auto.
 * Configure Express, les middlewares de sécurité, les routes API, Socket.IO et les tâches cron.
 * @module server
 */

const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const cron = require('node-cron');
const helmet = require('helmet');
const compression = require('compression');
const mongoSanitize = require('express-mongo-sanitize');
const connectDB = require('./config/database');
const path = require('path');
const mongoose = require('mongoose');
const { initializeFirebase } = require('./services/firebaseService');
const { runFullCleanup, getDatabaseStats } = require('./services/databaseCleanupService');
const { processExpiredJobs } = require('./services/expiredJobsService');
const { generalLimiter } = require('./middleware/rateLimiter');

// --- Initialisation ---

// Charger les variables d'environnement
dotenv.config();

// Valider les variables d'environnement AVANT de continuer
const { validateEnv, checkProductionKeys } = require('./config/validateEnv');
validateEnv(true); // true = exit si erreur
checkProductionKeys();

// Connecter à la base de données
connectDB();

// Initialiser Firebase pour les push notifications
initializeFirebase();

// Initialiser Express
const app = express();

// Trust proxy pour Railway/Heroku (nécessaire pour express-rate-limit)
app.set('trust proxy', 1);

// Créer le serveur HTTP pour Socket.IO
const httpServer = http.createServer(app);

// --- Configuration CORS ---

const corsOptions = {
    origin: function (origin, callback) {
        // Permettre les requêtes sans origin (apps mobiles, Postman)
        if (!origin) {
            return callback(null, true);
        }

        const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [];

        // Permettre les requêtes depuis le même domaine (pour reset-password, etc.)
        const appUrl = process.env.APP_URL || process.env.FRONTEND_URL;
        if (appUrl && origin === appUrl) {
            return callback(null, true);
        }

        // En développement, permettre localhost
        if (process.env.NODE_ENV !== 'production') {
            if (origin.includes('localhost') || origin.includes('127.0.0.1') || origin.includes('192.168.')) {
                return callback(null, true);
            }
        }

        // Vérifier si l'origin est dans la liste autorisée
        const isAllowed = allowedOrigins.some(allowed => {
            // Support des wildcards simples
            if (allowed.includes('*')) {
                const pattern = allowed.replace(/\*/g, '.*');
                return new RegExp(`^${pattern}$`).test(origin);
            }
            return allowed === origin;
        });

        if (isAllowed) {
            callback(null, true);
        } else {
            console.warn(`⚠️ CORS bloqué pour origin: ${origin}`);
            callback(new Error('Non autorisé par CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};

app.use(cors(corsOptions));

// HTTPS enforcement en production
if (process.env.NODE_ENV === 'production') {
    app.use((req, res, next) => {
        // Vérifier le header x-forwarded-proto (utilisé par les load balancers/proxies)
        if (req.headers['x-forwarded-proto'] !== 'https') {
            return res.redirect(301, `https://${req.headers.host}${req.url}`);
        }
        next();
    });
}

// --- Sécurité et compression ---

app.use(helmet({
    contentSecurityPolicy: false, // Désactivé pour les apps mobiles
    crossOriginEmbedderPolicy: false,
    hsts: {
        maxAge: 31536000, // 1 an
        includeSubDomains: true,
        preload: true,
    },
}));
app.use(mongoSanitize()); // Protection contre les injections NoSQL
app.use(generalLimiter); // Rate limiting général

// Compression des réponses (gzip)
app.use(compression({
    level: 6, // Niveau de compression (1-9)
    threshold: 1024, // Compresser seulement si > 1KB
    filter: (req, res) => {
        // Ne pas compresser les webhooks Stripe (raw body)
        if (req.path.includes('/webhook')) {
            return false;
        }
        return compression.filter(req, res);
    },
}));

// Middleware spécial pour les webhooks Stripe (doit recevoir le raw body AVANT express.json())
app.use('/api/webhooks/stripe', express.raw({ type: 'application/json' }));
app.use('/api/payments/webhook', express.raw({ type: 'application/json' }), (req, res, next) => {
    req.rawBody = req.body;
    next();
});

// Middleware JSON pour les autres routes avec limite de taille
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

//  Servir les fichiers statiques
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Site d'administration (React, construit dans admin-web/dist).
// Toute route /admin/* renvoie index.html : le routage se fait dans le navigateur.
const adminDist = path.join(__dirname, 'admin-web', 'dist');
app.use('/admin', express.static(adminDist, { index: false, maxAge: '1h' }));
app.get(['/admin', '/admin/*'], (req, res) => {
    res.set('Cache-Control', 'no-store');
    res.sendFile(path.join(adminDist, 'index.html'), (err) => {
        if (err) res.status(404).send('Site admin non construit : lancez npm run build:admin');
    });
});


// --- Journalisation (développement uniquement) ---

const sensitiveFields = ['password', 'token', 'refreshToken', 'secret', 'apiKey', 'cardNumber', 'cvv'];
const filterSensitiveData = (obj) => {
    if (!obj || typeof obj !== 'object') return obj;
    const filtered = { ...obj };
    for (const key of Object.keys(filtered)) {
        if (sensitiveFields.some(f => key.toLowerCase().includes(f.toLowerCase()))) {
            filtered[key] = '***FILTERED***';
        } else if (typeof filtered[key] === 'object') {
            filtered[key] = filterSensitiveData(filtered[key]);
        }
    }
    return filtered;
};

app.use((req, res, next) => {
    // Ne pas logger en production pour éviter les fuites de données
    if (process.env.NODE_ENV === 'production') {
        return next();
    }

    const timestamp = new Date().toISOString();
    console.log(`\n📝 [${timestamp}]`);
    console.log(`   Method: ${req.method}`);
    console.log(`   Path: ${req.path}`);
    console.log(`   IP: ${req.ip}`);
    if (Object.keys(req.body).length > 0) {
        // Filtrer les données sensibles avant de logger
        console.log(`   Body:`, JSON.stringify(filterSensitiveData(req.body), null, 2));
    }
    next();
});

// --- Routes API ---

app.use('/api/auth', require('./routes/auth'));
app.use('/api/reservations', require('./routes/reservations'));
app.use('/api/vehicles', require('./routes/vehicles'));
app.use('/api/parking-spots', require('./routes/parking-spots'));
app.use('/api/payments', require('./routes/payments'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/workers', require('./routes/workers'));
app.use('/api/phone', require('./routes/phoneVerification'));
app.use('/api/stripe-connect', require('./routes/stripeConnect'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/messages', require('./routes/messages'));
app.use('/api/support', require('./routes/support'));
app.use('/api/disputes', require('./routes/disputes'));
app.use('/api/webhooks', require('./routes/webhooks'));
app.use('/api/ai-chat', require('./routes/aiChat'));
app.use('/api/ai', require('./routes/aiFeatures'));

// ✅ Route pour la page de réinitialisation
app.get('/reset-password', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'reset-password.html'));
});

// ✅ Routes pour la politique de confidentialité et conditions d'utilisation
app.get('/privacy-policy', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html'));
});

app.get('/terms-of-service', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'terms-of-service.html'));
});

app.get('/delete-account', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'delete-account.html'));
});

// ✅ Routes pour les redirections Stripe Connect
app.get('/worker/stripe-connect/complete', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'stripe-connect-complete.html'));
});

app.get('/worker/stripe-connect/refresh', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'stripe-connect-refresh.html'));
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

// Route de santé améliorée
app.get('/health', async (req, res) => {
    const healthCheck = {
        success: true,
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        uptimeFormatted: formatUptime(process.uptime()),
        memory: {
            used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
            total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
            unit: 'MB',
        },
        database: {
            status: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
            name: mongoose.connection.name || 'N/A',
        },
        environment: process.env.NODE_ENV || 'development',
        version: process.env.npm_package_version || '1.0.0',
    };

    // Si la DB n'est pas connectée, retourner un status 503
    if (mongoose.connection.readyState !== 1) {
        healthCheck.success = false;
        healthCheck.status = 'unhealthy';
        return res.status(503).json(healthCheck);
    }

    res.json(healthCheck);
});

/**
 * Formate une durée en secondes vers une chaîne lisible (ex: "2j 3h 15m 42s").
 * @param {number} seconds - Nombre de secondes
 * @returns {string} Durée formatée
 */
function formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);

    const parts = [];
    if (days > 0) parts.push(`${days}j`);
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0) parts.push(`${minutes}m`);
    parts.push(`${secs}s`);

    return parts.join(' ');
}

// Route de santé détaillée (pour monitoring)
app.get('/health/detailed', async (req, res) => {
    try {
        // Test de latence DB
        const dbStart = Date.now();
        await mongoose.connection.db.admin().ping();
        const dbLatency = Date.now() - dbStart;

        res.json({
            success: true,
            status: 'healthy',
            timestamp: new Date().toISOString(),
            checks: {
                database: {
                    status: 'ok',
                    latency: `${dbLatency}ms`,
                },
                memory: {
                    status: process.memoryUsage().heapUsed < 500 * 1024 * 1024 ? 'ok' : 'warning',
                    heapUsed: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
                    heapTotal: `${Math.round(process.memoryUsage().heapTotal / 1024 / 1024)}MB`,
                },
                uptime: {
                    status: 'ok',
                    value: formatUptime(process.uptime()),
                },
            },
        });
    } catch (error) {
        res.status(503).json({
            success: false,
            status: 'unhealthy',
            error: error.message,
        });
    }
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

// --- Socket.IO (temps réel) ---

const io = new Server(httpServer, {
    cors: {
        origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
        methods: ['GET', 'POST'],
        credentials: true,
    },
});

// Middleware d'authentification Socket.IO
const jwt = require('jsonwebtoken');
const User = require('./models/User');

/**
 * Valide un identifiant MongoDB ObjectId.
 * @param {string} id - Identifiant à valider
 * @returns {boolean}
 */
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

/**
 * Valide des coordonnées GPS (latitude et longitude).
 * @param {number} lat - Latitude (-90 à 90)
 * @param {number} lng - Longitude (-180 à 180)
 * @returns {boolean}
 */
const isValidCoordinate = (lat, lng) => {
    return typeof lat === 'number' && typeof lng === 'number' &&
           lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 &&
           !isNaN(lat) && !isNaN(lng);
};

io.use(async (socket, next) => {
    try {
        const token = socket.handshake.auth.token;
        if (!token) {
            return next(new Error('Token manquant'));
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.id);
        if (!user) {
            return next(new Error('Utilisateur non trouvé'));
        }

        socket.userId = user._id.toString();
        socket.userRole = user.role;
        next();
    } catch (error) {
        next(new Error('Authentification échouée'));
    }
});

// Gestion des connexions Socket.IO
io.on('connection', (socket) => {
    console.log(`🔌 Socket connecté: ${socket.userId} (${socket.userRole})`);

    // Rejoindre une room personnelle basée sur l'ID utilisateur
    socket.join(`user:${socket.userId}`);

    // Les workers rejoignent aussi une room workers pour les broadcasts
    if (socket.userRole === 'snowWorker') {
        socket.join('workers');
    }

    // Les admins rejoignent une room admins
    if (socket.userRole === 'admin') {
        socket.join('admins');
    }

    // La position du deneigeur est gardee a la deconnexion : l'app passe en
    // arriere-plan, et c'est justement la qu'il doit etre prevenu des
    // nouvelles demandes proches (hors ligne = isAvailable a false).
    socket.on('disconnect', () => {
        console.log(`🔌 Socket déconnecté: ${socket.userId}`);
    });

    // Événement pour mettre à jour la position du worker
    socket.on('worker:updateLocation', async (data) => {
        if (socket.userRole !== 'snowWorker') return;

        // Valider les coordonnées
        const lat = parseFloat(data?.latitude);
        const lng = parseFloat(data?.longitude);

        if (!isValidCoordinate(lat, lng)) {
            socket.emit('error', { message: 'Coordonnées invalides' });
            return;
        }

        try {
            await User.findByIdAndUpdate(socket.userId, {
                'workerProfile.currentLocation.coordinates': [lng, lat],
                'workerProfile.lastLocationUpdate': new Date(),
            });
        } catch (error) {
            console.error('Erreur mise à jour position:', error);
            socket.emit('error', { message: 'Erreur lors de la mise à jour de la position' });
        }
    });

    // Rejoindre une room de conversation pour une réservation
    socket.on('chat:join', async (data) => {
        const { reservationId } = data;

        // Valider l'ObjectId
        if (!reservationId || !isValidObjectId(reservationId)) {
            socket.emit('error', { message: 'ID de réservation invalide' });
            return;
        }

        try {
            const Reservation = require('./models/Reservation');
            const reservation = await Reservation.findById(reservationId)
                .select('userId workerId')
                .lean();

            if (!reservation) {
                socket.emit('error', { message: 'Réservation non trouvée' });
                return;
            }

            const isClient = reservation.userId.toString() === socket.userId;
            const isWorker = reservation.workerId?.toString() === socket.userId;

            if (isClient || isWorker) {
                socket.join(`reservation:${reservationId}`);
                console.log(`💬 ${socket.userId} a rejoint le chat: reservation:${reservationId}`);
            } else {
                socket.emit('error', { message: 'Accès non autorisé à cette réservation' });
            }
        } catch (error) {
            console.error('Erreur chat:join:', error);
            socket.emit('error', { message: 'Erreur lors de la connexion au chat' });
        }
    });

    // Quitter une room de conversation
    socket.on('chat:leave', (data) => {
        const { reservationId } = data;
        if (reservationId && isValidObjectId(reservationId)) {
            socket.leave(`reservation:${reservationId}`);
            console.log(`💬 ${socket.userId} a quitté le chat: reservation:${reservationId}`);
        }
    });

    // Indicateur de frappe
    socket.on('chat:typing', (data) => {
        const { reservationId, isTyping } = data;
        if (reservationId && isValidObjectId(reservationId)) {
            socket.to(`reservation:${reservationId}`).emit('chat:typing', {
                userId: socket.userId,
                isTyping: !!isTyping,
            });
        }
    });
});

// Exporter io pour l'utiliser dans d'autres modules
app.set('io', io);

// --- Tâches cron ---

// Nettoyage quotidien à 3h du matin
cron.schedule('0 3 * * *', async () => {
    console.log('\n⏰ Tâche cron: Nettoyage quotidien de la base de données');
    try {
        const result = await runFullCleanup();
        console.log(`✅ Nettoyage terminé: ${result.totalDeleted} éléments supprimés`);
    } catch (error) {
        console.error('❌ Erreur lors du nettoyage cron:', error);
    }
}, {
    timezone: 'America/Montreal'
});

console.log('📅 Tâche cron de nettoyage programmée (3h00 tous les jours)');

// Vérification des jobs expirés toutes les 5 minutes
cron.schedule('*/5 * * * *', async () => {
    try {
        await processExpiredJobs();
    } catch (error) {
        console.error('❌ Erreur lors de la vérification des jobs expirés:', error);
    }
}, {
    timezone: 'America/Montreal'
});

console.log('📅 Tâche cron de vérification des jobs expirés programmée (toutes les 5 minutes)');

// Démarrer le serveur
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Écouter sur toutes les interfaces réseau
const server = httpServer.listen(PORT, HOST, () => {
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
    console.log(`   POST /api/phone/send-code`);
    console.log(`   POST /api/phone/verify-code`);
    console.log(`   POST /api/phone/resend-code`);
    console.log(`   GET  /api/reservations`);
    console.log(`   POST /api/reservations`);
    console.log(`   GET  /api/reservations/:id`);
    console.log(`   DELETE /api/reservations/:id`);
    console.log(`   GET  /api/vehicles`);
    console.log(`   POST /api/vehicles`);
    console.log(`   GET  /api/parking-spots`);

    console.log('\n' + '='.repeat(50) + '\n');
});

// --- Arrêt gracieux ---

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