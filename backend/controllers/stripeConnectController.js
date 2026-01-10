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

/**
 * Récupérer TOUS les comptes bancaires configurés
 * Retourne la liste complète avec infos partielles pour chaque compte
 */
exports.listBankAccounts = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        if (!user.workerProfile?.stripeConnectId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun compte de paiement configuré',
            });
        }

        // Récupérer le compte Connect avec les external_accounts
        const account = await stripe.accounts.retrieve(
            user.workerProfile.stripeConnectId,
            { expand: ['external_accounts'] }
        );

        // Filtrer uniquement les comptes bancaires (pas les cartes)
        const bankAccounts = account.external_accounts?.data?.filter(
            (acc) => acc.object === 'bank_account'
        ) || [];

        // Formater les données pour chaque compte
        const formattedAccounts = bankAccounts.map((bank) => ({
            id: bank.id,
            bankName: bank.bank_name,
            last4: bank.last4,
            routingNumber: bank.routing_number,
            currency: bank.currency,
            country: bank.country,
            status: bank.status,
            accountHolderName: bank.account_holder_name,
            accountHolderType: bank.account_holder_type,
            isDefault: bank.default_for_currency || false,
        }));

        res.json({
            success: true,
            bankAccounts: formattedAccounts,
            count: formattedAccounts.length,
        });
    } catch (error) {
        console.error('❌ Erreur récupération comptes bancaires:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

/**
 * Ajouter un nouveau compte bancaire
 * Crée un token et l'attache au compte Connect
 */
exports.addBankAccount = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        const {
            accountNumber,
            transitNumber,
            institutionNumber,
            accountHolderName,
            accountHolderType = 'individual',
            setAsDefault = false
        } = req.body;

        if (!user.workerProfile?.stripeConnectId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun compte de paiement configuré',
            });
        }

        // Validation des champs requis
        if (!accountNumber || !transitNumber || !institutionNumber || !accountHolderName) {
            return res.status(400).json({
                success: false,
                message: 'Tous les champs sont requis: numéro de compte, numéro de transit, numéro d\'institution et nom du titulaire',
            });
        }

        // Validation du format canadien
        if (transitNumber.length !== 5) {
            return res.status(400).json({
                success: false,
                message: 'Le numéro de transit doit contenir 5 chiffres',
            });
        }

        if (institutionNumber.length !== 3) {
            return res.status(400).json({
                success: false,
                message: 'Le numéro d\'institution doit contenir 3 chiffres',
            });
        }

        // Créer le routing number canadien (transit + institution)
        const routingNumber = `${transitNumber}${institutionNumber}`;

        // Créer le compte bancaire externe
        const bankAccount = await stripe.accounts.createExternalAccount(
            user.workerProfile.stripeConnectId,
            {
                external_account: {
                    object: 'bank_account',
                    country: 'CA',
                    currency: 'cad',
                    account_holder_name: accountHolderName,
                    account_holder_type: accountHolderType,
                    routing_number: routingNumber,
                    account_number: accountNumber,
                },
            }
        );

        // Si demandé, définir comme compte par défaut
        if (setAsDefault) {
            await stripe.accounts.updateExternalAccount(
                user.workerProfile.stripeConnectId,
                bankAccount.id,
                { default_for_currency: true }
            );
        }

        console.log('✅ Compte bancaire ajouté:', bankAccount.id);

        res.json({
            success: true,
            message: 'Compte bancaire ajouté avec succès',
            bankAccount: {
                id: bankAccount.id,
                bankName: bankAccount.bank_name,
                last4: bankAccount.last4,
                routingNumber: bankAccount.routing_number,
                currency: bankAccount.currency,
                country: bankAccount.country,
                status: bankAccount.status,
                accountHolderName: bankAccount.account_holder_name,
                accountHolderType: bankAccount.account_holder_type,
                isDefault: setAsDefault,
            },
        });
    } catch (error) {
        console.error('❌ Erreur ajout compte bancaire:', error);

        // Messages d'erreur plus clairs pour l'utilisateur
        let userMessage = error.message;
        if (error.code === 'routing_number_invalid') {
            userMessage = 'Le numéro de transit ou d\'institution est invalide';
        } else if (error.code === 'account_number_invalid') {
            userMessage = 'Le numéro de compte est invalide';
        } else if (error.code === 'bank_account_exists') {
            userMessage = 'Ce compte bancaire est déjà enregistré';
        }

        res.status(400).json({
            success: false,
            message: userMessage,
            stripeCode: error.code || null,
        });
    }
};

/**
 * Supprimer un compte bancaire
 */
exports.deleteBankAccount = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        const { bankAccountId } = req.params;

        if (!user.workerProfile?.stripeConnectId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun compte de paiement configuré',
            });
        }

        if (!bankAccountId) {
            return res.status(400).json({
                success: false,
                message: 'ID du compte bancaire requis',
            });
        }

        // Vérifier d'abord combien de comptes bancaires existent
        const account = await stripe.accounts.retrieve(
            user.workerProfile.stripeConnectId,
            { expand: ['external_accounts'] }
        );

        const bankAccounts = account.external_accounts?.data?.filter(
            (acc) => acc.object === 'bank_account'
        ) || [];

        // Vérifier qu'il reste au moins un compte après suppression
        if (bankAccounts.length <= 1) {
            return res.status(400).json({
                success: false,
                message: 'Impossible de supprimer le dernier compte bancaire. Ajoutez un autre compte avant de supprimer celui-ci.',
            });
        }

        // Vérifier si c'est le compte par défaut
        const accountToDelete = bankAccounts.find((b) => b.id === bankAccountId);
        if (accountToDelete?.default_for_currency) {
            return res.status(400).json({
                success: false,
                message: 'Impossible de supprimer le compte par défaut. Définissez un autre compte comme principal avant de supprimer celui-ci.',
            });
        }

        // Supprimer le compte bancaire
        await stripe.accounts.deleteExternalAccount(
            user.workerProfile.stripeConnectId,
            bankAccountId
        );

        console.log('✅ Compte bancaire supprimé:', bankAccountId);

        res.json({
            success: true,
            message: 'Compte bancaire supprimé avec succès',
            deletedAccountId: bankAccountId,
        });
    } catch (error) {
        console.error('❌ Erreur suppression compte bancaire:', error);

        let userMessage = error.message;
        if (error.code === 'resource_missing') {
            userMessage = 'Compte bancaire introuvable';
        }

        res.status(400).json({
            success: false,
            message: userMessage,
            stripeCode: error.code || null,
        });
    }
};

/**
 * Définir un compte bancaire comme compte par défaut pour les versements
 */
exports.setDefaultBankAccount = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        const { bankAccountId } = req.params;

        if (!user.workerProfile?.stripeConnectId) {
            return res.status(400).json({
                success: false,
                message: 'Aucun compte de paiement configuré',
            });
        }

        if (!bankAccountId) {
            return res.status(400).json({
                success: false,
                message: 'ID du compte bancaire requis',
            });
        }

        // Mettre à jour le compte pour le définir comme défaut
        const bankAccount = await stripe.accounts.updateExternalAccount(
            user.workerProfile.stripeConnectId,
            bankAccountId,
            { default_for_currency: true }
        );

        console.log('✅ Compte bancaire défini par défaut:', bankAccountId);

        res.json({
            success: true,
            message: 'Compte bancaire défini comme principal',
            bankAccount: {
                id: bankAccount.id,
                bankName: bankAccount.bank_name,
                last4: bankAccount.last4,
                isDefault: true,
            },
        });
    } catch (error) {
        console.error('❌ Erreur définition compte par défaut:', error);

        let userMessage = error.message;
        if (error.code === 'resource_missing') {
            userMessage = 'Compte bancaire introuvable';
        }

        res.status(400).json({
            success: false,
            message: userMessage,
            stripeCode: error.code || null,
        });
    }
};

/**
 * Obtenir la liste des institutions bancaires canadiennes (pour aide à la saisie)
 */
exports.getCanadianBanks = async (req, res) => {
    // Liste des principales banques canadiennes avec leurs numéros d'institution
    const canadianBanks = [
        { code: '001', name: 'Banque de Montréal (BMO)' },
        { code: '002', name: 'Banque Scotia' },
        { code: '003', name: 'Banque Royale du Canada (RBC)' },
        { code: '004', name: 'Banque Toronto-Dominion (TD)' },
        { code: '006', name: 'Banque Nationale du Canada' },
        { code: '010', name: 'Banque CIBC' },
        { code: '016', name: 'Banque HSBC Canada' },
        { code: '030', name: 'Banque Canadienne de l\'Ouest' },
        { code: '039', name: 'Banque Laurentienne' },
        { code: '219', name: 'ATB Financial' },
        { code: '241', name: 'Banque Équitable' },
        { code: '260', name: 'Citibank Canada' },
        { code: '309', name: 'Banque Bridgewater' },
        { code: '315', name: 'Banque Continentale du Canada' },
        { code: '320', name: 'Banque Manuvie' },
        { code: '540', name: 'Banque Manulife Trust' },
        { code: '614', name: 'Tangerine' },
        { code: '815', name: 'Desjardins' },
        { code: '828', name: 'Caisse Centrale Desjardins' },
        { code: '829', name: 'Caisses Populaires Desjardins' },
        { code: '837', name: 'Caisse Populaire Groupe Financier' },
        { code: '865', name: 'Caisses Populaires' },
        { code: '879', name: 'Credit Union Atlantic' },
        { code: '899', name: 'Meridian Credit Union' },
    ];

    res.json({
        success: true,
        banks: canadianBanks,
    });
};

// ============== ADMIN: GESTION DES COMPTES CONNECT ==============

/**
 * [ADMIN] Supprimer un compte Stripe Connect d'un déneigeur
 * Utilise l'API Delete de Stripe pour supprimer le compte
 */
exports.deleteConnectAccount = async (req, res) => {
    try {
        const { workerId } = req.params;

        // Vérifier que l'utilisateur est admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Accès réservé aux administrateurs',
            });
        }

        // Trouver le worker
        const worker = await User.findById(workerId);

        if (!worker) {
            return res.status(404).json({
                success: false,
                message: 'Déneigeur introuvable',
            });
        }

        if (!worker.workerProfile?.stripeConnectId) {
            return res.status(400).json({
                success: false,
                message: 'Ce déneigeur n\'a pas de compte Stripe Connect',
            });
        }

        const stripeConnectId = worker.workerProfile.stripeConnectId;

        // Supprimer le compte via l'API Stripe
        const deletedAccount = await stripe.accounts.del(stripeConnectId);

        // Mettre à jour le profil du worker
        worker.workerProfile.stripeConnectId = null;
        await worker.save();

        console.log('✅ Compte Stripe Connect supprimé:', stripeConnectId, 'pour worker:', workerId);

        res.json({
            success: true,
            message: 'Compte Stripe Connect supprimé avec succès',
            deletedAccountId: stripeConnectId,
            deleted: deletedAccount.deleted,
        });
    } catch (error) {
        console.error('❌ Erreur suppression compte Connect:', error);

        let userMessage = error.message;

        // Si le compte n'existe plus sur Stripe (supprimé ou accès révoqué), on nettoie la DB
        if (error.code === 'resource_missing' || error.code === 'account_invalid') {
            try {
                const worker = await User.findById(req.params.workerId);
                if (worker?.workerProfile?.stripeConnectId) {
                    const oldStripeId = worker.workerProfile.stripeConnectId;
                    worker.workerProfile.stripeConnectId = null;
                    await worker.save();
                    console.log('✅ Profil nettoyé pour worker:', req.params.workerId, '- ancien Stripe ID:', oldStripeId);
                }
                return res.json({
                    success: true,
                    message: 'Compte Stripe Connect déjà supprimé ou inexistant. Le profil a été nettoyé.',
                    cleaned: true,
                });
            } catch (cleanupError) {
                console.error('Erreur nettoyage:', cleanupError);
            }
        }

        res.status(400).json({
            success: false,
            message: userMessage,
            stripeCode: error.code || null,
        });
    }
};

/**
 * [ADMIN] Lister tous les comptes Connect de la plateforme
 * Récupère directement depuis Stripe pour avoir tous les comptes, même orphelins
 */
exports.listAllConnectAccounts = async (req, res) => {
    try {
        // Vérifier que l'utilisateur est admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Accès réservé aux administrateurs',
            });
        }

        // Récupérer TOUS les comptes Connect directement depuis Stripe
        const stripeAccounts = await stripe.accounts.list({
            limit: 100, // Maximum par requête
        });

        // Récupérer tous les workers avec un compte Stripe Connect pour le mapping
        const workers = await User.find({
            role: 'snowWorker',
            'workerProfile.stripeConnectId': { $exists: true, $ne: null }
        }).select('firstName lastName email workerProfile.stripeConnectId');

        // Créer un map pour recherche rapide par stripeConnectId
        const workerMap = new Map();
        workers.forEach(worker => {
            workerMap.set(worker.workerProfile.stripeConnectId, worker);
        });

        // Formater les comptes avec les infos du worker si disponible
        const accountsWithDetails = stripeAccounts.data.map(account => {
            const worker = workerMap.get(account.id);

            return {
                stripeAccountId: account.id,
                email: account.email,
                chargesEnabled: account.charges_enabled,
                payoutsEnabled: account.payouts_enabled,
                detailsSubmitted: account.details_submitted,
                created: new Date(account.created * 1000),
                businessType: account.business_type,
                country: account.country,
                // Infos du worker si lié dans notre DB
                workerId: worker?._id || null,
                workerName: worker ? `${worker.firstName} ${worker.lastName}` : null,
                workerEmail: worker?.email || null,
                isOrphan: !worker, // True si le compte existe sur Stripe mais pas lié dans notre DB
            };
        });

        // Aussi vérifier s'il y a des workers dans notre DB avec des stripeConnectId invalides
        const stripeAccountIds = new Set(stripeAccounts.data.map(a => a.id));
        const orphanedInDb = workers
            .filter(w => !stripeAccountIds.has(w.workerProfile.stripeConnectId))
            .map(worker => ({
                stripeAccountId: worker.workerProfile.stripeConnectId,
                email: null,
                chargesEnabled: false,
                payoutsEnabled: false,
                detailsSubmitted: false,
                created: null,
                businessType: null,
                country: null,
                workerId: worker._id,
                workerName: `${worker.firstName} ${worker.lastName}`,
                workerEmail: worker.email,
                isOrphan: false,
                isInvalidOnStripe: true, // Le compte n'existe plus sur Stripe
            }));

        const allAccounts = [...accountsWithDetails, ...orphanedInDb];

        res.json({
            success: true,
            accounts: allAccounts,
            count: allAccounts.length,
            stripeTotal: stripeAccounts.data.length,
            linkedToWorkers: accountsWithDetails.filter(a => !a.isOrphan).length,
            orphanOnStripe: accountsWithDetails.filter(a => a.isOrphan).length,
            invalidInDb: orphanedInDb.length,
        });
    } catch (error) {
        console.error('❌ Erreur listing comptes Connect:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

/**
 * [ADMIN] Supprimer un compte Stripe Connect orphelin (par son ID Stripe directement)
 * Pour les comptes qui existent sur Stripe mais ne sont pas liés à un worker
 */
exports.deleteOrphanConnectAccount = async (req, res) => {
    try {
        const { stripeAccountId } = req.params;

        // Vérifier que l'utilisateur est admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Accès réservé aux administrateurs',
            });
        }

        if (!stripeAccountId) {
            return res.status(400).json({
                success: false,
                message: 'ID du compte Stripe requis',
            });
        }

        // Supprimer le compte via l'API Stripe
        const deletedAccount = await stripe.accounts.del(stripeAccountId);

        console.log('✅ Compte Stripe Connect orphelin supprimé:', stripeAccountId);

        res.json({
            success: true,
            message: 'Compte Stripe Connect supprimé avec succès',
            deletedAccountId: stripeAccountId,
            deleted: deletedAccount.deleted,
        });
    } catch (error) {
        console.error('❌ Erreur suppression compte orphelin:', error);

        let userMessage = error.message;
        if (error.code === 'resource_missing' || error.code === 'account_invalid') {
            userMessage = 'Compte déjà supprimé ou inexistant sur Stripe';
        }

        res.status(400).json({
            success: false,
            message: userMessage,
            stripeCode: error.code || null,
        });
    }
};

module.exports = exports;
