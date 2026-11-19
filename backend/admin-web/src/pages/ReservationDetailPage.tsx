import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { RotateCcw } from 'lucide-react';
import { Badge, Button, Card, ErrorState, Field, Input, Label, Modal, PageHeader, Spinner, Textarea, useToast } from '../components/ui';
import { api } from '../lib/api';
import { formatDateTime, formatMoney, fullName } from '../lib/format';
import { paymentStatus, payoutStatus, reservationStatus, serviceOptions } from '../lib/labels';
import type { Reservation } from '../types';
import { BackLink } from './UserDetailPage';

const refundable = (r: Reservation) => Math.max(0, r.totalPrice - (r.refundAmount ?? 0));

function RefundDialog({ reservation, open, onClose }: { reservation: Reservation; open: boolean; onClose: () => void }) {
  const qc = useQueryClient();
  const toast = useToast();
  const max = refundable(reservation);
  const [amount, setAmount] = useState(max.toFixed(2));
  const [reason, setReason] = useState('');
  const value = Number(amount);
  const invalid = !(value > 0) || value > max + 0.001 || !reason.trim();

  const mutation = useMutation({
    mutationFn: () =>
      api<{ message: string }>(`/admin/reservations/${reservation._id}/refund`, {
        method: 'POST',
        body: { amount: value, reason },
      }),
    onSuccess: (res) => {
      toast(res.message);
      qc.invalidateQueries({ queryKey: ['reservation', reservation._id] });
      qc.invalidateQueries({ queryKey: ['reservations'] });
      onClose();
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Remboursement refusé', 'danger'),
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Rembourser le client"
      footer={
        <>
          <Button onClick={onClose}>Annuler</Button>
          <Button variant="accent" loading={mutation.isPending} disabled={invalid} onClick={() => mutation.mutate()}>
            Rembourser {value > 0 ? formatMoney(value) : ''}
          </Button>
        </>
      }
    >
      <p className="text-slate-2">
        Le remboursement est envoyé par Stripe sur la carte du client. Il est <strong className="text-ink">irréversible</strong>.
      </p>
      {reservation.workerId && (
        <p className="text-slate-2">
          Le déneigeur perd sa part de ce montant (75 %) :{' '}
          <strong className="tabular text-ink">{formatMoney(Math.round((value > 0 ? value : 0) * 75) / 100)}</strong>
          {' '}repris sur son versement.
        </p>
      )}
      <div>
        <Label htmlFor="amount">Montant (max. {formatMoney(max)})</Label>
        <Input id="amount" type="number" min="0.01" max={max} step="0.01" value={amount} onChange={(e) => setAmount(e.target.value)} className="tabular" />
        <div className="mt-2 flex gap-2">
          <Button variant="ghost" className="h-7 px-2 text-xs" onClick={() => setAmount((max / 2).toFixed(2))}>
            50 %
          </Button>
          <Button variant="ghost" className="h-7 px-2 text-xs" onClick={() => setAmount(max.toFixed(2))}>
            Totalité
          </Button>
        </div>
      </div>
      <div>
        <Label htmlFor="refund-reason">Raison (pour le suivi interne)</Label>
        <Textarea id="refund-reason" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Ex. : travail incomplet confirmé par les photos" />
      </div>
    </Modal>
  );
}

export function ReservationDetailPage() {
  const { id = '' } = useParams();
  const [refundOpen, setRefundOpen] = useState(false);
  const query = useQuery({
    queryKey: ['reservation', id],
    queryFn: () => api<{ reservation: Reservation }>(`/admin/reservations/${id}`),
  });

  if (query.isLoading) return <Spinner />;
  if (query.error || !query.data) return <ErrorState error={query.error} onRetry={() => query.refetch()} />;

  const r = query.data.reservation;
  const status = reservationStatus(r.status);
  const pay = paymentStatus(r.paymentStatus);
  const canRefund = ['paid', 'partially_refunded'].includes(r.paymentStatus ?? '') && refundable(r) > 0;

  const timeline: [string, string | null | undefined][] = [
    ['Créée', r.createdAt],
    ['Assignée', r.assignedAt],
    ['Commencée', r.startedAt],
    ['Terminée', r.completedAt],
    ['Annulée', r.cancelledAt],
    ['Remboursée', r.refundedAt],
  ];

  return (
    <>
      <PageHeader
        back={<BackLink to="/reservations" label="Réservations" />}
        title={`Réservation du ${formatDateTime(r.departureTime)}`}
        subtitle={
          <span className="flex flex-wrap gap-2">
            <Badge tone={status.tone}>{status.label}</Badge>
            <Badge tone={pay.tone}>{pay.label}</Badge>
            {r.dispute?.hasDispute && <Badge tone="danger">Litige ouvert</Badge>}
          </span>
        }
        actions={
          canRefund && (
            <Button variant="secondary" icon={<RotateCcw className="h-4 w-4" />} onClick={() => setRefundOpen(true)}>
              Rembourser
            </Button>
          )
        }
      />

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card title="Service">
            <dl className="divide-y divide-line/60">
              <Field label="Adresse">{r.location?.address ?? '—'}</Field>
              <Field label="Place">{r.parkingSpotNumber || '—'}</Field>
              <Field label="Véhicule">
                {[r.vehicle?.make, r.vehicle?.model, r.vehicle?.color].filter(Boolean).join(' · ') || '—'}
                {r.vehicle?.licensePlate && <span className="ml-2 rounded border border-ink px-1.5 text-xs font-extrabold">{r.vehicle.licensePlate}</span>}
              </Field>
              <Field label="Options">{r.serviceOptions?.length ? r.serviceOptions.map((o) => serviceOptions[o] ?? o).join(', ') : 'Aucune'}</Field>
              <Field label="Neige">{r.snowDepthCm ? `${r.snowDepthCm} cm` : '—'}</Field>
              <Field label="Échéance">{formatDateTime(r.deadlineTime)}</Field>
              {r.cancelReason && <Field label="Raison d’annulation">{r.cancelReason}</Field>}
            </dl>
          </Card>

          <Card title="Paiement et versement">
            <dl className="divide-y divide-line/60">
              <Field label="Prix total">{formatMoney(r.totalPrice)}</Field>
              <Field label="Déjà remboursé">{formatMoney(r.refundAmount)}</Field>
              <Field label="Pourboire">{formatMoney(r.tipAmount)}</Field>
              <Field label="Part déneigeur">{formatMoney(r.payout?.workerAmount)}</Field>
              <Field label="Frais plateforme / Stripe">
                {formatMoney(r.payout?.platformFee)} / {formatMoney(r.payout?.stripeFee)}
              </Field>
              <Field label="Versement">{r.payout?.status ? payoutStatus[r.payout.status] ?? r.payout.status : '—'}</Field>
              {r.payout?.error && <Field label="Erreur de versement"><span className="text-danger">{r.payout.error}</span></Field>}
              <Field label="Paiement Stripe">{r.paymentIntentId ? <span className="font-mono text-xs">{r.paymentIntentId}</span> : '—'}</Field>
            </dl>
          </Card>
        </div>

        <div className="space-y-6">
          <Card title="Personnes">
            <dl className="divide-y divide-line/60">
              <Field label="Client">
                {r.userId ? <Link className="text-glacier hover:underline" to={`/users/${r.userId._id}`}>{fullName(r.userId)}</Link> : '—'}
              </Field>
              <Field label="Déneigeur">
                {r.workerId ? <Link className="text-glacier hover:underline" to={`/users/${r.workerId._id}`}>{fullName(r.workerId)}</Link> : 'Non assigné'}
              </Field>
              <Field label="Note du client">{r.rating ? `${r.rating} / 5` : '—'}</Field>
            </dl>
          </Card>

          <Card title="Historique">
            <ol className="space-y-3">
              {timeline
                .filter(([, date]) => date)
                .map(([label, date]) => (
                  <li key={label} className="flex items-center gap-3">
                    <span className="h-2 w-2 rounded-full bg-ink" aria-hidden />
                    <span className="flex-1 font-semibold">{label}</span>
                    <span className="tabular text-slate-2">{formatDateTime(date)}</span>
                  </li>
                ))}
            </ol>
          </Card>
        </div>
      </div>

      {canRefund && <RefundDialog key={r.refundAmount} reservation={r} open={refundOpen} onClose={() => setRefundOpen(false)} />}
    </>
  );
}
