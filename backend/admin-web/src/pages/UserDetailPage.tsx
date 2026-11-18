import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft, Ban, ShieldCheck, Undo2 } from 'lucide-react';
import { Badge, Button, Card, DataTable, ErrorState, Field, Label, Modal, PageHeader, Select, Spinner, Textarea, useToast } from '../components/ui';
import { api } from '../lib/api';
import { formatBirthDate, formatDate, formatDateTime, formatMoney, formatRating, fullName } from '../lib/format';
import { equipment, reservationStatus, roleLabel, verificationStatus } from '../lib/labels';
import type { Reservation, User } from '../types';
import { Avatar, isUserSuspended } from './UsersPage';

export function BackLink({ to, label }: { to: string; label: string }) {
  return (
    <Link to={to} className="mb-2 inline-flex items-center gap-1.5 text-sm font-semibold text-slate-2 hover:text-ink">
      <ArrowLeft className="h-4 w-4" aria-hidden />
      {label}
    </Link>
  );
}

function SuspendDialog({ user, open, onClose }: { user: User; open: boolean; onClose: () => void }) {
  const qc = useQueryClient();
  const toast = useToast();
  const [days, setDays] = useState('7');
  const [reason, setReason] = useState('');
  const mutation = useMutation({
    mutationFn: () => api<{ message: string }>(`/admin/users/${user._id}/suspend`, { method: 'POST', body: { days: Number(days), reason } }),
    onSuccess: (res) => {
      toast(res.message);
      qc.invalidateQueries({ queryKey: ['user', user._id] });
      qc.invalidateQueries({ queryKey: ['users'] });
      onClose();
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Échec de la suspension', 'danger'),
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={`Suspendre ${fullName(user)}`}
      footer={
        <>
          <Button onClick={onClose}>Annuler</Button>
          <Button variant="danger" loading={mutation.isPending} disabled={!reason.trim()} onClick={() => mutation.mutate()}>
            Suspendre le compte
          </Button>
        </>
      }
    >
      <p className="text-slate-2">
        La personne ne pourra plus utiliser l’application pendant la durée choisie et sera notifiée avec la raison indiquée.
      </p>
      <div>
        <Label htmlFor="days">Durée</Label>
        <Select id="days" value={days} onChange={(e) => setDays(e.target.value)}>
          <option value="1">1 jour</option>
          <option value="3">3 jours</option>
          <option value="7">7 jours</option>
          <option value="30">30 jours</option>
          <option value="365">1 an</option>
        </Select>
      </div>
      <div>
        <Label htmlFor="reason">Raison (visible par la personne)</Label>
        <Textarea id="reason" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Ex. : annulations répétées à la dernière minute" />
      </div>
    </Modal>
  );
}

function WorkerJobs({ workerId }: { workerId: string }) {
  const navigate = useNavigate();
  const query = useQuery({
    queryKey: ['user', workerId, 'jobs'],
    queryFn: () => api<{ jobs: Reservation[]; pagination: { total: number } }>(`/admin/workers/${workerId}/jobs`, { query: { limit: 10 } }),
  });
  const jobs = query.data?.jobs ?? [];
  return (
    <Card title={`Travaux récents${query.data ? ` (${query.data.pagination.total} au total)` : ''}`} className="mt-6" padded={false}>
      {jobs.length ? (
        <DataTable
          rows={jobs}
          rowKey={(j) => j._id}
          onRowClick={(j) => navigate(`/reservations/${j._id}`)}
          columns={[
            { header: 'Départ', cell: (j) => <span className="tabular font-semibold">{formatDateTime(j.departureTime)}</span> },
            { header: 'Client', cell: (j) => <span className="text-slate-2">{fullName(j.userId)}</span> },
            {
              header: 'Statut',
              cell: (j) => {
                const s = reservationStatus(j.status);
                return <Badge tone={s.tone}>{s.label}</Badge>;
              },
            },
            { header: 'Note', align: 'right', cell: (j) => <span className="tabular">{j.rating ? `${j.rating} / 5` : '—'}</span> },
            { header: 'Montant', align: 'right', cell: (j) => <span className="tabular font-extrabold">{formatMoney(j.totalPrice)}</span> },
          ]}
        />
      ) : (
        <p className="p-5 text-slate-3">{query.isLoading ? 'Chargement…' : 'Aucun travail pour l’instant.'}</p>
      )}
    </Card>
  );
}

export function UserDetailPage() {
  const { id = '' } = useParams();
  const qc = useQueryClient();
  const toast = useToast();
  const [suspendOpen, setSuspendOpen] = useState(false);

  const query = useQuery({
    queryKey: ['user', id],
    queryFn: () => api<{ user: User; workerStats?: Record<string, number> | null }>(`/admin/users/${id}`),
  });

  const unsuspend = useMutation({
    mutationFn: () => api<{ message: string }>(`/admin/users/${id}/unsuspend`, { method: 'POST' }),
    onSuccess: (res) => {
      toast(res.message);
      qc.invalidateQueries({ queryKey: ['user', id] });
      qc.invalidateQueries({ queryKey: ['users'] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Échec', 'danger'),
  });

  if (query.isLoading) return <Spinner />;
  if (query.error || !query.data) return <ErrorState error={query.error} onRetry={() => query.refetch()} />;

  const u = query.data.user;
  const role = roleLabel(u.role);
  const suspended = isUserSuspended(u);
  const wp = u.workerProfile;
  const cp = u.clientProfile;
  const verif = verificationStatus(wp?.identityVerification?.status);

  return (
    <>
      <PageHeader
        back={<BackLink to="/users" label="Comptes" />}
        title={
          <span className="flex items-center gap-3">
            <Avatar user={u} size={44} />
            {fullName(u)}
          </span>
        }
        subtitle={
          <span className="flex flex-wrap items-center gap-2">
            <Badge tone={role.tone}>{role.label}</Badge>
            {suspended ? <Badge tone="danger">Suspendu jusqu’au {formatDate(u.suspendedUntil ?? wp?.suspendedUntil)}</Badge> : <Badge tone="ok">Actif</Badge>}
          </span>
        }
        actions={
          u.role !== 'admin' &&
          (suspended ? (
            <Button icon={<Undo2 className="h-4 w-4" />} loading={unsuspend.isPending} onClick={() => unsuspend.mutate()}>
              Lever la suspension
            </Button>
          ) : (
            <Button variant="danger" icon={<Ban className="h-4 w-4" />} onClick={() => setSuspendOpen(true)}>
              Suspendre
            </Button>
          ))
        }
      />

      {suspended && (u.suspensionReason ?? null) && (
        <p className="mb-6 rounded-xl bg-danger-light px-4 py-3 font-semibold text-danger">Raison de la suspension : {u.suspensionReason}</p>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <Card title="Coordonnées">
          <dl className="divide-y divide-line/60">
            <Field label="Courriel">{u.email}</Field>
            <Field label="Téléphone">
              {u.phoneNumber ?? '—'} {u.phoneVerified && <Badge tone="ok">Vérifié</Badge>}
            </Field>
            <Field label="Date de naissance">{u.dateOfBirth ? formatBirthDate(u.dateOfBirth) : 'Non renseignée'}</Field>
            <Field label="Inscrit le">{formatDate(u.createdAt)}</Field>
            <Field label="Client Stripe">{u.stripeCustomerId ? <span className="font-mono text-xs">{u.stripeCustomerId}</span> : '—'}</Field>
          </dl>
        </Card>

        {u.role === 'client' && (
          <Card title="Activité client">
            <dl className="divide-y divide-line/60">
              <Field label="Réservations">{cp?.completedReservations ?? 0} terminées sur {cp?.totalReservations ?? 0}</Field>
              <Field label="Montant dépensé">{formatMoney(cp?.totalSpent)}</Field>
              <Field label="Annulations">{cp?.totalCancellations ?? 0}</Field>
              <Field label="Litiges">{cp?.totalDisputes ?? 0}</Field>
              <Field label="Avertissements">{cp?.warningCount ?? 0}</Field>
              <Field label="Score de fiabilité">{cp?.reliabilityScore ?? '—'}</Field>
            </dl>
          </Card>
        )}

        {u.role === 'snowWorker' && (
          <Card
            title="Activité déneigeur"
            actions={
              <Link to={`/verifications/${u._id}`} className="inline-flex items-center gap-1.5 text-sm font-bold text-glacier hover:underline">
                <ShieldCheck className="h-4 w-4" aria-hidden />
                Identité : {verif.label}
              </Link>
            }
          >
            <dl className="divide-y divide-line/60">
              <Field label="En ligne">{wp?.isAvailable ? <Badge tone="ok">Oui</Badge> : <Badge tone="neutral">Non</Badge>}</Field>
              <Field label="Travaux terminés">{wp?.totalJobsCompleted ?? 0}</Field>
              <Field label="Gains">{formatMoney(wp?.totalEarnings)}</Field>
              <Field label="Pourboires">{formatMoney(wp?.totalTipsReceived)}</Field>
              <Field label="Note moyenne">
                {wp?.averageRating ? `${formatRating(wp.averageRating)} / 5 (${wp.totalRatingsCount ?? 0} avis)` : '—'}
              </Field>
              <Field label="Absences / avertissements">
                {wp?.noShowCount ?? 0} / {wp?.warningCount ?? 0}
              </Field>
              <Field label="Équipement">{wp?.equipmentList?.length ? wp.equipmentList.map((e) => equipment[e] ?? e).join(', ') : '—'}</Field>
              <Field label="Compte Stripe Connect">{wp?.stripeConnectId ? <span className="font-mono text-xs">{wp.stripeConnectId}</span> : 'Non configuré'}</Field>
            </dl>
          </Card>
        )}
      </div>

      {u.role === 'snowWorker' && <WorkerJobs workerId={u._id} />}

      <SuspendDialog user={u} open={suspendOpen} onClose={() => setSuspendOpen(false)} />
    </>
  );
}
