import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { CreditCard, Trash2 } from 'lucide-react';
import { Badge, Button, Card, DataTable, EmptyState, ErrorState, Modal, PageHeader, Spinner, useToast } from '../components/ui';
import type { Column } from '../components/ui';
import { api } from '../lib/api';
import { formatDate } from '../lib/format';
import type { ConnectAccount } from '../types';

interface AccountsResponse {
  accounts: ConnectAccount[];
  stripeTotal: number;
  linkedToWorkers: number;
  orphanOnStripe: number;
  invalidInDb: number;
}

function accountState(a: ConnectAccount) {
  if (a.isInvalidOnStripe) return <Badge tone="danger">Introuvable sur Stripe</Badge>;
  if (a.isOrphan) return <Badge tone="warn">Sans déneigeur</Badge>;
  if (a.payoutsEnabled) return <Badge tone="ok">Prêt à recevoir</Badge>;
  if (a.detailsSubmitted) return <Badge tone="info">En vérification</Badge>;
  return <Badge tone="warn">Inscription incomplète</Badge>;
}

export function StripeAccountsPage() {
  const qc = useQueryClient();
  const toast = useToast();
  const [toDelete, setToDelete] = useState<ConnectAccount | null>(null);

  const query = useQuery({
    queryKey: ['stripe-accounts'],
    queryFn: () => api<AccountsResponse>('/stripe-connect/admin/accounts'),
  });

  const remove = useMutation({
    // Compte lie a un deneigeur : on passe par lui pour nettoyer aussi la base.
    mutationFn: (a: ConnectAccount) =>
      api<{ message: string }>(
        a.workerId ? `/stripe-connect/admin/accounts/${a.workerId}` : `/stripe-connect/admin/orphan-accounts/${a.stripeAccountId}`,
        { method: 'DELETE' },
      ),
    onSuccess: (res) => {
      toast(res.message ?? 'Compte supprimé');
      setToDelete(null);
      qc.invalidateQueries({ queryKey: ['stripe-accounts'] });
      qc.invalidateQueries({ queryKey: ['workers'] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Suppression refusée', 'danger'),
  });

  const columns: Column<ConnectAccount>[] = [
    {
      header: 'Déneigeur',
      cell: (a) =>
        a.workerId ? (
          <Link to={`/users/${a.workerId}`} onClick={(e) => e.stopPropagation()} className="min-w-0">
            <p className="truncate font-bold text-glacier hover:underline">{a.workerName}</p>
            <p className="truncate text-xs text-slate-2">{a.workerEmail}</p>
          </Link>
        ) : (
          <span className="text-slate-3">{a.email ?? 'Aucun'}</span>
        ),
    },
    { header: 'Compte Stripe', cell: (a) => <span className="font-mono text-xs">{a.stripeAccountId}</span> },
    { header: 'État', cell: accountState },
    { header: 'Créé le', cell: (a) => <span className="text-slate-2">{formatDate(a.created)}</span> },
    {
      header: 'Action',
      align: 'right',
      cell: (a) => (
        <Button variant="ghost" aria-label="Supprimer le compte" icon={<Trash2 className="h-4 w-4" />} onClick={() => setToDelete(a)} />
      ),
    },
  ];

  if (query.isLoading) return <Spinner />;
  if (query.error || !query.data) return <ErrorState error={query.error} onRetry={() => query.refetch()} />;

  const d = query.data;

  return (
    <>
      <PageHeader title="Comptes Stripe" subtitle="Comptes Stripe Connect qui reçoivent les versements des déneigeurs." />

      <div className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
        {[
          ['Comptes sur Stripe', d.stripeTotal],
          ['Liés à un déneigeur', d.linkedToWorkers],
          ['Sans déneigeur', d.orphanOnStripe],
          ['Introuvables sur Stripe', d.invalidInDb],
        ].map(([label, value]) => (
          <div key={label} className="rounded-2xl border border-line/70 bg-white p-5 shadow-card">
            <p className="text-slate-2">{label}</p>
            <p className="tabular mt-1 text-[26px] font-extrabold">{value}</p>
          </div>
        ))}
      </div>

      <Card padded={false}>
        {d.accounts.length ? (
          <DataTable columns={columns} rows={d.accounts} rowKey={(a) => a.stripeAccountId} />
        ) : (
          <EmptyState
            icon={<CreditCard className="h-5 w-5" />}
            title="Aucun compte Stripe Connect"
            hint="Les déneigeurs créent leur compte depuis l’application, dans Paiements."
          />
        )}
      </Card>

      <Modal
        open={!!toDelete}
        onClose={() => setToDelete(null)}
        title="Supprimer ce compte Stripe ?"
        footer={
          <>
            <Button onClick={() => setToDelete(null)}>Annuler</Button>
            <Button variant="danger" loading={remove.isPending} onClick={() => toDelete && remove.mutate(toDelete)}>
              Supprimer définitivement
            </Button>
          </>
        }
      >
        <p className="text-slate-2">
          Le compte <span className="font-mono text-xs text-ink">{toDelete?.stripeAccountId}</span> sera supprimé chez Stripe.
          {toDelete?.workerName
            ? ` ${toDelete.workerName} ne recevra plus de versements avant d’avoir créé un nouveau compte dans l’application.`
            : ' Il n’est lié à aucun déneigeur.'}
        </p>
        <p className="font-bold text-danger">Cette action est irréversible.</p>
      </Modal>
    </>
  );
}
