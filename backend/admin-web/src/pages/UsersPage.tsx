import { useNavigate } from 'react-router-dom';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { Users } from 'lucide-react';
import { Badge, Card, DataTable, EmptyState, ErrorState, PageHeader, Pager, SearchInput, Select, Spinner } from '../components/ui';
import type { Column } from '../components/ui';
import { api } from '../lib/api';
import { formatDate, fullName, initials } from '../lib/format';
import { roleLabel } from '../lib/labels';
import { useListParams } from '../lib/useListParams';
import type { Pagination, User } from '../types';

export function isUserSuspended(u: User): boolean {
  const until = u.suspendedUntil ?? u.workerProfile?.suspendedUntil;
  return Boolean((u.isSuspended || u.workerProfile?.isSuspended) && (!until || new Date(until) > new Date()));
}

export function Avatar({ user, size = 36 }: { user: Pick<User, 'firstName' | 'lastName' | 'photoUrl'>; size?: number }) {
  return user.photoUrl ? (
    <img src={user.photoUrl} alt="" className="shrink-0 rounded-full object-cover" style={{ width: size, height: size }} />
  ) : (
    <span
      className="flex shrink-0 items-center justify-center rounded-full bg-ink text-xs font-extrabold text-white"
      style={{ width: size, height: size }}
      aria-hidden
    >
      {initials(user.firstName, user.lastName)}
    </span>
  );
}

const columns: Column<User>[] = [
  {
    header: 'Compte',
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
    header: 'Rôle',
    cell: (u) => {
      const r = roleLabel(u.role);
      return <Badge tone={r.tone}>{r.label}</Badge>;
    },
  },
  { header: 'Téléphone', cell: (u) => <span className="tabular text-slate-2">{u.phoneNumber ?? '—'}</span> },
  {
    header: 'Statut',
    cell: (u) =>
      isUserSuspended(u) ? (
        <Badge tone="danger">Suspendu</Badge>
      ) : u.isActive === false ? (
        <Badge tone="neutral">Désactivé</Badge>
      ) : (
        <Badge tone="ok">Actif</Badge>
      ),
  },
  { header: 'Inscrit le', cell: (u) => <span className="text-slate-2">{formatDate(u.createdAt)}</span> },
];

export function UsersPage() {
  const navigate = useNavigate();
  const { values, page, set } = useListParams(['search', 'role'] as const);

  const query = useQuery({
    queryKey: ['users', values, page],
    queryFn: () =>
      api<{ users: User[]; pagination: Pagination }>('/admin/users', {
        query: { page, limit: 20, search: values.search, role: values.role },
      }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <PageHeader title="Comptes" subtitle="Clients, déneigeurs et administrateurs." />
      <Card padded={false}>
        <div className="flex flex-wrap gap-3 border-b border-line/70 px-5 py-3">
          <SearchInput value={values.search} onChange={(v) => set('search', v)} placeholder="Nom ou courriel" />
          <Select value={values.role} onChange={(e) => set('role', e.target.value)} aria-label="Rôle" className="w-44">
            <option value="">Tous les rôles</option>
            <option value="client">Clients</option>
            <option value="snowWorker">Déneigeurs</option>
            <option value="admin">Administrateurs</option>
          </Select>
        </div>
        {query.isLoading ? (
          <Spinner />
        ) : query.error ? (
          <ErrorState error={query.error} onRetry={() => query.refetch()} />
        ) : query.data?.users.length ? (
          <>
            <DataTable columns={columns} rows={query.data.users} rowKey={(u) => u._id} onRowClick={(u) => navigate(`/users/${u._id}`)} />
            <Pager
              page={page}
              pages={query.data.pagination.pages ?? 1}
              total={query.data.pagination.total}
              onPage={(p) => set('page', p)}
            />
          </>
        ) : (
          <EmptyState icon={<Users className="h-5 w-5" />} title="Aucun compte trouvé" hint="Modifiez la recherche ou le filtre de rôle." />
        )}
      </Card>
    </>
  );
}
