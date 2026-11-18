import { useNavigate } from 'react-router-dom';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import clsx from 'clsx';
import { ShieldCheck } from 'lucide-react';
import { Badge, Card, DataTable, EmptyState, ErrorState, PageHeader, Pager, SearchInput, Spinner } from '../components/ui';
import type { Column } from '../components/ui';
import { api } from '../lib/api';
import { formatDate, formatRelative } from '../lib/format';
import { verificationStatus } from '../lib/labels';
import { useListParams } from '../lib/useListParams';
import type { Pagination, Verification } from '../types';

const STATUS_TABS = [
  ['pending', 'À examiner'],
  ['approved', 'Approuvées'],
  ['rejected', 'Refusées'],
  ['expired', 'Expirées'],
  ['not_submitted', 'Non soumises'],
  ['', 'Toutes'],
] as const;

const columns: Column<Verification>[] = [
  {
    header: 'Déneigeur',
    cell: (v) => (
      <div className="min-w-0">
        <p className="truncate font-bold">{v.name}</p>
        <p className="truncate text-xs text-slate-2">{v.email}</p>
      </div>
    ),
  },
  {
    header: 'Statut',
    cell: (v) => {
      const s = verificationStatus(v.verification.status);
      return <Badge tone={s.tone}>{s.label}</Badge>;
    },
  },
  { header: 'Soumise', cell: (v) => <span className="text-slate-2">{v.verification.submittedAt ? formatRelative(v.verification.submittedAt) : '—'}</span> },
  { header: 'Tentatives', align: 'right', cell: (v) => <span className="tabular">{v.verification.attemptsCount ?? 0}</span> },
  { header: 'Inscrit le', cell: (v) => <span className="text-slate-2">{formatDate(v.createdAt)}</span> },
];

export function VerificationsPage() {
  const navigate = useNavigate();
  const { values, page, set } = useListParams(['status', 'search'] as const);
  const status = values.status;

  const stats = useQuery({
    queryKey: ['verifications', 'stats'],
    queryFn: () => api<{ data: Record<string, number> }>('/admin/verifications/stats'),
  });
  const query = useQuery({
    queryKey: ['verifications', values, page],
    queryFn: () =>
      api<{ data: { verifications: Verification[]; pagination: Pagination } }>('/admin/verifications', {
        query: { page, limit: 20, status, search: values.search },
      }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <PageHeader title="Vérifications d’identité" subtitle="Pièces d’identité et selfies des déneigeurs, à approuver avant qu’ils reçoivent des travaux." />

      <div className="mb-4 flex flex-wrap gap-2" role="tablist" aria-label="Filtrer par statut">
        {STATUS_TABS.map(([value, label]) => (
          <button
            key={value || 'all'}
            role="tab"
            aria-selected={status === value}
            onClick={() => set('status', value)}
            className={clsx(
              'flex items-center gap-2 rounded-full border px-3.5 py-1.5 text-sm font-bold transition-colors',
              status === value ? 'border-ink bg-ink text-white' : 'border-line bg-white text-ink hover:bg-ice',
            )}
          >
            {label}
            <span className={clsx('tabular', status === value ? 'text-white/70' : 'text-slate-3')}>
              {value ? stats.data?.data[value] ?? '' : stats.data?.data.total ?? ''}
            </span>
          </button>
        ))}
      </div>

      <Card padded={false}>
        <div className="border-b border-line/70 px-5 py-3">
          <SearchInput value={values.search} onChange={(v) => set('search', v)} placeholder="Nom ou courriel" />
        </div>
        {query.isLoading ? (
          <Spinner />
        ) : query.error ? (
          <ErrorState error={query.error} onRetry={() => query.refetch()} />
        ) : query.data?.data.verifications.length ? (
          <>
            <DataTable
              columns={columns}
              rows={query.data.data.verifications}
              rowKey={(v) => v.userId}
              onRowClick={(v) => navigate(`/verifications/${v.userId}`)}
            />
            <Pager
              page={page}
              pages={query.data.data.pagination.totalPages ?? 1}
              total={query.data.data.pagination.total}
              onPage={(p) => set('page', p)}
            />
          </>
        ) : (
          <EmptyState icon={<ShieldCheck className="h-5 w-5" />} title="Rien à afficher" hint={status === 'pending' ? 'Aucune identité en attente : tout est à jour.' : undefined} />
        )}
      </Card>
    </>
  );
}
