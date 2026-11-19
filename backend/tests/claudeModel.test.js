const { buildParams, textOf, createMessage, getModel } = require('../services/claudeModel');

describe('appels à Claude', () => {
  const saved = process.env.AI_CHAT_MODEL;
  afterEach(() => {
    if (saved === undefined) delete process.env.AI_CHAT_MODEL;
    else process.env.AI_CHAT_MODEL = saved;
  });

  it('utilise Claude Opus 5.5 par défaut, avec effort, repli et place pour la réflexion', () => {
    delete process.env.AI_CHAT_MODEL;
    const params = buildParams({ max_tokens: 300, messages: [{ role: 'user', content: 'x' }] });
    expect(getModel()).toBe('claude-opus-5-5');
    expect(params).toMatchObject({
      model: 'claude-opus-5-5',
      max_tokens: 4096,
      output_config: { effort: 'low' },
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
    });
    expect(params.thinking).toBeUndefined();
  });

  it('garde la requête d’origine pour un ancien modèle choisi dans AI_CHAT_MODEL', () => {
    process.env.AI_CHAT_MODEL = 'claude-sonnet-4-20250514';
    const params = buildParams({ max_tokens: 300, messages: [] }, { effort: 'medium' });
    expect(params).toEqual({ model: 'claude-sonnet-4-20250514', max_tokens: 300, messages: [] });
  });

  it('lit le texte même quand la réponse commence par un bloc de réflexion', () => {
    const response = {
      stop_reason: 'end_turn',
      content: [{ type: 'thinking', thinking: '' }, { type: 'text', text: '{"ok":true}' }],
    };
    expect(textOf(response)).toBe('{"ok":true}');
  });

  it('signale une demande déclinée au lieu de renvoyer un texte vide', () => {
    expect(() => textOf({ stop_reason: 'refusal', content: [] })).toThrow(/décliné/);
  });

  it('passe par l’API beta (repli automatique)', async () => {
    delete process.env.AI_CHAT_MODEL;
    const create = jest.fn().mockResolvedValue({ stop_reason: 'end_turn', content: [] });
    await createMessage({ beta: { messages: { create } } }, { max_tokens: 100, messages: [] }, { effort: 'medium' });
    expect(create.mock.calls[0][0]).toMatchObject({ model: 'claude-opus-5-5', output_config: { effort: 'medium' } });
  });
});
