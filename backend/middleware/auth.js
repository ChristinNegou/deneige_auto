const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware pour protéger les routes
exports.protect = async (req, res, next) => {
    let token;

    // Log pour debug
    console.log(`🔐 [AUTH] ${req.method} ${req.path}`);
    console.log(`🔐 [AUTH] Authorization header: ${req.headers.authorization ? 'présent' : 'ABSENT'}`);

    // Vérifier si le token existe dans les headers
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        token = req.headers.authorization.split(' ')[1];
        console.log(`🔐 [AUTH] Token extrait: ${token ? token.substring(0, 20) + '...' : 'VIDE'}`);
    }

    // Vérifier si le token existe
    if (!token) {
        console.log(`❌ [AUTH] Token manquant pour ${req.method} ${req.path}`);
        return res.status(401).json({
            success: false,
            message: 'Non autorisé - Token manquant',
        });
    }

    try {
        // Vérifier le token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        console.log(`✅ [AUTH] Token valide pour user ${decoded.id}`);

        // Récupérer l'utilisateur depuis la base de données
        req.user = await User.findById(decoded.id).select('-password');

        if (!req.user) {
            console.log(`❌ [AUTH] Utilisateur ${decoded.id} non trouvé en DB`);
            return res.status(401).json({
                success: false,
                message: 'Utilisateur non trouvé',
            });
        }

        // Vérifier si l'utilisateur est suspendu
        if (req.user.isSuspended) {
            const suspendedUntilStr = req.user.suspendedUntil
                ? req.user.suspendedUntil.toLocaleDateString('fr-CA')
                : 'indéterminée';

            return res.status(403).json({
                success: false,
                code: 'USER_SUSPENDED',
                message: 'Votre compte est suspendu',
                suspensionDetails: {
                    reason: req.user.suspensionReason || 'Non spécifiée',
                    suspendedUntil: req.user.suspendedUntil,
                    suspendedUntilDisplay: suspendedUntilStr,
                },
            });
        }

        next();
    } catch (error) {
        console.log(`❌ [AUTH] Token invalide: ${error.message}`);
        return res.status(401).json({
            success: false,
            message: 'Non autorisé - Token invalide',
        });
    }
};

// Middleware pour autoriser certains rôles
exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Le rôle ${req.user.role} n'est pas autorisé à accéder à cette ressource`,
            });
        }
        next();
    };
};