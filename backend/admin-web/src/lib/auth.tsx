import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import type { ReactNode } from 'react';
import { api, ApiError, setUnauthorizedHandler, tokenStore } from './api';

/** Deconnexion automatique apres 30 minutes sans activite. */
const IDLE_TIMEOUT_MS = 30 * 60 * 1000;
const USER_KEY = 'deneige_admin_user';

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: string;
}

interface AuthContextValue {
  user: AdminUser | null;
  /** Raison de la derniere deconnexion forcee, affichee sur l'ecran de connexion. */
  notice: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: (notice?: string) => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function readStoredUser(): AdminUser | null {
  if (!tokenStore.get()) return null;
  try {
    const raw = sessionStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as AdminUser) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(readStoredUser);
  const [notice, setNotice] = useState<string | null>(null);
  const idleTimer = useRef<number | undefined>(undefined);

  const logout = useCallback((reason?: string) => {
    tokenStore.clear();
    try {
      sessionStorage.removeItem(USER_KEY);
    } catch {
      /* rien a nettoyer */
    }
    setUser(null);
    setNotice(reason ?? null);
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const res = await api<{ token: string; user: AdminUser }>('/auth/login', {
      method: 'POST',
      body: { email, password },
    });
    // Le serveur accepte tous les comptes : seul un administrateur entre ici.
    if (res.user.role !== 'admin') {
      throw new ApiError('Ce compte n’a pas accès à l’administration.', 403);
    }
    tokenStore.set(res.token);
    const admin: AdminUser = {
      id: res.user.id,
      email: res.user.email,
      name: res.user.name,
      role: res.user.role,
    };
    try {
      sessionStorage.setItem(USER_KEY, JSON.stringify(admin));
    } catch {
      /* session en memoire seulement */
    }
    setNotice(null);
    setUser(admin);
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(() => logout('Votre session a expiré. Reconnectez-vous.'));
  }, [logout]);

  // Deconnexion apres inactivite
  useEffect(() => {
    if (!user) return;
    const reset = () => {
      window.clearTimeout(idleTimer.current);
      idleTimer.current = window.setTimeout(
        () => logout('Déconnecté après 30 minutes d’inactivité.'),
        IDLE_TIMEOUT_MS,
      );
    };
    const events = ['mousemove', 'keydown', 'click', 'scroll'] as const;
    events.forEach((e) => window.addEventListener(e, reset, { passive: true }));
    reset();
    return () => {
      window.clearTimeout(idleTimer.current);
      events.forEach((e) => window.removeEventListener(e, reset));
    };
  }, [user, logout]);

  const value = useMemo(() => ({ user, notice, login, logout }), [user, notice, login, logout]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth doit etre utilise dans AuthProvider');
  return ctx;
}
