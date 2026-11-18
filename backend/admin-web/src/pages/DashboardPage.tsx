import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowRight, Gavel, LifeBuoy, ShieldCheck, Star } from 'lucide-react';
import type { ReactNode } from 'react';
import { DailyChart } from '../components/DailyChart';
import { Card, EmptyState, ErrorState, PageHeader, Spinner } from '../components/ui';
import { api } from '../lib/api';
import { dayKey, formatMoney, formatPercent, formatRating } from '../lib/format';
import type { DashboardStats } from '../types';

function Kpi({ label, value, detail }: { label: string; value: string; detail?: string }) {
  return (
    <div className="rounded-2xl border border-line/70 bg-white p-5 shadow-card">
      <p className="text-slate-2">{label}</p>
      <p className="tabular mt-1 text-[28px] font-extrabold tracking-tight">{value}</p>
      {detail && <p className="mt-0.5 text-xs text-slate-3">{detail}</p>}
    </div>
  );
}

/** Une file d'attente : combien de dossiers attendent, et un lien pour les traiter. */
function QueueRow({ to, icon, label, count }: { to: string; icon: ReactNode; label: string; count: number }) {
  return (
    <Link to={to} className="flex items-center gap-3 rounded-xl px-3 py-3 hover:bg-ice">
      <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-ice text-ink">{icon}</div>
      <span className="flex-1 font-semibold">{label}</span>
      <span className={count > 0 ? 'tabular text-lg font-extrabold text-signal-dark' : 'tabular text-lg font-extrabold text-slate-3'}>{count}</span>
      <ArrowRight className="h-4 w-4 text-slate-3" aria-hidden />
    </Link>
  );
}

export function DashboardPage() {
  const dashboard = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => api<{ stats: DashboardStats }>('/admin/dashboard'),
  });
  const verifications = useQuery({
    queryKey: ['verifications', 'stats'],
    queryFn: () => api<{ data: { pending: number } }>('/admin/verifications/stats'),
  });
  const disputes = useQuery({
    queryKey: ['disputes', 'stats'],
    queryFn: () => api<{ stats: { pendingCount: number; overdueCount: number } }>('/disputes/admin/stats'),
  });

  if (dashboard.isLoading) return <Spinner />;
  if (dashboard.error || !dashboard.data) return <ErrorState error={dashboard.error} onRetry={() => dashboard.refetch()} />;

  const s = dashboard.data.stats;

  // Le serveur n'envoie que les jours avec activite : on complete les 8 derniers jours par des zeros.
  const byDay = new Map(s.charts.dailyReservations.map((d) => [d._id.slice(0, 10), d]));
  const days = Array.from({ length: 8 }, (_, i) => {
    const date = new Date();
    date.setDate(date.getDate() - 7 + i);
    const key = dayKey(date);
    return byDay.get(key) ?? { _id: key, count: 0, revenue: 0 };
  });

  return (
    <>
      <PageHeader title="Tableau de bord" subtitle="Activité de la plateforme et dossiers à traiter." />

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <Kpi label="Revenus ce mois" value={formatMoney(s.revenue.thisMonth)} detail={`Frais nets plateforme : ${formatMoney(s.revenue.monthlyPlatformFeesNet)}`} />
        <Kpi label="Réservations aujourd’hui" value={String(s.reservations.today)} detail={`${s.reservations.thisMonth} ce mois`} />
        <Kpi label="Taux de complétion" value={formatPercent(s.reservations.completionRate)} detail={`${s.reservations.completed} terminées sur ${s.reservations.total}`} />
        <Kpi label="Déneigeurs en ligne" value={`${s.users.activeWorkers} / ${s.users.workers}`} detail={`${s.users.clients} clients inscrits`} />
      </div>

      <div className="mt-6 grid gap-6 lg:grid-cols-3">
        <Card title="Réservations par jour, 8 derniers jours" className="lg:col-span-2">
          <DailyChart data={days} />
        </Card>

        <Card title="À traiter" padded={false}>
          <div className="p-2">
            <QueueRow to="/verifications?status=pending" icon={<ShieldCheck className="h-[18px] w-[18px]" />} label="Identités à vérifier" count={verifications.data?.data.pending ?? 0} />
            <QueueRow to="/disputes" icon={<Gavel className="h-[18px] w-[18px]" />} label="Litiges ouverts" count={disputes.data?.stats.pendingCount ?? 0} />
            <QueueRow to="/support?status=pending" icon={<LifeBuoy className="h-[18px] w-[18px]" />} label="Nouveaux tickets" count={s.support.pending} />
          </div>
          {(disputes.data?.stats.overdueCount ?? 0) > 0 && (
            <p className="mx-4 mb-4 rounded-lg bg-danger-light px-3 py-2 text-xs font-bold text-danger">
              {disputes.data?.stats.overdueCount} litige(s) en retard sur l’échéance de résolution
            </p>
          )}
        </Card>
      </div>

      <div className="mt-6 grid gap-6 lg:grid-cols-3">
        <Card title="Meilleurs déneigeurs" className="lg:col-span-2" padded={false}>
          {s.topWorkers.length ? (
            <ul className="divide-y divide-line/60">
              {s.topWorkers.map((w, i) => (
                <li key={w.id}>
                  <Link to={`/users/${w.id}`} className="flex items-center gap-4 px-5 py-3 hover:bg-ice/70">
                    <span className="tabular w-5 font-extrabold text-slate-3">{i + 1}</span>
                    <span className="flex-1 font-semibold">{w.name}</span>
                    <span className="tabular text-slate-2">{w.jobsCompleted} travaux</span>
                    <span className="tabular flex w-14 items-center justify-end gap-1 font-bold">
                      <Star className="h-3.5 w-3.5 fill-warn text-warn" aria-hidden />
                      {w.rating ? formatRating(w.rating) : '—'}
                    </span>
                    <span className="tabular w-24 text-right font-extrabold">{formatMoney(w.totalEarnings)}</span>
                  </Link>
                </li>
              ))}
            </ul>
          ) : (
            <EmptyState icon={<Star className="h-5 w-5" />} title="Aucun déneigeur actif" />
          )}
        </Card>

        <Card title="Finances (total)">
          <dl className="divide-y divide-line/60">
            {[
              ['Paiements encaissés', s.revenue.total],
              ['Frais plateforme nets', s.revenue.platformFeesNet],
              ['Versés aux déneigeurs', s.revenue.workerPayouts],
              ['Pourboires', s.revenue.tips],
            ].map(([label, value]) => (
              <div key={label as string} className="flex justify-between py-2.5">
                <dt className="text-slate-2">{label}</dt>
                <dd className="tabular font-bold">{formatMoney(value as number)}</dd>
              </div>
            ))}
          </dl>
        </Card>
      </div>
    </>
  );
}
