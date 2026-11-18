import { Link } from 'react-router-dom';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import clsx from 'clsx';
import { MapPin, Star, Users, X } from 'lucide-react';
import { ROLE_COLORS, SignupChart } from '../components/SignupChart';
import { Card, DataTable, EmptyState, ErrorState, PageHeader, Select, Spinner } from '../components/ui';
import { api } from '../lib/api';
import { formatMoney, formatRating } from '../lib/format';
import { useListParams } from '../lib/useListParams';
import type { UserStats } from '../types';

const PERIODS = [
  ['month', '30 derniers jours'],
  ['quarter', '90 derniers jours'],
  ['year', '12 derniers mois'],
  ['all', 'Depuis le début'],
] as const;

function Kpi({ label, value, detail, swatch }: { label: string; value: number; detail?: string; swatch?: string }) {
  return (
    <div className="rounded-2xl border border-line/70 bg-white p-5 shadow-card">
      <p className="flex items-center gap-2 text-slate-2">
        {swatch && <span className="h-2.5 w-2.5 rounded-sm" style={{ background: swatch }} aria-hidden />}
        {label}
      </p>
      <p className="tabular mt-1 text-[28px] font-extrabold tracking-tight">{value.toLocaleString('fr-CA')}</p>
      {detail && <p className="mt-0.5 text-xs text-slate-3">{detail}</p>}
    </div>
  );
}

const plus = (n: number) => (n > 0 ? `+${n}` : '0');

export function StatsPage() {
  const { values, set } = useListParams(['period', 'city'] as const);
  const period = values.period || 'year';
  const city = values.city;

  const query = useQuery({
    queryKey: ['stats', 'users', period, city],
    queryFn: () => api<{ stats: UserStats }>('/admin/stats/users', { query: { period, city: city || undefined } }),
    placeholderData: keepPreviousData,
  });

  if (query.isLoading) return <Spinner />;
  if (query.error || !query.data) return <ErrorState error={query.error} onRetry={() => query.refetch()} />;

  const s = query.data.stats;
  const newTotal = s.newThisMonth.clients + s.newThisMonth.workers;
  const lastTotal = s.newLastMonth.clients + s.newLastMonth.workers;
  const where = city ? `à ${s.cities.find((c) => c.city.localeCompare(city, 'fr', { sensitivity: 'base' }) === 0)?.city ?? city}` : 'toutes villes';

  return (
    <>
      <PageHeader title="Statistiques" subtitle="Inscriptions, et activité des clients et déneigeurs par ville." />

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <Kpi label="Comptes inscrits" value={s.totals.users} detail={`${plus(newTotal)} ce mois`} />
        <Kpi
          label="Clients"
          swatch={ROLE_COLORS.clients}
          value={s.totals.clients}
          detail={`${plus(s.newThisMonth.clients)} ce mois, ${s.clientsWithoutReservation} sans réservation`}
        />
        <Kpi label="Déneigeurs" swatch={ROLE_COLORS.workers} value={s.totals.workers} detail={`${plus(s.newThisMonth.workers)} ce mois`} />
        <Kpi label="Inscrits ce mois" value={newTotal} detail={`Mois dernier : ${lastTotal}`} />
      </div>

      <Card title="Inscriptions par mois, 12 derniers mois" className="mt-6">
        <SignupChart data={s.signupsByMonth} />
      </Card>

      {/* Les filtres ne portent que sur l'activite par ville, en dessous. */}
      <div className="mt-8 flex flex-wrap items-center gap-3">
        <h2 className="mr-auto text-lg font-extrabold">Activité par ville</h2>
        <Select value={period} onChange={(e) => set('period', e.target.value)} aria-label="Période" className="w-48">
          {PERIODS.map(([value, label]) => (
            <option key={value} value={value}>{label}</option>
          ))}
        </Select>
        <Select value={city} onChange={(e) => set('city', e.target.value)} aria-label="Ville" className="w-52">
          <option value="">Toutes les villes</option>
          {s.cities.map((c) => (
            <option key={c.city} value={c.city}>{c.city}</option>
          ))}
        </Select>
      </div>

      <Card padded={false} className="mt-3">
        {s.cities.length ? (
          <DataTable
            rows={s.cities}
            rowKey={(c) => c.city}
            onRowClick={(c) => set('city', city === c.city ? '' : c.city)}
            columns={[
              {
                header: 'Ville',
                cell: (c) => (
                  <span className={clsx('flex items-center gap-2 font-semibold', city === c.city && 'text-glacier')}>
                    <MapPin className="h-4 w-4 text-slate-3" aria-hidden />
                    {c.city}
                    {city === c.city && <X className="h-3.5 w-3.5" aria-label="Retirer le filtre" />}
                  </span>
                ),
              },
              { header: 'Clients actifs', align: 'right', className: 'tabular', cell: (c) => c.clients },
              { header: 'Déneigeurs actifs', align: 'right', className: 'tabular', cell: (c) => c.workers },
              { header: 'Réservations', align: 'right', className: 'tabular', cell: (c) => c.reservations },
              { header: 'Terminées', align: 'right', className: 'tabular', cell: (c) => c.completed },
              { header: 'Montant terminé', align: 'right', className: 'tabular font-bold', cell: (c) => formatMoney(c.revenue) },
            ]}
          />
        ) : (
          <EmptyState icon={<MapPin className="h-5 w-5" />} title="Aucune réservation sur cette période" />
        )}
        <p className="border-t border-line/70 px-5 py-3 text-xs text-slate-3">
          La ville vient de l’adresse des réservations. Un client actif a réservé dans la ville, un déneigeur actif y a terminé au moins un déneigement.
        </p>
      </Card>

      <div className="mt-6 grid gap-6 lg:grid-cols-2">
        <Card title={`Clients les plus actifs, ${where}`} padded={false}>
          {s.topClients.length ? (
            <ul className="divide-y divide-line/60">
              {s.topClients.map((c, i) => (
                <li key={c.id}>
                  <Link to={`/users/${c.id}`} className="flex items-center gap-4 px-5 py-3 hover:bg-ice/70">
                    <span className="tabular w-5 font-extrabold text-slate-3">{i + 1}</span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate font-semibold">{c.name}</span>
                      <span className="block text-xs text-slate-3">{c.city}</span>
                    </span>
                    <span className="tabular text-slate-2">{c.reservations} rés.</span>
                    <span className="tabular w-24 text-right font-extrabold">{formatMoney(c.spent)}</span>
                  </Link>
                </li>
              ))}
            </ul>
          ) : (
            <EmptyState icon={<Users className="h-5 w-5" />} title="Aucun client actif" />
          )}
        </Card>

        <Card title={`Déneigeurs les plus actifs, ${where}`} padded={false}>
          {s.topWorkers.length ? (
            <ul className="divide-y divide-line/60">
              {s.topWorkers.map((w, i) => (
                <li key={w.id}>
                  <Link to={`/users/${w.id}`} className="flex items-center gap-4 px-5 py-3 hover:bg-ice/70">
                    <span className="tabular w-5 font-extrabold text-slate-3">{i + 1}</span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate font-semibold">{w.name}</span>
                      <span className="block text-xs text-slate-3">{w.city}</span>
                    </span>
                    <span className="tabular text-slate-2">{w.jobs} travaux</span>
                    <span className="tabular flex w-12 items-center justify-end gap-1 font-bold">
                      <Star className="h-3.5 w-3.5 fill-warn text-warn" aria-hidden />
                      {w.rating ? formatRating(w.rating) : '—'}
                    </span>
                    <span className="tabular w-24 text-right font-extrabold">{formatMoney(w.earnings)}</span>
                  </Link>
                </li>
              ))}
            </ul>
          ) : (
            <EmptyState icon={<Star className="h-5 w-5" />} title="Aucun déneigeur actif" />
          )}
        </Card>
      </div>
    </>
  );
}
