import { useNavigate } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { HardHat, Star } from 'lucide-react';
import { Badge, Button, Card, DataTable, EmptyState, ErrorState, PageHeader, Select, Spinner, useToast } from '../components/ui';
import type { Column } from '../components/ui';
import { api } from '../lib/api';
import { formatMoney, formatRating, fullName } from '../lib/format';
import { verificationStatus } from '../lib/labels';
import { useListParams } from '../lib/useListParams';
import type { User, WorkerWarning } from '../types';
import { Avatar, isUserSuspended } from './UsersPage';

const columns: Column<User>[] = [
  {
    header: 'Déneigeur',
    cell: (u) => (
      <div className="flex items-center gap-3">
        <Avatar user={u} />
        <div className="min-w-0">
          <p className="truncate font-bold">{fullName(u)}</p>
          <p className="truncate text-xs text-slate-2">{u.email}</p>
        </div>
      </div>
    ),
  },
  {
    header: 'Disponibilité',
    cell: (u) =>
      isUserSuspended(u) ? (
        <Badge tone="danger">Suspendu</Badge>
      ) : u.workerProfile?.isAvailable ? (
        <Badge tone="ok">En ligne</Badge>
      ) : (
        <Badge tone="neutral">Hors ligne</Badge>
      ),
  },
  {
    header: 'Identité',
    cell: (u) => {
      const v = verificationStatus(u.workerProfile?.identityVerification?.status ?? 'not_submitted');
      return <Badge tone={v.tone}>{v.label}</Badge>;
    },
  },
  {
    header: 'Paiements',
    cell: (u) =>
      u.workerProfile?.stripeConnectId ? <span className="text-slate-2">Stripe configuré</span> : <span className="font-semibold text-warn">Stripe manquant</span>,
  },
  { header: 'Travaux', align: 'right', cell: (u) => <span className="tabular">{u.workerProfile?.totalJobsCompleted ?? 0}</span> },
  {
    header: 'Note',
    align: 'right',
    cell: (u) => (
      <span className="tabular inline-flex items-center gap-1 font-bold">
        <Star className="h-3.5 w-3.5 fill-warn text-warn" aria-hidden />
        {u.workerProfile?.averageRating ? formatRating(u.workerProfile.averageRating) : '—'}
      </span>
    ),
  },
  { header: 'Gains', align: 'right', cell: (u) => <span className="tabular font-extrabold">{formatMoney(u.workerProfile?.totalEarnings)}</span> },
];

function WarningsCard() {
  const qc = useQueryClient();
  const toast = useToast();
  const query = useQuery({
    queryKey: ['workers', 'warnings'],
    queryFn: () => api<{ workers: WorkerWarning[] }>('/admin/workers/warnings'),
  });
  const reset = useMutation({
    mutationFn: (id: string) => api<{ message: string }>(`/admin/workers/${id}/reset-warnings`, { method: 'POST' }),
    onSuccess: (res) => {
      toast(res.message);
      qc.invalidateQueries({ queryKey: ['workers'] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Réinitialisation refusée', 'danger'),
  });

  const workers = query.data?.workers ?? [];
  if (!workers.length) return null;

  return (
    <Card title="Avertissements pour annulation" className="mb-6" padded={false}>
      <p className="px-5 pt-4 text-slate-2">
        Un déneigeur qui annule trop de travaux reçoit des avertissements, puis est suspendu automatiquement. Réinitialisez-les si l’annulation était justifiée.
      </p>
      <ul className="divide-y divide-line/60">
        {workers.map((w) => (
          <li key={w.id} className="flex items-center gap-4 px-5 py-3">
            <div className="min-w-0 flex-1">
              <p className="truncate font-bold">{w.name}</p>
              <p className="truncate text-xs text-slate-2">{w.email}</p>
            </div>
            <Badge tone={w.warningCount >= 3 ? 'danger' : 'warn'}>
              {w.warningCount} avertissement{w.warningCount > 1 ? 's' : ''}
            </Badge>
            {w.isSuspended && <Badge tone="danger">Suspendu</Badge>}
            <Button loading={reset.isPending && reset.variables === w.id} onClick={() => reset.mutate(w.id)}>
              Réinitialiser
            </Button>
          </li>
        ))}
      </ul>
    </Card>
  );
}

export function WorkersPage() {
  const navigate = useNavigate();
  const { values, set } = useListParams(['state'] as const);

  const query = useQuery({
    queryKey: ['workers', 'list'],
    queryFn: () => api<{ workers: User[] }>('/admin/workers'),
  });

  // La liste est courte : le filtre se fait dans le navigateur
  const workers = (query.data?.workers ?? []).filter((u) => {
    if (values.state === 'online') return u.workerProfile?.isAvailable && !isUserSuspended(u);
    if (values.state === 'offline') return !u.workerProfile?.isAvailable && !isUserSuspended(u);
    if (values.state === 'suspended') return isUserSuspended(u);
    if (values.state === 'unverified') return u.workerProfile?.identityVerification?.status !== 'approved';
    if (values.state === 'nostripe') return !u.workerProfile?.stripeConnectId;
    return true;
  });
  const online = (query.data?.workers ?? []).filter((u) => u.workerProfile?.isAvailable && !isUserSuspended(u)).length;

  return (
    <>
      <PageHeader title="Déneigeurs" subtitle={query.data ? `${online} en ligne sur ${query.data.workers.length}.` : undefined} />
      <WarningsCard />
      <Card padded={false}>
        <div className="border-b border-line/70 px-5 py-3">
          <Select value={values.state} onChange={(e) => set('state', e.target.value)} aria-label="Filtrer" className="w-60">
            <option value="">Tous les déneigeurs</option>
            <option value="online">En ligne</option>
            <option value="offline">Hors ligne</option>
            <option value="suspended">Suspendus</option>
            <option value="unverified">Identité non approuvée</option>
            <option value="nostripe">Sans compte Stripe</option>
          </Select>
        </div>
        {query.isLoading ? (
          <Spinner />
        ) : query.error ? (
          <ErrorState error={query.error} onRetry={() => query.refetch()} />
        ) : workers.length ? (
          <DataTable columns={columns} rows={workers} rowKey={(u) => u._id} onRowClick={(u) => navigate(`/users/${u._id}`)} />
        ) : (
          <EmptyState icon={<HardHat className="h-5 w-5" />} title="Aucun déneigeur" hint="Aucun déneigeur ne correspond à ce filtre." />
        )}
      </Card>
    </>
  );
}
