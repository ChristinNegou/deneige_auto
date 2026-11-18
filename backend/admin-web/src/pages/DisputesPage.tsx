import { useNavigate } from 'react-router-dom';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { Gavel } from 'lucide-react';
import { Badge, Card, DataTable, EmptyState, ErrorState, PageHeader, Pager, Select, Spinner } from '../components/ui';
import type { Column } from '../components/ui';
import { api } from '../lib/api';
import { formatMoney, formatRelative, fullName } from '../lib/format';
import { disputeStatus, disputeType, priority } from '../lib/labels';
import { useListParams } from '../lib/useListParams';
import type { Dispute, Pagination } from '../types';

const columns: Column<Dispute>[] = [
  {
    header: 'Litige',
    cell: (d) => (
      <div>
        <p className="font-bold">{disputeType[d.type] ?? d.type}</p>
        <p className="text-xs text-slate-2">Ouvert {formatRelative(d.createdAt)}</p>
      </div>
    ),
  },
  {
    header: 'Plaignant → défendeur',
    cell: (d) => (
      <span className="text-slate-2">
        {fullName(d.claimant?.user)} → {fullName(d.respondent?.user)}
      </span>
    ),
  },
  {
    header: 'Priorité',
    cell: (d) => {
      const p = priority(d.priority);
      return <Badge tone={p.tone}>{p.label}</Badge>;
    },
  },
  {
    header: 'Statut',
    cell: (d) => {
      const s = disputeStatus(d.status);
      return <Badge tone={s.tone}>{s.label}</Badge>;
    },
  },
  { header: 'Réclamé', align: 'right', cell: (d) => <span className="tabular font-extrabold">{formatMoney(d.claimedAmount)}</span> },
];

export function DisputesPage() {
  const navigate = useNavigate();
  const { values, page, set } = useListParams(['status', 'type', 'priority'] as const);

  const query = useQuery({
    queryKey: ['disputes', values, page],
    queryFn: () =>
      api<{ disputes: Dispute[]; pagination: Pagination }>('/disputes/admin/all', {
        query: { page, limit: 20, ...values },
      }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <PageHeader title="Litiges" subtitle="Plaintes entre clients et déneigeurs, à examiner et trancher." />
      <Card padded={false}>
        <div className="flex flex-wrap gap-3 border-b border-line/70 px-5 py-3">
          <Select value={values.status} onChange={(e) => set('status', e.target.value)} aria-label="Statut" className="w-48">
            <option value="">Tous les statuts</option>
            <option value="open">Ouverts</option>
            <option value="under_review">En examen</option>
            <option value="pending_response">Attente réponse</option>
            <option value="appealed">En appel</option>
            <option value="escalated">Escaladés</option>
            <option value="resolved">Résolus</option>
            <option value="closed">Fermés</option>
          </Select>
          <Select value={values.type} onChange={(e) => set('type', e.target.value)} aria-label="Type" className="w-48">
            <option value="">Tous les types</option>
            {Object.entries(disputeType).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </Select>
          <Select value={values.priority} onChange={(e) => set('priority', e.target.value)} aria-label="Priorité" className="w-40">
            <option value="">Toutes priorités</option>
            <option value="urgent">Urgente</option>
            <option value="high">Haute</option>
            <option value="medium">Moyenne</option>
            <option value="low">Basse</option>
          </Select>
        </div>
        {query.isLoading ? (
          <Spinner />
        ) : query.error ? (
          <ErrorState error={query.error} onRetry={() => query.refetch()} />
        ) : query.data?.disputes.length ? (
          <>
            <DataTable columns={columns} rows={query.data.disputes} rowKey={(d) => d._id} onRowClick={(d) => navigate(`/disputes/${d._id}`)} />
            <Pager page={page} pages={query.data.pagination.pages ?? 1} total={query.data.pagination.total} onPage={(p) => set('page', p)} />
          </>
        ) : (
          <EmptyState icon={<Gavel className="h-5 w-5" />} title="Aucun litige" hint="Aucun litige ne correspond à ces filtres." />
        )}
      </Card>
    </>
  );
}
