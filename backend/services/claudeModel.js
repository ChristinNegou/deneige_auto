/**
 * Appels a Claude partages par tous les services IA : un seul modele par
 * defaut, et les reglages qu'il demande.
 *
 * Claude Opus 5.5 reflechit toujours avant de repondre (bloc "thinking" en
 * tete de reponse, vide par defaut) : on lit donc la reponse par type de
 * bloc, et la limite de jetons doit laisser de la place a cette reflexion.
 */

/** Modele par defaut ; AI_CHAT_MODEL le remplace (ex. claude-sonnet-5-5). */
const DEFAULT_MODEL = 'claude-opus-5-5';

/** Modeles recents : effort, reflexion adaptative et repli automatique. */
const CURRENT_MODELS = new Set(['claude-opus-5-5', 'claude-opus-5', 'claude-fable-5-1', 'claude-sonnet-5-5']);

/** La reflexion compte dans max_tokens : en dessous, la reponse serait coupee. */
const MIN_MAX_TOKENS = 4096;

const getModel = () => process.env.AI_CHAT_MODEL || DEFAULT_MODEL;

/**
 * Parametres d'une requete pour le modele configure.
 * @param {object} params - messages, system, max_tokens...
 * @param {{effort?: 'low'|'medium'|'high'}} [options] - "low" pour les
 *   taches simples (classement, court JSON, chat), plus rapide et moins cher
 */
function buildParams(params, { effort = 'low' } = {}) {
    const model = getModel();
    if (!CURRENT_MODELS.has(model)) {
        // Ancien modele choisi par AI_CHAT_MODEL : requete d'origine, sans
        // les parametres qu'il refuserait
        return { model, ...params };
    }
    return {
        model,
        ...params,
        max_tokens: Math.max(params.max_tokens || 0, MIN_MAX_TOKENS),
        output_config: { effort },
        // Si les filtres de securite refusent la demande, Claude la relance
        // sur le modele de repli recommande par Anthropic
        betas: ['server-side-fallback-2026-07-01'],
        fallbacks: 'default',
    };
}

/** Envoie une requete et attend la reponse complete. */
function createMessage(client, params, options) {
    return client.beta.messages.create(buildParams(params, options));
}

/** Ouvre une reponse en continu (chat). */
function streamMessage(client, params, options) {
    return client.beta.messages.stream(buildParams(params, options));
}

/**
 * Texte de la reponse (les blocs de reflexion sont ignores).
 * @throws si Claude a decline la demande
 */
function textOf(response) {
    if (response.stop_reason === 'refusal') {
        const error = new Error('Claude a décliné cette demande');
        error.code = 'AI_REFUSAL';
        throw error;
    }
    return response.content
        .filter((block) => block.type === 'text')
        .map((block) => block.text)
        .join('');
}

module.exports = { DEFAULT_MODEL, getModel, buildParams, createMessage, streamMessage, textOf };
