import { useState } from 'react';
import type { FormEvent } from 'react';
import { Snowflake } from 'lucide-react';
import { Button, Input, Label } from '../components/ui';
import { useAuth } from '../lib/auth';

export function LoginPage() {
  const { login, notice } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(email.trim(), password);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connexion impossible.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-ink text-white">
            <Snowflake className="h-6 w-6" aria-hidden />
          </div>
          <div className="leading-tight">
            <p className="text-lg font-extrabold">Déneige Auto</p>
            <p className="text-slate-2">Administration</p>
          </div>
        </div>

        <form onSubmit={submit} className="space-y-4 rounded-2xl border border-line/70 bg-white p-6 shadow-card">
          <h1 className="text-xl font-extrabold">Connexion</h1>
          {(error || notice) && (
            <p role="alert" className={error ? 'rounded-lg bg-danger-light px-3 py-2 font-semibold text-danger' : 'rounded-lg bg-glacier-light px-3 py-2 font-semibold text-glacier'}>
              {error ?? notice}
            </p>
          )}
          <div>
            <Label htmlFor="email">Courriel</Label>
            <Input id="email" type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div>
            <Label htmlFor="password">Mot de passe</Label>
            <Input id="password" type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
          <Button type="submit" variant="primary" loading={loading} className="w-full">
            Se connecter
          </Button>
        </form>
        <p className="mt-4 text-center text-xs text-slate-3">Accès réservé aux administrateurs. Session fermée après 30 min d’inactivité.</p>
      </div>
    </div>
  );
}
