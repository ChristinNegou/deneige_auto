/**
 * Configuration des prompts IA pour l'assistant Déneige Auto
 */

/**
 * Génère le prompt système avec le contexte utilisateur
 * @param {Object} context - Contexte utilisateur
 * @returns {string} Prompt système complet
 */
const getSystemPrompt = (context = {}) => {
    const basePrompt = `Tu es l'assistant virtuel de Déneige Auto, une application de déneigement de véhicules au Québec.

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
- Utilise un ton amical et professionnel`;

    // Ajouter le contexte utilisateur si disponible
    let contextSection = '';

    if (context.user) {
        contextSection += `\n\n## Informations sur l'utilisateur actuel
- Prénom: ${context.user.firstName || 'Non spécifié'}
- Rôle: ${context.user.role === 'client' ? 'Client' : context.user.role === 'snowWorker' ? 'Déneigeur' : 'Administrateur'}`;
    }

    if (context.vehicles && context.vehicles.length > 0) {
        contextSection += `\n\n## Véhicules de l'utilisateur`;
        context.vehicles.forEach((v, i) => {
            contextSection += `\n${i + 1}. ${v.make} ${v.model} ${v.year || ''} (${v.color || 'couleur non spécifiée'}) - Plaque: ${v.licensePlate || 'non spécifiée'}`;
        });
    }

    if (context.activeReservations && context.activeReservations.length > 0) {
        contextSection += `\n\n## Réservations actives`;
        context.activeReservations.forEach((r, i) => {
            const status = getStatusLabel(r.status);
            contextSection += `\n${i + 1}. ${status} - Départ prévu: ${formatDateTime(r.departureTime)} - ${r.totalPrice?.toFixed(2) || '?'} $`;
        });
    }

    if (context.weather) {
        contextSection += `\n\n## Météo actuelle
- Température: ${context.weather.temperature}°C
- Conditions: ${context.weather.description}
- Accumulation de neige: ${context.weather.snowDepth || 0} cm`;
    }

    return basePrompt + contextSection;
};

/**
 * Messages de bienvenue suggérés
 */
const welcomeMessages = [
    "Bonjour! Je suis l'assistant Déneige Auto. Comment puis-je vous aider aujourd'hui?",
    "Salut! Je peux vous aider avec vos réservations, les tarifs, ou toute question sur nos services. Que puis-je faire pour vous?",
    "Bienvenue! Je suis là pour répondre à vos questions sur Déneige Auto. Comment puis-je vous être utile?"
];

/**
 * Suggestions d'actions rapides pour les clients
 */
const clientQuickActions = [
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
];

/**
 * Suggestions d'actions rapides pour les déneigeurs
 */
const workerQuickActions = [
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
];

/**
 * Retourne les actions rapides en fonction du rôle
 * @param {string} role - Rôle de l'utilisateur (client, snowWorker, admin)
 * @returns {Array} Liste des actions rapides
 */
const getQuickActionsForRole = (role) => {
    if (role === 'snowWorker') {
        return workerQuickActions;
    }
    return clientQuickActions;
};

// Pour la rétrocompatibilité
const quickActions = clientQuickActions;

/**
 * Convertit un statut en libellé français
 */
const getStatusLabel = (status) => {
    const labels = {
        'pending': 'En attente',
        'assigned': 'Assigné',
        'enRoute': 'En route',
        'inProgress': 'En cours',
        'completed': 'Terminé',
        'cancelled': 'Annulé'
    };
    return labels[status] || status;
};

/**
 * Formate une date/heure
 */
const formatDateTime = (dateString) => {
    if (!dateString) return 'Date non spécifiée';
    try {
        const date = new Date(dateString);
        return date.toLocaleString('fr-CA', {
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
    quickActions,
    clientQuickActions,
    workerQuickActions,
    getQuickActionsForRole,
    getStatusLabel,
    formatDateTime
};
