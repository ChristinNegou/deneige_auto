const money = new Intl.NumberFormat('fr-CA', { style: 'currency', currency: 'CAD' });
const dateFmt = new Intl.DateTimeFormat('fr-CA', { day: 'numeric', month: 'short', year: 'numeric' });
const dateTimeFmt = new Intl.DateTimeFormat('fr-CA', {
  day: 'numeric',
  month: 'short',
  hour: '2-digit',
  minute: '2-digit',
});
const shortDay = new Intl.DateTimeFormat('fr-CA', { day: 'numeric', month: 'short' });

export const formatMoney = (value?: number | null) => money.format(value ?? 0);

export const formatDate = (iso?: string | null) => (iso ? dateFmt.format(new Date(iso)) : '—');

export const formatDateTime = (iso?: string | null) =>
  iso ? dateTimeFmt.format(new Date(iso)) : '—';

/** "2026-11-18" est un jour calendaire : on le lit en heure locale, pas en UTC. */
export const parseDay = (day: string) => {
  const [y, m, d] = day.slice(0, 10).split('-').map(Number);
  return new Date(y, m - 1, d);
};

export const formatShortDay = (day: string) => shortDay.format(parseDay(day));

const pad = (n: number) => String(n).padStart(2, '0');
export const dayKey = (date: Date) => `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;

export const formatRating = (value: number) =>
  value.toLocaleString('fr-CA', { minimumFractionDigits: 1, maximumFractionDigits: 1 });

export const formatPercent = (value: string | number) =>
  `${Number(value).toLocaleString('fr-CA', { maximumFractionDigits: 1 })} %`;

/** "il y a 3 h", "il y a 2 j" : pour reperer d'un coup d'oeil ce qui attend. */
export function formatRelative(iso?: string | null): string {
  if (!iso) return '—';
  const minutes = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (minutes < 1) return 'à l’instant';
  if (minutes < 60) return `il y a ${minutes} min`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `il y a ${hours} h`;
  const days = Math.round(hours / 24);
  // Au-dela d'un mois, une date parle davantage qu'un nombre de jours
  return days <= 30 ? `il y a ${days} j` : `le ${formatDate(iso)}`;
}

export const initials = (first?: string, last?: string) =>
  `${first?.[0] ?? ''}${last?.[0] ?? ''}`.toUpperCase() || '?';

export const fullName = (person?: { firstName?: string; lastName?: string } | null) =>
  person ? `${person.firstName ?? ''} ${person.lastName ?? ''}`.trim() || '—' : '—';
