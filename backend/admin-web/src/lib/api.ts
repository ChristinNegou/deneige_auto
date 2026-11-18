/**
 * Client HTTP de l'administration. Ajoute le jeton, normalise les erreurs et
 * deconnecte la session si le serveur repond 401.
 */

const TOKEN_KEY = 'deneige_admin_token';

/** Le jeton vit en sessionStorage : il disparait a la fermeture de l'onglet. */
export const tokenStore = {
  get: (): string | null => {
    try {
      return sessionStorage.getItem(TOKEN_KEY);
    } catch {
      return null;
    }
  },
  set: (token: string) => {
    try {
      sessionStorage.setItem(TOKEN_KEY, token);
    } catch {
      /* stockage indisponible : la session reste en memoire */
    }
  },
  clear: () => {
    try {
      sessionStorage.removeItem(TOKEN_KEY);
    } catch {
      /* rien a nettoyer */
    }
  },
};

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

let onUnauthorized: (() => void) | null = null;

export function setUnauthorizedHandler(handler: () => void) {
  onUnauthorized = handler;
}

type Query = Record<string, string | number | boolean | undefined | null>;

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  query?: Query;
}

function buildUrl(path: string, query?: Query): string {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query ?? {})) {
    if (value !== undefined && value !== null && value !== '') {
      params.set(key, String(value));
    }
  }
  const qs = params.toString();
  return `/api${path}${qs ? `?${qs}` : ''}`;
}

export async function api<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const token = tokenStore.get();
  const res = await fetch(buildUrl(path, options.query), {
    method: options.method ?? 'GET',
    headers: {
      ...(options.body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
  });

  const json = await res.json().catch(() => ({}));

  if (res.status === 401 && token) {
    tokenStore.clear();
    onUnauthorized?.();
  }
  if (!res.ok || json?.success === false) {
    const message =
      json?.message ??
      json?.errors?.[0]?.msg ??
      `Le serveur a répondu ${res.status}`;
    throw new ApiError(message, res.status);
  }
  return json as T;
}
