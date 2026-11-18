import { useNavigate } from 'react-router-dom';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { CalendarCheck } from 'lucide-react';
import { Badge, Card, DataTable, EmptyState, ErrorState, Input, PageHeader, Pager, Select, Spinner } from '../components/ui';
import type { Column } from '../components/ui';
import { api } from '../lib/api';
import { formatDateTime, formatMoney, fullName } from '../lib/format';
import { paymentStatus, reservationStatus } from '../lib/labels';
import { useListParams } from '../lib/useListParams';
import type { Pagination, Reservation } from '../types';

const columns: Column<Reservation>[] = [
  { header: 'Départ', cell: (r) => <span className="tabular font-semibold">{formatDateTime(r.departureTime)}</span> },
  {
    header: 'Client',
    cell: (r) => (
      <div className="min-w-0">
        <p className="truncate font-bold">{fullName(r.userId)}</p>
        <p className="truncate text-xs text-slate-2">{r.location?.address ?? '—'}</p>
      </div>
    ),
  },
  { header: 'Déneigeur', cell: (r) => <span className="text-slate-2">{r.workerId ? fullName(r.workerId) : '—'}</span> },
  {
    header: 'Statut',
    cell: (r) => {
      const s = reservationStatus(r.status);
      return (
        <span className="flex flex-wrap gap-1.5">
          <Badge tone={s.tone}>{s.label}</Badge>
          {r.dispute?.hasDispute && <Badge tone="danger">Litige</Badge>}
        </span>
      );
    },
  },
  {
    header: 'Paiement',
    cell: (r) => {
      const p = paymentStatus(r.paymentStatus);
      return <Badge tone={p.tone}>{p.label}</Badge>;
    },
  },
  { header: 'Montant', align: 'right', cell: (r) => <span className="tabular font-extrabold">{formatMoney(r.totalPrice)}</span> },
];

export function ReservationsPage() {
  const navigate = useNavigate();
  const { values, page, set } = useListParams(['status', 'startDate', 'endDate'] as const);

  const query = useQuery({
    queryKey: ['reservations', values, page],
    queryFn: () =>
      api<{ reservations: Reservation[]; pagination: Pagination }>('/admin/reservations', {
        query: { page, limit: 20, ...values },
      }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <PageHeader title="Réservations" subtitle="Toutes les réservations, leurs paiements et remboursements." />
      <Card padded={false}>
        <div className="flex flex-wrap items-center gap-3 border-b border-line/70 px-5 py-3">
          <Select value={values.status} onChange={(e) => set('status', e.target.value)} aria-label="Statut" className="w-44">
            <option value="">Tous les statuts</option>
            <option value="pending">En attente</option>
            <option value="assigned">Assignées</option>
            <option value="inProgress">En cours</option>
            <option value="completed">Terminées</option>
            <option value="cancelled">Annulées</option>
          </Select>
          <label className="flex items-center gap-2 text-slate-2">
            Du
            <Input type="date" value={values.startDate} onChange={(e) => set('startDate', e.target.value)} className="w-40" />
          </label>
          <label className="flex items-center gap-2 text-slate-2">
            au
            <Input type="date" value={values.endDate} onChange={(e) => set('endDate', e.target.value)} className="w-40" />
          </label>
        </div>
        {query.isLoading ? (
          <Spinner />
        ) : query.error ? (
          <ErrorState error={query.error} onRetry={() => query.refetch()} />
        ) : query.data?.reservations.length ? (
          <>
            <DataTable
              columns={columns}
              rows={query.data.reservations}
              rowKey={(r) => r._id}
              onRowClick={(r) => navigate(`/reservations/${r._id}`)}
            />
            <Pager page={page} pages={query.data.pagination.pages ?? 1} total={query.data.pagination.total} onPage={(p) => set('page', p)} />
          </>
        ) : (
          <EmptyState icon={<CalendarCheck className="h-5 w-5" />} title="Aucune réservation" hint="Aucune réservation ne correspond à ces filtres." />
        )}
      </Card>
    </>
  );
}
