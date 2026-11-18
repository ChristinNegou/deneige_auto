import { createContext, useCallback, useContext, useEffect, useState } from 'react';
import type { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode, SelectHTMLAttributes, TextareaHTMLAttributes } from 'react';
import clsx from 'clsx';
import { AlertTriangle, ChevronLeft, ChevronRight, Loader2, Search, X } from 'lucide-react';
import type { Tone } from '../lib/labels';

/* ---------- Bouton ---------- */

type Variant = 'primary' | 'accent' | 'secondary' | 'ghost' | 'danger';

export function Button({
  variant = 'secondary',
  loading,
  icon,
  className,
  children,
  disabled,
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; loading?: boolean; icon?: ReactNode }) {
  return (
    <button
      {...rest}
      disabled={disabled || loading}
      className={clsx(
        'inline-flex h-9 items-center justify-center gap-2 rounded-lg px-3.5 text-sm font-bold transition-colors disabled:cursor-not-allowed disabled:opacity-50',
        variant === 'primary' && 'bg-ink text-white hover:bg-ink/90',
        variant === 'accent' && 'bg-signal text-white hover:bg-signal-dark',
        variant === 'secondary' && 'border border-line bg-white text-ink hover:bg-ice',
        variant === 'ghost' && 'text-slate-2 hover:bg-ink-light hover:text-ink',
        variant === 'danger' && 'border border-danger/30 bg-white text-danger hover:bg-danger-light',
        className,
      )}
    >
      {loading ? <Loader2 className="h-4 w-4 animate-spin" aria-hidden /> : icon}
      {children}
    </button>
  );
}

/* ---------- Badge de statut (point + libelle, jamais la couleur seule) ---------- */

const toneClasses: Record<Tone, string> = {
  neutral: 'bg-ice text-slate-2',
  info: 'bg-glacier-light text-glacier',
  ok: 'bg-ok-light text-ok',
  warn: 'bg-warn-light text-warn',
  danger: 'bg-danger-light text-danger',
  progress: 'bg-signal-light text-signal-dark',
  route: 'bg-teal-light text-teal',
};

export function Badge({ tone = 'neutral', children }: { tone?: Tone; children: ReactNode }) {
  return (
    <span className={clsx('inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-bold', toneClasses[tone])}>
      <span className="h-1.5 w-1.5 rounded-full bg-current" aria-hidden />
      {children}
    </span>
  );
}

/* ---------- Mise en page ---------- */

export function Card({ title, actions, children, className, padded = true }: {
  title?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
  padded?: boolean;
}) {
  return (
    <section className={clsx('rounded-2xl border border-line/70 bg-white shadow-card', className)}>
      {(title || actions) && (
        <header className="flex items-center justify-between gap-3 border-b border-line/70 px-5 py-3.5">
          <h2 className="text-[15px] font-extrabold">{title}</h2>
          {actions}
        </header>
      )}
      <div className={clsx(padded && 'p-5')}>{children}</div>
    </section>
  );
}

export function PageHeader({ title, subtitle, actions, back }: {
  title: ReactNode;
  subtitle?: ReactNode;
  actions?: ReactNode;
  back?: ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        {back}
        <h1 className="text-2xl font-extrabold tracking-tight">{title}</h1>
        {subtitle && <p className="mt-1 text-slate-2">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap gap-2">{actions}</div>}
    </div>
  );
}

/** Ligne libelle / valeur des fiches detail. */
export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-2">
      <dt className="text-slate-2">{label}</dt>
      <dd className="text-right font-semibold">{children}</dd>
    </div>
  );
}

/* ---------- Etats ---------- */

export function Spinner({ label = 'Chargement…' }: { label?: string }) {
  return (
    <div className="flex items-center justify-center gap-2 py-16 text-slate-3" role="status">
      <Loader2 className="h-5 w-5 animate-spin" aria-hidden />
      {label}
    </div>
  );
}

export function EmptyState({ icon, title, hint }: { icon: ReactNode; title: string; hint?: string }) {
  return (
    <div className="flex flex-col items-center gap-2 px-6 py-14 text-center">
      <div className="mb-1 flex h-12 w-12 items-center justify-center rounded-full border border-line bg-white text-ink">{icon}</div>
      <p className="font-extrabold">{title}</p>
      {hint && <p className="max-w-sm text-slate-2">{hint}</p>}
    </div>
  );
}

export function ErrorState({ error, onRetry }: { error: unknown; onRetry?: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 px-6 py-14 text-center">
      <AlertTriangle className="h-6 w-6 text-danger" aria-hidden />
      <p className="font-bold">{error instanceof Error ? error.message : 'Une erreur est survenue.'}</p>
      {onRetry && <Button onClick={onRetry}>Réessayer</Button>}
    </div>
  );
}

/* ---------- Formulaires ---------- */

export function Label({ children, htmlFor }: { children: ReactNode; htmlFor?: string }) {
  return (
    <label htmlFor={htmlFor} className="mb-1.5 block text-xs font-bold text-slate-2">
      {children}
    </label>
  );
}

// Largeur pleine par defaut, sauf si l'appelant impose la sienne (w-44…)
const width = (className?: string) => (/(^|\s)w-/.test(className ?? '') ? undefined : 'w-full');

const inputBase =
  'h-9 rounded-lg border border-line bg-white px-3 text-sm text-ink placeholder:text-slate-3 focus:border-ink focus:outline-none';

export function Input(props: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={clsx(inputBase, width(props.className), props.className)} />;
}

export function Select({ children, ...props }: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select {...props} className={clsx(inputBase, width(props.className), 'pr-8', props.className)}>
      {children}
    </select>
  );
}

export function Textarea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea {...props} className={clsx(inputBase, width(props.className), 'h-auto min-h-[96px] py-2', props.className)} />;
}

/** Recherche avec temporisation : n'interroge pas le serveur a chaque touche. */
export function SearchInput({ value, onChange, placeholder }: {
  value: string;
  onChange: (value: string) => void;
  placeholder: string;
}) {
  const [draft, setDraft] = useState(value);
  useEffect(() => setDraft(value), [value]);
  useEffect(() => {
    const t = window.setTimeout(() => draft !== value && onChange(draft), 350);
    return () => window.clearTimeout(t);
  }, [draft, value, onChange]);
  return (
    <div className="relative w-full max-w-xs">
      <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-3" aria-hidden />
      <Input
        type="search"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        placeholder={placeholder}
        aria-label={placeholder}
        className="pl-9"
      />
    </div>
  );
}

/* ---------- Tableau ---------- */

export interface Column<T> {
  header: string;
  cell: (row: T) => ReactNode;
  className?: string;
  align?: 'left' | 'right';
}

export function DataTable<T>({ columns, rows, rowKey, onRowClick }: {
  columns: Column<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  onRowClick?: (row: T) => void;
}) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[720px] border-collapse">
        <thead>
          <tr className="border-b border-line text-left">
            {columns.map((c) => (
              <th
                key={c.header}
                scope="col"
                className={clsx('whitespace-nowrap px-5 py-2.5 text-xs font-bold text-slate-2', c.align === 'right' && 'text-right')}
              >
                {c.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={rowKey(row)}
              onClick={onRowClick ? () => onRowClick(row) : undefined}
              onKeyDown={onRowClick ? (e) => e.key === 'Enter' && onRowClick(row) : undefined}
              tabIndex={onRowClick ? 0 : undefined}
              className={clsx('border-b border-line/60 last:border-0', onRowClick && 'cursor-pointer hover:bg-ice/70 focus:bg-ice/70')}
            >
              {columns.map((c) => (
                <td key={c.header} className={clsx('px-5 py-3 align-middle', c.align === 'right' && 'text-right', c.className)}>
                  {c.cell(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function Pager({ page, pages, total, onPage }: {
  page: number;
  pages: number;
  total: number;
  onPage: (page: number) => void;
}) {
  if (total === 0) return null;
  return (
    <div className="flex items-center justify-between border-t border-line/70 px-5 py-3 text-slate-2">
      <span className="tabular">
        {total} résultat{total > 1 ? 's' : ''} · page {page} sur {Math.max(pages, 1)}
      </span>
      <div className="flex gap-1">
        <Button variant="ghost" aria-label="Page précédente" disabled={page <= 1} onClick={() => onPage(page - 1)} icon={<ChevronLeft className="h-4 w-4" />} />
        <Button variant="ghost" aria-label="Page suivante" disabled={page >= pages} onClick={() => onPage(page + 1)} icon={<ChevronRight className="h-4 w-4" />} />
      </div>
    </div>
  );
}

/* ---------- Fenetre modale ---------- */

export function Modal({ open, title, onClose, children, footer }: {
  open: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4" onMouseDown={onClose}>
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className="w-full max-w-md rounded-2xl bg-white shadow-pop"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <header className="flex items-center justify-between border-b border-line/70 px-5 py-4">
          <h2 className="text-base font-extrabold">{title}</h2>
          <Button variant="ghost" aria-label="Fermer" onClick={onClose} icon={<X className="h-4 w-4" />} />
        </header>
        <div className="space-y-4 px-5 py-4">{children}</div>
        {footer && <footer className="flex justify-end gap-2 border-t border-line/70 px-5 py-3">{footer}</footer>}
      </div>
    </div>
  );
}

/* ---------- Notifications ---------- */

interface Toast {
  id: number;
  message: string;
  tone: 'ok' | 'danger';
}

const ToastContext = createContext<(message: string, tone?: Toast['tone']) => void>(() => undefined);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const push = useCallback((message: string, tone: Toast['tone'] = 'ok') => {
    const id = Date.now() + Math.random();
    setToasts((t) => [...t, { id, message, tone }]);
    window.setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 4500);
  }, []);
  return (
    <ToastContext.Provider value={push}>
      {children}
      <div className="fixed bottom-4 right-4 z-[60] flex flex-col gap-2" aria-live="polite">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={clsx('rounded-xl px-4 py-3 text-sm font-bold text-white shadow-pop', t.tone === 'ok' ? 'bg-ink' : 'bg-danger')}
          >
            {t.message}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export const useToast = () => useContext(ToastContext);
