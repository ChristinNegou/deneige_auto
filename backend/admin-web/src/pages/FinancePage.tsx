import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import clsx from 'clsx';
import { AlertTriangle, CheckCircle2, RefreshCw, Send, Wrench } from 'lucide-react';
import { Badge, Button, Card, DataTable, ErrorState, Modal, PageHeader, Spinner, useToast } from '../components/ui';
import type { Column } from '../components/ui';
import { api } from '../lib/api';
import { formatDate, formatMoney, parseDay } from '../lib/format';
import { payoutStatus } from '../lib/labels';
import type { PayoutSummary, Reconciliation, RevenueRow } from '../types';

const monthFmt = new Intl.DateTimeFormat('fr-CA', { month: 'long', year: 'numeric' });

const DISCREPANCY_LABELS: Record<string, { label: string; money: boolean }> = {
  revenue: { label: 'Paiements encaissés', money: true },
  workerPayouts: { label: 'Versements aux déneigeurs', money: true },
  stripeFees: { label: 'Frais Stripe', money: true },
  transactionCount: { label: 'Nombre de transactions', money: false },
};

function Kpi({ label, value, detail }: { label: string; value: string; detail?: string }) {
  return (
    <div className="rounded-2xl border border-line/70 bg-white p-5 shadow-card">
      <p className="text-slate-2">{label}</p>
      <p className="tabular mt-1 text-[26px] font-extrabold tracking-tight">{value}</p>
      {detail && <p className="mt-0.5 text-xs text-slate-3">{detail}</p>}
    </div>
  );
}

/**
 * Action financiere en deux temps : simulation (dryRun) puis confirmation.
 * Rien ne bouge chez Stripe tant que l'admin n'a pas vu le resultat simule.
 */
function TwoStepAction({ title, description, endpoint, confirmLabel, describe, icon }: {
  title: string;
  description: string;
  endpoint: string;
  confirmLabel: (s: PayoutSummary) => string;
  /** Resume de la simulation, en clair (le message du serveur parle de dryRun). */
  describe: (s: PayoutSummary) => string;
  icon: React.ReactNode;
}) {
  const qc = useQueryClient();
  const toast = useToast();
  const [preview, setPreview] = useState<{ message: string; summary: PayoutSummary } | null>(null);

  const run = useMutation({
    mutationFn: (dryRun: boolean) =>
      api<{ message: string; summary: PayoutSummary }>(endpoint, { method: 'POST', body: { dryRun } }),
    onSuccess: (res, dryRun) => {
      if (dryRun) {
        setPreview(res);
        return;
      }
      toast(res.message);
      setPreview(null);
      qc.invalidateQueries({ queryKey: ['finance'] });
      qc.invalidateQueries({ queryKey: ['dashboard'] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Action refusée', 'danger'),
  });

  const details = preview?.summary.details ?? [];
  const actionable = preview ? preview.summary.found - (preview.summary.noAccount ?? 0) : 0;

  return (
    <>
      <div className="flex items-start gap-4 py-4 first:pt-0 last:pb-0">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-ice text-ink">{icon}</div>
        <div className="flex-1">
          <p className="font-bold">{title}</p>
          <p className="text-slate-2">{description}</p>
        </div>
        <Button loading={run.isPending && run.variables === true} onClick={() => run.mutate(true)}>
          Analyser
        </Button>
      </div>

      <Modal
        open={!!preview}
        onClose={() => setPreview(null)}
        title={title}
        footer={
          <>
            <Button onClick={() => setPreview(null)}>Fermer</Button>
            {actionable > 0 && preview && (
              <Button variant="accent" loading={run.isPending && run.variables === false} onClick={() => run.mutate(false)}>
                {confirmLabel(preview.summary)}
              </Button>
            )}
          </>
        }
      >
        <p className="rounded-lg bg-ice px-3 py-2 font-semibold">{preview && describe(preview.summary)}</p>
        {details.length > 0 && (
          <ul className="max-h-64 divide-y divide-line/60 overflow-y-auto">
            {details.map((d) => {
              const amount = d.amount ?? d.workerAmount;
              return (
                <li key={d.reservationId ?? d.id} className="flex items-center justify-between gap-3 py-2">
                  <span>
                    <span className="font-semibold">{d.workerName ?? `Réservation de ${formatMoney(d.totalPrice)}`}</span>
                    {d.hasStripeConnect === false && <span className="ml-2 text-xs font-bold text-warn">sans compte Stripe</span>}
                  </span>
                  {amount !== undefined && (
                    <span className="tabular font-bold">
                      {formatMoney(amount)}
                      {d.workerAmount !== undefined && <span className="ml-1 text-xs font-semibold text-slate-3">au déneigeur</span>}
                    </span>
                  )}
                </li>
              );
            })}
          </ul>
        )}
        {actionable > 0 && <p className="text-xs text-slate-3">Ceci n’était qu’une simulation. Rien n’a encore été envoyé à Stripe.</p>}
      </Modal>
    </>
  );
}

const problemColumns: Column<Reconciliation['problematicReservations'][number]>[] = [
  { header: 'Créée le', cell: (r) => <span className="text-slate-2">{formatDate(r.createdAt)}</span> },
  {
    header: 'Versement',
    cell: (r) => <Badge tone={r.payoutStatus === 'failed' ? 'danger' : 'warn'}>{payoutStatus[r.payoutStatus] ?? r.payoutStatus}</Badge>,
  },
  { header: 'Montant', align: 'right', cell: (r) => <span className="tabular font-extrabold">{formatMoney(r.totalPrice)}</span> },
  {
    header: 'Détail',
    align: 'right',
    cell: (r) => (
      <Link to={`/reservations/${r.id}`} className="font-bold text-glacier hover:underline">
        Ouvrir
      </Link>
    ),
  },
];

export function FinancePage() {
  const qc = useQueryClient();
  const toast = useToast();

  const recon = useQuery({
    queryKey: ['finance', 'reconciliation'],
    queryFn: () => api<Reconciliation>('/admin/finance/reconciliation'),
  });
  const revenue = useQuery({
    queryKey: ['finance', 'revenue'],
    queryFn: () => api<{ report: RevenueRow[] }>('/admin/reports/revenue', { query: { period: 'month' } }),
  });

  const sync = useMutation({
    mutationFn: () => api<{ message: string; results: { errors?: string[] } }>('/admin/finance/sync-stripe', { method: 'POST', body: {} }),
    onSuccess: (res) => {
      toast(res.results?.errors?.length ? `${res.message} (${res.results.errors.length} erreur(s))` : res.message, res.results?.errors?.length ? 'danger' : 'ok');
      qc.invalidateQueries({ queryKey: ['finance'] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Synchronisation impossible', 'danger'),
  });

  if (recon.isLoading) return <Spinner />;
  if (recon.error || !recon.data) return <ErrorState error={recon.error} onRetry={() => recon.refetch()} />;

  const r = recon.data;
  const months = [...(revenue.data?.report ?? [])].sort((a, b) => String(b._id).localeCompare(String(a._id)));

  return (
    <>
      <PageHeader
        title="Finances"
        subtitle={`Comparaison avec Stripe du ${formatDate(r.period.start)} au ${formatDate(r.period.end)}.`}
        actions={
          <Button icon={<RefreshCw className="h-4 w-4" />} loading={sync.isPending} onClick={() => sync.mutate()}>
            Synchroniser avec Stripe
          </Button>
        }
      />

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <Kpi label="Solde Stripe disponible" value={formatMoney(r.stripe.balance?.available)} detail={`${formatMoney(r.stripe.balance?.pending)} en attente`} />
        <Kpi label="Encaissé sur Stripe" value={formatMoney(r.stripe.chargesTotal)} detail={`${r.stripe.chargesCount} paiement(s) sur 30 jours`} />
        <Kpi label="Remboursé" value={formatMoney(r.stripe.refundsTotal)} detail="Sur 30 jours" />
        <Kpi label="Frais Stripe" value={formatMoney(r.stripe.feesTotal)} detail="Sur 30 jours" />
      </div>

      {r.stripe.error && (
        <p className="mt-4 rounded-xl bg-danger-light px-4 py-3 font-semibold text-danger">Stripe n’a pas répondu : {r.stripe.error}</p>
      )}

      <div className="mt-6 grid gap-6 lg:grid-cols-5">
        <Card title="Base de données ou Stripe : les chiffres concordent-ils ?" className="lg:col-span-3" padded={false}>
          <table className="w-full">
            <thead>
              <tr className="border-b border-line text-left text-xs font-bold text-slate-2">
                <th scope="col" className="px-5 py-2.5">Mesure</th>
                <th scope="col" className="px-5 py-2.5 text-right">Application</th>
                <th scope="col" className="px-5 py-2.5 text-right">Stripe</th>
                <th scope="col" className="px-5 py-2.5 text-right">Écart</th>
              </tr>
            </thead>
            <tbody>
              {Object.entries(r.discrepancies).map(([key, d]) => {
                const meta = DISCREPANCY_LABELS[key] ?? { label: key, money: true };
                const fmt = (v: number) => (meta.money ? formatMoney(v) : String(v));
                const off = Math.abs(d.difference) >= 0.01;
                return (
                  <tr key={key} className="border-b border-line/60 last:border-0">
                    <td className="px-5 py-3 font-semibold">{meta.label}</td>
                    <td className="tabular px-5 py-3 text-right">{fmt(d.local)}</td>
                    <td className="tabular px-5 py-3 text-right">{fmt(d.stripe)}</td>
                    <td className={clsx('tabular px-5 py-3 text-right font-extrabold', off ? 'text-warn' : 'text-ok')}>
                      {off ? fmt(d.difference) : 'OK'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </Card>

        <Card title="Recommandations" className="lg:col-span-2">
          {r.recommendations.length ? (
            <ul className="space-y-3">
              {r.recommendations.map((rec, i) => (
                <li key={i} className="flex gap-3">
                  <AlertTriangle className={clsx('mt-0.5 h-4 w-4 shrink-0', rec.type === 'error' ? 'text-danger' : 'text-warn')} aria-hidden />
                  <span>
                    <span className="font-semibold">{rec.message}</span>
                    {rec.action && <span className="block text-slate-2">{rec.action}</span>}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="flex items-center gap-2 font-semibold text-ok">
              <CheckCircle2 className="h-4 w-4" aria-hidden />
              Tout concorde.
            </p>
          )}
        </Card>
      </div>

      <div className="mt-6 grid gap-6 lg:grid-cols-5">
        <Card title="Versements aux déneigeurs" className="lg:col-span-3">
          <div className="divide-y divide-line/60">
            <TwoStepAction
              title="Verser les paiements en attente"
              description="Envoie leur part aux déneigeurs pour les travaux terminés qui n’ont pas encore été payés."
              endpoint="/admin/finance/process-pending-payouts"
              icon={<Send className="h-[18px] w-[18px]" />}
              confirmLabel={(s) => `Verser ${s.found - (s.noAccount ?? 0)} paiement(s)`}
              describe={(s) =>
                s.found === 0
                  ? 'Aucun versement en attente.'
                  : `${s.found} versement(s) en attente, dont ${s.noAccount ?? 0} bloqué(s) faute de compte Stripe Connect.`
              }
            />
            <TwoStepAction
              title="Recalculer les montants de versement"
              description="Corrige les réservations payées dont la part du déneigeur ou les frais n’ont pas été calculés."
              endpoint="/admin/finance/fix-payouts"
              icon={<Wrench className="h-[18px] w-[18px]" />}
              confirmLabel={(s) => `Corriger ${s.found} réservation(s)`}
              describe={(s) => (s.found === 0 ? 'Tous les montants sont déjà calculés.' : `${s.found} réservation(s) ont des montants de versement à recalculer.`)}
            />
          </div>
        </Card>

        <Card title="Revenus par mois" className="lg:col-span-2" padded={false}>
          {months.length ? (
            <table className="w-full">
              <thead>
                <tr className="border-b border-line text-left text-xs font-bold text-slate-2">
                  <th scope="col" className="px-5 py-2.5">Mois</th>
                  <th scope="col" className="px-5 py-2.5 text-right">Réserv.</th>
                  <th scope="col" className="px-5 py-2.5 text-right">Encaissé</th>
                  <th scope="col" className="px-5 py-2.5 text-right">Frais nets</th>
                </tr>
              </thead>
              <tbody>
                {months.map((m) => (
                  <tr key={m._id} className="border-b border-line/60 last:border-0">
                    <td className="px-5 py-2.5 font-semibold first-letter:uppercase">{monthFmt.format(parseDay(`${m._id}-01`))}</td>
                    <td className="tabular px-5 py-2.5 text-right">{m.count}</td>
                    <td className="tabular px-5 py-2.5 text-right font-bold">{formatMoney(m.totalRevenue)}</td>
                    <td className="tabular px-5 py-2.5 text-right">{formatMoney(m.platformFees)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <p className="p-5 text-slate-3">Aucun revenu enregistré.</p>
          )}
        </Card>
      </div>

      {r.problematicReservations.length > 0 && (
        <Card title={`Réservations à vérifier (${r.problematicReservations.length})`} className="mt-6" padded={false}>
          <DataTable columns={problemColumns} rows={r.problematicReservations} rowKey={(p) => p.id} />
        </Card>
      )}
    </>
  );
}
