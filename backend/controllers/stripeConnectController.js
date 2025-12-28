const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const User = require('../models/User');

// Configuration de la commission plateforme
const PLATFORM_FEE_PERCENT = 0.25; // 25%

/**
 * Créer un compte Stripe Connect pour un déneigeur
 * Le déneigeur doit compléter l'onboarding pour recevoir des paiements
 */
exports.createConnectAccount = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        if (user.role !== 'snowWorker') {
            return res.status(403).json({
                success: false,
                message: 'Seuls les déneigeurs peuvent créer un compte de paiement',
            });
        }

        // Initialiser workerProfile si inexistant (pour les anciens utilisateurs)
        if (!user.workerProfile) {
            user.workerProfile = {
                isAvailable: false,
                currentLocation: { type: 'Point', coordinates: [0, 0] },
                preferredZones: [],
                maxActiveJobs: 3,
                vehicleType: 'car',
                equipmentList: [],
                totalJobsCompleted: 0,
                totalEarnings: 0,
                totalTipsReceived: 0,
                averageRating: 0,
                totalRatingsCount: 0,
            };
            await user.save();
        }

        // Vérifier si le compte existe déjà
        if (user.workerProfile?.stripeConnectId) {
            // Récupérer le compte existant
            const account = await stripe.accounts.retrieve(
                user.workerProfile.stripeConnectId
            );

            // Si le compte n'est pas complètement configuré, renvoyer le lien d'onboarding
            if (!account.charges_enabled) {
                const accountLink = await stripe.accountLinks.create({
                    account: user.workerProfile.stripeConnectId,
                    refresh_url: `${process.env.APP_URL}/worker/stripe-connect/refresh`,
                    return_url: `${process.env.APP_URL}/worker/stripe-connect/complete`,
                    type: 'account_onboarding',
                });

                return res.json({
                    success: true,
                    accountId: user.workerProfile.stripeConnectId,
                    onboardingUrl: accountLink.url,
                    isComplete: false,
                });
            }

            return res.json({
                success: true,
                accountId: user.workerProfile.stripeConnectId,
                isComplete: true,
                chargesEnabled: account.charges_enabled,
                payoutsEnabled: account.payouts_enabled,
            });
        }

        // Créer un nouveau compte Express Connect
        const account = await stripe.accounts.create({
            type: 'express',
            country: 'CA',
            email: user.email,
            capabilities: {
                card_payments: { requested: true },
                transfers: { requested: true },
            },
            business_type: 'individual',
            business_profile: {
                mcc: '7349', // Code pour services de nettoyage
                product_description: 'Services de déneigement automobile',
            },
            metadata: {
                userId: user._id.toString(),
                userEmail: user.email,
            },
        });

        // Sauvegarder l'ID du compte Connect
        user.workerProfile.stripeConnectId = account.id;
        await user.save();

        // Créer le lien d'onboarding
        const accountLink = await stripe.accountLinks.create({
            account: account.id,
            refresh_url: `${process.env.APP_URL}/worker/stripe-connect/refresh`,
            return_url: `${process.env.APP_URL}/worker/stripe-connect/complete`,
            type: 'account_onboarding',
        });

        console.log('✅ Compte Stripe Connect créé:', account.id);

        res.json({
            success: true,
            accountId: account.id,
            onboardingUrl: accountLink.url,
            isComplete: false,
        });
    } catch (error) {
        console.error('❌ Erreur création compte Connect:', error);

        // Log détaillé pour Stripe errors
        if (error.type) {
            console.error('Stripe Error Type:', error.type);
            console.error('Stripe Error Code:', error.code);
            console.error('Stripe Error Param:', error.param);
        }

        res.status(500).json({
            success: false,
            message: error.message,
            stripeError: error.type || null,
            stripeCode: error.code || null,
        });
    }
};

/**
 * Vérifier le statut du compte Connect d'un déneigeur
 */
exports.getConnectAccountStatus = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        // Initialiser workerProfile si inexistant
        if (!user.workerProfile) {
            user.workerProfile = {
                isAvailable: false,
                currentLocation: { type: 'Point', coordinates: [0, 0] },
                preferredZones: [],
                maxActiveJobs: 3,
                vehicleType: 'car',
                equipmentList: [],
                totalJobsCompleted: 0,
                totalEarnings: 0,
                totalTipsReceived: 0,
                averageRating: 0,
                totalRatingsCount: 0,
            };
            await user.save();
        }

        if (!user.workerProfile.stripeConnectId) {
            return res.json({
                success: true,
                hasAccount: false,
                isComplete: false,
            });
        }

        const account = await stripe.accounts.retrieve(
            user.workerProfile.stripeConnectId
        );

        res.json({
            success: true,
            hasAccount: true,
            accountId: account.id,
            isComplete: account.details_submitted,
            chargesEnabled: account.charges_enabled,
            payoutsEnabled: account.payouts_enabled,
            requirements: account.requirements,
        });
    } catch (error) {
        console.error('❌ Erreur récupération statut Connect:', error);

        if (error.type) {
            console.error('Stripe Error Type:', error.type);
            console.error('Stripe Error Code:', error.code);
        }

        res.status(500).json({
            success: false,
            message: error.message,
            stripeError: error.type || null,
            stripeCode: error.code || null,
        });
    }
};

/**
 * Créer un lien vers le dashboard Express du déneigeur
 */
exports.getConnectDashboardLink = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        if (!user.workerProfile?.stripeConnectId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun compte de paiement configuré',
            });
        }

        const loginLink = await stripe.accounts.createLoginLink(
            user.workerProfile.stripeConnectId
        );

        res.json({
            success: true,
            dashboardUrl: loginLink.url,
        });
    } catch (error) {
        console.error('❌ Erreur création lien dashboard:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

/**
 * Récupérer le solde du compte Connect
 */
exports.getConnectBalance = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        if (!user.workerProfile?.stripeConnectId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun compte de paiement configuré',
            });
        }

        const balance = await stripe.balance.retrieve({
            stripeAccount: user.workerProfile.stripeConnectId,
        });

        // Convertir les montants de cents en dollars
        const available = balance.available.reduce((acc, b) => {
            if (b.currency === 'cad') return acc + (b.amount / 100);
            return acc;
        }, 0);

        const pending = balance.pending.reduce((acc, b) => {
            if (b.currency === 'cad') return acc + (b.amount / 100);
            return acc;
        }, 0);

        res.json({
            success: true,
            balance: {
                available,
                pending,
                currency: 'cad',
            },
        });
    } catch (error) {
        console.error('❌ Erreur récupération solde:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

/**
 * Récupérer l'historique des paiements reçus
 */
exports.getPayoutHistory = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        if (!user.workerProfile?.stripeConnectId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun compte de paiement configuré',
            });
        }

        // Récupérer les transferts reçus
        const transfers = await stripe.transfers.list({
            destination: user.workerProfile.stripeConnectId,
            limit: 50,
        });

        // Formater les données
        const payouts = transfers.data.map(transfer => ({
            id: transfer.id,
            amount: transfer.amount / 100,
            currency: transfer.currency,
            status: transfer.reversed ? 'reversed' : 'paid',
            createdAt: new Date(transfer.created * 1000),
            description: transfer.description,
            reservationId: transfer.metadata?.reservationId,
        }));

        res.json({
            success: true,
            payouts,
            hasMore: transfers.has_more,
        });
    } catch (error) {
        console.error('❌ Erreur récupération historique:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

/**
 * Obtenir la configuration de commission actuelle
 */
exports.getPlatformFeeConfig = async (req, res) => {
    res.json({
        success: true,
        platformFeePercent: PLATFORM_FEE_PERCENT,
        workerPercent: 1 - PLATFORM_FEE_PERCENT,
        description: `La plateforme retient ${PLATFORM_FEE_PERCENT * 100}% sur chaque transaction. Vous recevez ${(1 - PLATFORM_FEE_PERCENT) * 100}% du montant payé par le client.`,
    });
};

module.exports = exports;
