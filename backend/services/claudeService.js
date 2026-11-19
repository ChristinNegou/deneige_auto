/**
 * Service Claude pour l'assistant IA
 * Intégration avec l'API Anthropic Claude
 */

const Anthropic = require('@anthropic-ai/sdk');
const { createMessage, streamMessage, textOf } = require('./claudeModel');
const { getSystemPrompt, buildUserContext } = require('../config/aiPrompts');

// Client Anthropic (initialisé seulement si la clé API est présente)
let client = null;

/**
 * Initialise le client Anthropic
 * @returns {Anthropic|null} Instance du client ou null si non configuré
 */
const initAnthropicClient = () => {
    if (client) {
        return client;
    }

    const apiKey = process.env.ANTHROPIC_API_KEY;

    if (!apiKey) {
        console.warn('⚠️ ANTHROPIC_API_KEY non configurée. Fonctionnalités IA désactivées.');
        return null;
    }

    try {
        client = new Anthropic({
            apiKey: apiKey
        });
        console.log('✅ Client Anthropic initialisé avec succès');
        return client;
    } catch (error) {
        console.error('❌ Erreur initialisation Anthropic:', error.message);
        return null;
    }
};

/**
 * Génère une réponse IA avec Claude
 * @param {Array} messages - Historique des messages [{role: 'user'|'assistant', content: string}]
 * @param {Object} userContext - Contexte utilisateur (véhicules, réservations, etc.)
 * @param {Object} options - Options de génération
 * @returns {Promise<Object>} Résultat de la génération
 */
const generateResponse = async (messages, userContext = {}, options = {}) => {
    const anthropicClient = initAnthropicClient();
    const lang = options.lang || 'fr';

    // Mode développement: réponse simulée si Claude n'est pas configuré
    if (!anthropicClient) {
        console.log('='.repeat(50));
        console.log('🤖 MODE DÉVELOPPEMENT - Réponse IA simulée');
        console.log('='.repeat(50));

        const simulatedMessages = {
            fr: "Je suis l'assistant Déneige Auto. Je suis actuellement en mode simulation car l'API Claude n'est pas configurée. Comment puis-je vous aider?",
            en: "I'm the Deneige Auto assistant. I'm currently in simulation mode as the Claude API is not configured. How can I help you?"
        };

        return {
            success: true,
            simulated: true,
            response: simulatedMessages[lang] || simulatedMessages.fr,
            usage: { inputTokens: 0, outputTokens: 0 }
        };
    }

    try {
        const maxTokens = options.maxTokens || parseInt(process.env.AI_CHAT_MAX_TOKENS) || 4096;

        // Construire le prompt système avec le contexte utilisateur et la langue
        const systemPrompt = getSystemPrompt(userContext, lang);

        const response = await createMessage(anthropicClient, {
            max_tokens: maxTokens,
            system: systemPrompt,
            messages: messages.map(msg => ({
                role: msg.role,
                content: msg.content
            }))
        });

        const responseText = textOf(response);

        console.log(`✅ Réponse Claude générée (${response.usage.input_tokens} in, ${response.usage.output_tokens} out)`);

        return {
            success: true,
            simulated: false,
            response: responseText,
            usage: {
                inputTokens: response.usage.input_tokens,
                outputTokens: response.usage.output_tokens
            },
            stopReason: response.stop_reason
        };
    } catch (error) {
        console.error('❌ Erreur Claude API:', error.message);

        // Gestion des erreurs spécifiques Anthropic
        if (error.status === 401) {
            return {
                success: false,
                error: 'Clé API invalide',
                code: 'INVALID_API_KEY'
            };
        }

        if (error.status === 429) {
            return {
                success: false,
                error: 'Limite de requêtes atteinte. Veuillez réessayer dans quelques instants.',
                code: 'RATE_LIMITED'
            };
        }

        if (error.status === 529) {
            return {
                success: false,
                error: 'Service temporairement surchargé. Veuillez réessayer.',
                code: 'OVERLOADED'
            };
        }

        return {
            success: false,
            error: 'Erreur lors de la génération de la réponse',
            code: 'GENERATION_ERROR',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        };
    }
};

/**
 * Génère une réponse en streaming
 * @param {Array} messages - Historique des messages
 * @param {Object} userContext - Contexte utilisateur
 * @param {Function} onChunk - Callback pour chaque chunk reçu
 * @param {Object} options - Options de génération
 * @returns {Promise<Object>} Résultat final
 */
const generateStreamingResponse = async (messages, userContext = {}, onChunk, options = {}) => {
    const anthropicClient = initAnthropicClient();
    const lang = options.lang || 'fr';

    if (!anthropicClient) {
        // Mode simulation pour le streaming
        const simulatedResponses = {
            fr: "Je suis l'assistant Déneige Auto en mode simulation.",
            en: "I'm the Deneige Auto assistant in simulation mode."
        };
        const simulatedResponse = simulatedResponses[lang] || simulatedResponses.fr;
        for (const char of simulatedResponse) {
            onChunk(char);
            await new Promise(resolve => setTimeout(resolve, 20));
        }

        return {
            success: true,
            simulated: true,
            response: simulatedResponse,
            usage: { inputTokens: 0, outputTokens: 0 }
        };
    }

    try {
        const maxTokens = options.maxTokens || parseInt(process.env.AI_CHAT_MAX_TOKENS) || 4096;
        const systemPrompt = getSystemPrompt(userContext, lang);

        let fullResponse = '';
        let usage = { inputTokens: 0, outputTokens: 0 };

        const stream = streamMessage(anthropicClient, {
            max_tokens: maxTokens,
            system: systemPrompt,
            messages: messages.map(msg => ({
                role: msg.role,
                content: msg.content
            }))
        });

        for await (const event of stream) {
            if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
                const text = event.delta.text;
                fullResponse += text;
                onChunk(text);
            }

            if (event.type === 'message_delta' && event.usage) {
                usage.outputTokens = event.usage.output_tokens;
            }

            if (event.type === 'message_start' && event.message?.usage) {
                usage.inputTokens = event.message.usage.input_tokens;
            }
        }

        console.log(`✅ Streaming Claude terminé (${usage.inputTokens} in, ${usage.outputTokens} out)`);

        return {
            success: true,
            simulated: false,
            response: fullResponse,
            usage: usage
        };
    } catch (error) {
        console.error('❌ Erreur streaming Claude:', error.message);

        return {
            success: false,
            error: 'Erreur lors du streaming de la réponse',
            code: 'STREAMING_ERROR',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        };
    }
};

/**
 * Vérifie si Claude est correctement configuré
 * @returns {boolean} True si configuré
 */
const isClaudeConfigured = () => {
    return !!process.env.ANTHROPIC_API_KEY;
};

/**
 * Vérifie si les fonctionnalités IA sont activées
 * @returns {boolean} True si activé
 */
const isAIEnabled = () => {
    const enabled = process.env.AI_CHAT_ENABLED;
    return enabled === 'true' || enabled === '1';
};

module.exports = {
    initAnthropicClient,
    generateResponse,
    generateStreamingResponse,
    isClaudeConfigured,
    isAIEnabled
};
