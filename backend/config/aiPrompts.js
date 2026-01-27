/**
 * Configuration des prompts IA pour l'assistant Déneige Auto
 * Supporte le français (fr) et l'anglais (en)
 */

/**
 * Normalise le code de langue
 * @param {string} lang - Code de langue ('fr', 'en', etc.)
 * @returns {string} 'fr' ou 'en'
 */
const normalizeLang = (lang) => {
    if (!lang) return 'fr';
    const code = lang.toLowerCase().split('-')[0];
    return code === 'en' ? 'en' : 'fr';
};

/**
 * Génère le prompt système avec le contexte utilisateur
 * @param {Object} context - Contexte utilisateur
 * @param {string} lang - Code de langue ('fr' ou 'en')
 * @returns {string} Prompt système complet
 */
const getSystemPrompt = (context = {}, lang = 'fr') => {
    lang = normalizeLang(lang);

    const basePrompts = {
        fr: `Tu es l'assistant virtuel de Déneige Auto, une application de déneigement de véhicules au Québec.

## À propos de Déneige Auto
Déneige Auto est une plateforme qui met en relation des propriétaires de véhicules avec des déneigeurs professionnels. Les clients peuvent réserver un service de déneigement pour leur véhicule stationné, et un déneigeur se déplace pour nettoyer le véhicule avant l'heure de départ souhaitée.

## Tarification
- **Prix de base**: 15,00 $ CAD
- **Supplément neige**: 0,50 $ par centimètre de neige accumulée
- **Options de service**:
  - Grattage des vitres: +5,00 $
  - Dégivrage des portes: +3,00 $
  - Dégagement des roues: +4,00 $
- **Frais d'urgence**: +40% si réservé moins de 45 minutes avant le départ
- **Taxes**: TPS 5% + TVQ 9,975% (Québec)
- **Frais de service**: 1,50 $ fixe
- **Frais de traitement**: 2,90% du montant

## Abonnements disponibles
- **Hebdomadaire**: 39,00 $ / semaine
- **Mensuel**: 129,00 $ / mois
- **Saisonnier**: 399,00 $ / saison

## Politique d'annulation
- Annulation gratuite jusqu'à 60 minutes avant le départ
- 50% de frais si le déneigeur est en route
- 100% de frais si le travail est commencé
- Frais minimum: 5,00 $

## Fonctionnement
1. Le client crée une réservation en indiquant son véhicule et son emplacement
2. Il choisit son heure de départ souhaitée
3. Un déneigeur disponible accepte la mission
4. Le déneigeur se déplace et nettoie le véhicule
5. Le client est notifié quand le travail est terminé
6. Le paiement est traité automatiquement

## Ton rôle
- Répondre aux questions sur l'application et les services
- Aider les utilisateurs à comprendre les tarifs et options
- Guider les utilisateurs dans le processus de réservation
- Fournir des informations sur la météo et les conditions de déneigement
- Être courtois, professionnel et utile

## Directives
- Réponds TOUJOURS en français québécois
- Sois concis mais complet dans tes réponses
- Si tu ne connais pas une information, dis-le honnêtement
- Ne divulgue JAMAIS d'informations sensibles (mots de passe, données de paiement)
- Suggère des actions pertinentes quand c'est approprié
- Utilise un ton amical et professionnel`,

        en: `You are the virtual assistant of Deneige Auto, a vehicle snow removal application in Quebec, Canada.

## About Deneige Auto
Deneige Auto is a platform that connects vehicle owners with professional snow removers. Clients can book a snow removal service for their parked vehicle, and a snow worker will come clean the vehicle before the desired departure time.

## Pricing
- **Base price**: $15.00 CAD
- **Snow supplement**: $0.50 per centimeter of accumulated snow
- **Service options**:
  - Window scraping: +$5.00
  - Door de-icing: +$3.00
  - Wheel clearing: +$4.00
- **Urgency fee**: +40% if booked less than 45 minutes before departure
- **Taxes**: GST 5% + QST 9.975% (Quebec)
- **Service fee**: $1.50 flat
- **Processing fee**: 2.90% of the amount

## Available subscriptions
- **Weekly**: $39.00 / week
- **Monthly**: $129.00 / month
- **Seasonal**: $399.00 / season

## Cancellation policy
- Free cancellation up to 60 minutes before departure
- 50% fee if the snow worker is on the way
- 100% fee if work has started
- Minimum fee: $5.00

## How it works
1. The client creates a reservation indicating their vehicle and location
2. They choose their desired departure time
3. An available snow worker accepts the job
4. The snow worker goes to the location and cleans the vehicle
5. The client is notified when the work is done
6. Payment is processed automatically

## Your role
- Answer questions about the app and services
- Help users understand pricing and options
- Guide users through the reservation process
- Provide weather and snow removal condition information
- Be courteous, professional, and helpful

## Directives
- ALWAYS respond in English
- Be concise but thorough in your responses
- If you don't know something, say so honestly
- NEVER disclose sensitive information (passwords, payment data)
- Suggest relevant actions when appropriate
- Use a friendly and professional tone`
    };

    const basePrompt = basePrompts[lang];

    // Ajouter le contexte utilisateur si disponible
    let contextSection = '';

    if (context.user) {
        const roleLabels = {
            fr: { client: 'Client', snowWorker: 'Déneigeur', admin: 'Administrateur' },
            en: { client: 'Client', snowWorker: 'Snow Worker', admin: 'Administrator' }
        };
        const sectionTitle = lang === 'en' ? 'Current user information' : "Informations sur l'utilisateur actuel";
        const nameLabel = lang === 'en' ? 'First name' : 'Prénom';
        const roleLabel = lang === 'en' ? 'Role' : 'Rôle';
        const notSpecified = lang === 'en' ? 'Not specified' : 'Non spécifié';

        contextSection += `\n\n## ${sectionTitle}
- ${nameLabel}: ${context.user.firstName || notSpecified}
- ${roleLabel}: ${roleLabels[lang][context.user.role] || context.user.role}`;
    }

    if (context.vehicles && context.vehicles.length > 0) {
        const title = lang === 'en' ? "User's vehicles" : "Véhicules de l'utilisateur";
        const colorNotSpecified = lang === 'en' ? 'color not specified' : 'couleur non spécifiée';
        const plateNotSpecified = lang === 'en' ? 'not specified' : 'non spécifiée';
        const plateLabel = lang === 'en' ? 'Plate' : 'Plaque';

        contextSection += `\n\n## ${title}`;
        context.vehicles.forEach((v, i) => {
            contextSection += `\n${i + 1}. ${v.make} ${v.model} ${v.year || ''} (${v.color || colorNotSpecified}) - ${plateLabel}: ${v.licensePlate || plateNotSpecified}`;
        });
    }

    if (context.activeReservations && context.activeReservations.length > 0) {
        const title = lang === 'en' ? 'Active reservations' : 'Réservations actives';
        const departureLabel = lang === 'en' ? 'Planned departure' : 'Départ prévu';

        contextSection += `\n\n## ${title}`;
        context.activeReservations.forEach((r, i) => {
            const status = getStatusLabel(r.status, lang);
            contextSection += `\n${i + 1}. ${status} - ${departureLabel}: ${formatDateTime(r.departureTime, lang)} - ${r.totalPrice?.toFixed(2) || '?'} $`;
        });
    }

    if (context.weather) {
        const labels = {
            fr: { title: 'Météo actuelle', temp: 'Température', conditions: 'Conditions', snow: 'Accumulation de neige' },
            en: { title: 'Current weather', temp: 'Temperature', conditions: 'Conditions', snow: 'Snow accumulation' }
        };
        const l = labels[lang];
        contextSection += `\n\n## ${l.title}
- ${l.temp}: ${context.weather.temperature}°C
- ${l.conditions}: ${context.weather.description}
- ${l.snow}: ${context.weather.snowDepth || 0} cm`;
    }

    return basePrompt + contextSection;
};

/**
 * Messages de bienvenue suggérés (par langue)
 */
const welcomeMessagesByLang = {
    fr: [
        "Bonjour! Je suis l'assistant Déneige Auto. Comment puis-je vous aider aujourd'hui?",
        "Salut! Je peux vous aider avec vos réservations, les tarifs, ou toute question sur nos services. Que puis-je faire pour vous?",
        "Bienvenue! Je suis là pour répondre à vos questions sur Déneige Auto. Comment puis-je vous être utile?"
    ],
    en: [
        "Hello! I'm the Deneige Auto assistant. How can I help you today?",
        "Hi! I can help you with your reservations, pricing, or any questions about our services. What can I do for you?",
        "Welcome! I'm here to answer your questions about Deneige Auto. How can I be of help?"
    ]
};

// Rétrocompatibilité
const welcomeMessages = welcomeMessagesByLang.fr;

/**
 * Retourne les messages de bienvenue pour une langue
 * @param {string} lang - Code de langue
 * @returns {Array} Messages de bienvenue
 */
const getWelcomeMessages = (lang = 'fr') => {
    lang = normalizeLang(lang);
    return welcomeMessagesByLang[lang] || welcomeMessagesByLang.fr;
};

/**
 * Actions rapides par langue et par rôle
 */
const quickActionsByLang = {
    fr: {
        client: [
            {
                id: 'create_reservation',
                label: 'Créer une réservation',
                prompt: "Je voudrais créer une nouvelle réservation de déneigement."
            },
            {
                id: 'view_reservations',
                label: 'Voir mes réservations',
                prompt: "Montre-moi mes réservations en cours."
            },
            {
                id: 'pricing_info',
                label: 'Tarifs et options',
                prompt: "Quels sont les tarifs et les options de service disponibles?"
            },
            {
                id: 'cancel_policy',
                label: 'Politique d\'annulation',
                prompt: "Quelle est votre politique d'annulation?"
            },
            {
                id: 'contact_support',
                label: 'Contacter le support',
                prompt: "J'ai besoin de parler à un humain du support."
            }
        ],
        worker: [
            {
                id: 'view_available_jobs',
                label: 'Jobs disponibles',
                prompt: "Montre-moi les jobs de déneigement disponibles près de moi."
            },
            {
                id: 'my_earnings',
                label: 'Mes revenus',
                prompt: "Quel est le résumé de mes revenus cette semaine?"
            },
            {
                id: 'payment_info',
                label: 'Mes paiements',
                prompt: "Quand vais-je recevoir mon prochain paiement?"
            },
            {
                id: 'tips_optimize',
                label: 'Conseils pour gagner plus',
                prompt: "Donne-moi des conseils pour maximiser mes revenus en tant que déneigeur."
            },
            {
                id: 'contact_support',
                label: 'Contacter le support',
                prompt: "J'ai besoin de parler à un humain du support."
            }
        ]
    },
    en: {
        client: [
            {
                id: 'create_reservation',
                label: 'Create a reservation',
                prompt: "I would like to create a new snow removal reservation."
            },
            {
                id: 'view_reservations',
                label: 'View my reservations',
                prompt: "Show me my current reservations."
            },
            {
                id: 'pricing_info',
                label: 'Pricing and options',
                prompt: "What are the available pricing and service options?"
            },
            {
                id: 'cancel_policy',
                label: 'Cancellation policy',
                prompt: "What is your cancellation policy?"
            },
            {
                id: 'contact_support',
                label: 'Contact support',
                prompt: "I need to speak with a human from support."
            }
        ],
        worker: [
            {
                id: 'view_available_jobs',
                label: 'Available jobs',
                prompt: "Show me the available snow removal jobs near me."
            },
            {
                id: 'my_earnings',
                label: 'My earnings',
                prompt: "What is the summary of my earnings this week?"
            },
            {
                id: 'payment_info',
                label: 'My payments',
                prompt: "When will I receive my next payment?"
            },
            {
                id: 'tips_optimize',
                label: 'Tips to earn more',
                prompt: "Give me tips to maximize my earnings as a snow worker."
            },
            {
                id: 'contact_support',
                label: 'Contact support',
                prompt: "I need to speak with a human from support."
            }
        ]
    }
};

// Rétrocompatibilité
const clientQuickActions = quickActionsByLang.fr.client;
const workerQuickActions = quickActionsByLang.fr.worker;
const quickActions = clientQuickActions;

/**
 * Retourne les actions rapides en fonction du rôle et de la langue
 * @param {string} role - Rôle de l'utilisateur (client, snowWorker, admin)
 * @param {string} lang - Code de langue ('fr' ou 'en')
 * @returns {Array} Liste des actions rapides
 */
const getQuickActionsForRole = (role, lang = 'fr') => {
    lang = normalizeLang(lang);
    const actions = quickActionsByLang[lang] || quickActionsByLang.fr;
    if (role === 'snowWorker') {
        return actions.worker;
    }
    return actions.client;
};

/**
 * Convertit un statut en libellé localisé
 * @param {string} status - Code du statut
 * @param {string} lang - Code de langue
 * @returns {string} Libellé localisé
 */
const getStatusLabel = (status, lang = 'fr') => {
    lang = normalizeLang(lang);
    const labels = {
        fr: {
            'pending': 'En attente',
            'assigned': 'Assigné',
            'enRoute': 'En route',
            'inProgress': 'En cours',
            'completed': 'Terminé',
            'cancelled': 'Annulé'
        },
        en: {
            'pending': 'Pending',
            'assigned': 'Assigned',
            'enRoute': 'On the way',
            'inProgress': 'In progress',
            'completed': 'Completed',
            'cancelled': 'Cancelled'
        }
    };
    return (labels[lang] || labels.fr)[status] || status;
};

/**
 * Formate une date/heure selon la langue
 * @param {string} dateString - Date à formater
 * @param {string} lang - Code de langue
 * @returns {string} Date formatée
 */
const formatDateTime = (dateString, lang = 'fr') => {
    lang = normalizeLang(lang);
    const notSpecified = lang === 'en' ? 'Date not specified' : 'Date non spécifiée';
    if (!dateString) return notSpecified;
    try {
        const date = new Date(dateString);
        const locale = lang === 'en' ? 'en-CA' : 'fr-CA';
        return date.toLocaleString(locale, {
            weekday: 'short',
            day: 'numeric',
            month: 'short',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch {
        return dateString;
    }
};

/**
 * Construit le contexte utilisateur à partir des données
 * @param {Object} user - Utilisateur connecté
 * @param {Array} vehicles - Véhicules de l'utilisateur
 * @param {Array} reservations - Réservations actives
 * @param {Object} weather - Données météo
 * @returns {Object} Contexte formaté
 */
const buildUserContext = (user, vehicles = [], reservations = [], weather = null) => {
    return {
        user: user ? {
            firstName: user.firstName,
            role: user.role
        } : null,
        vehicles: vehicles.map(v => ({
            make: v.make,
            model: v.model,
            year: v.year,
            color: v.color,
            licensePlate: v.licensePlate
        })),
        activeReservations: reservations
            .filter(r => ['pending', 'assigned', 'enRoute', 'inProgress'].includes(r.status))
            .map(r => ({
                status: r.status,
                departureTime: r.departureTime,
                totalPrice: r.totalPrice
            })),
        weather: weather
    };
};

module.exports = {
    getSystemPrompt,
    buildUserContext,
    welcomeMessages,
    getWelcomeMessages,
    quickActions,
    clientQuickActions,
    workerQuickActions,
    getQuickActionsForRole,
    getStatusLabel,
    formatDateTime,
    normalizeLang
};
