import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Sparkles } from 'lucide-react';
import { Badge, Button, Card, ErrorState, Field, Input, Label, PageHeader, Select, Spinner, Textarea, useToast } from '../components/ui';
import { api } from '../lib/api';
import { formatDateTime, formatMoney, formatRelative, fullName } from '../lib/format';
import { disputeDecisions, disputeStatus, disputeType, penalties, priority } from '../lib/labels';
import type { Dispute } from '../types';
import { BackLink } from './UserDetailPage';

const OPEN_STATUSES = ['open', 'under_review', 'pending_response', 'appealed', 'escalated'];

function Photos({ photos }: { photos?: { url: string; description?: string }[] }) {
  if (!photos?.length) return <p className="text-slate-3">Aucune photo.</p>;
  return (
    <div className="grid grid-cols-3 gap-2">
      {photos.map((p) => (
        <a key={p.url} href={p.url} target="_blank" rel="noreferrer" className="block overflow-hidden rounded-lg border border-line">
          <img src={p.url} alt={p.description ?? 'Preuve'} className="aspect-square w-full object-cover" loading="lazy" />
        </a>
      ))}
    </div>
  );
}

function ResolveForm({ dispute }: { dispute: Dispute }) {
  const qc = useQueryClient();
  const toast = useToast();
  // Le serveur ne plafonne pas : on borne au montant encore remboursable.
  const maxRefund = Math.max(0, (dispute.reservation?.totalPrice ?? 0) - (dispute.reservation?.refundAmount ?? 0));
  const [decision, setDecision] = useState('');
  const [refundAmount, setRefundAmount] = useState('');
  const [workerPenalty, setWorkerPenalty] = useState('none');
  const [clientPenalty, setClientPenalty] = useState('none');
  const [notes, setNotes] = useState('');
  const needsAmount = decision === 'partial_refund';

  const mutation = useMutation({
    mutationFn: () =>
      api<{ message?: string }>(`/disputes/${dispute._id}/resolve`, {
        method: 'POST',
        body: {
          decision,
          refundAmount: decision === 'full_refund' ? maxRefund : needsAmount ? Number(refundAmount) : 0,
          workerPenalty,
          clientPenalty,
          notes,
        },
      }),
    onSuccess: (res) => {
      toast(res.message ?? 'Litige résolu');
      qc.invalidateQueries({ queryKey: ['dispute', dispute._id] });
      qc.invalidateQueries({ queryKey: ['disputes'] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Résolution refusée', 'danger'),
  });

  const amountValid = Number(refundAmount) > 0 && Number(refundAmount) <= maxRefund + 0.001;
  const invalid = !decision || (needsAmount && !amountValid) || !notes.trim();

  return (
    <Card title="Trancher le litige">
      <div className="space-y-4">
        <div>
          <Label htmlFor="decision">Décision</Label>
          <Select id="decision" value={decision} onChange={(e) => setDecision(e.target.value)}>
            <option value="">Choisir…</option>
            {Object.entries(disputeDecisions).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </Select>
        </div>
        {needsAmount && (
          <div>
            <Label htmlFor="refund">
              Montant remboursé (réclamé : {formatMoney(dispute.claimedAmount)}, max. {formatMoney(maxRefund)})
            </Label>
            <Input id="refund" type="number" min="0.01" max={maxRefund} step="0.01" value={refundAmount} onChange={(e) => setRefundAmount(e.target.value)} />
          </div>
        )}
        {decision === 'full_refund' && <p className="rounded-lg bg-ice px-3 py-2 text-slate-2">Remboursement complet : {formatMoney(maxRefund)}</p>}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <Label htmlFor="wp">Sanction déneigeur</Label>
            <Select id="wp" value={workerPenalty} onChange={(e) => setWorkerPenalty(e.target.value)}>
              {Object.entries(penalties).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </Select>
          </div>
          <div>
            <Label htmlFor="cp">Sanction client</Label>
            <Select id="cp" value={clientPenalty} onChange={(e) => setClientPenalty(e.target.value)}>
              {Object.entries(penalties).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </Select>
          </div>
        </div>
        <div>
          <Label htmlFor="notes">Motivation (envoyée aux deux parties)</Label>
          <Textarea id="notes" value={notes} onChange={(e) => setNotes(e.target.value)} />
        </div>
        <Button variant="accent" className="w-full" loading={mutation.isPending} disabled={invalid} onClick={() => mutation.mutate()}>
          Rendre la décision
        </Button>
      </div>
    </Card>
  );
}

function AdminNotes({ dispute }: { dispute: Dispute }) {
  const qc = useQueryClient();
  const toast = useToast();
  const [note, setNote] = useState('');
  const mutation = useMutation({
    mutationFn: () => api(`/disputes/${dispute._id}/admin-note`, { method: 'POST', body: { note } }),
    onSuccess: () => {
      setNote('');
      qc.invalidateQueries({ queryKey: ['dispute', dispute._id] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Note non enregistrée', 'danger'),
  });
  return (
    <Card title="Notes internes">
      <ul className="mb-4 space-y-3">
        {(dispute.adminNotes ?? []).map((n, i) => (
          <li key={i} className="rounded-lg bg-ice px-3 py-2">
            <p>{n.note}</p>
            <p className="mt-1 text-xs text-slate-3">
              {fullName(n.addedBy)} · {formatRelative(n.addedAt)}
            </p>
          </li>
        ))}
        {!dispute.adminNotes?.length && <li className="text-slate-3">Aucune note pour l’instant.</li>}
      </ul>
      <Textarea value={note} onChange={(e) => setNote(e.target.value)} placeholder="Visible par les administrateurs seulement" aria-label="Nouvelle note" />
      <Button className="mt-2" disabled={!note.trim()} loading={mutation.isPending} onClick={() => mutation.mutate()}>
        Ajouter la note
      </Button>
    </Card>
  );
}

export function DisputeDetailPage() {
  const { id = '' } = useParams();
  const query = useQuery({
    queryKey: ['dispute', id],
    queryFn: () => api<{ dispute: Dispute }>(`/disputes/${id}`),
  });

  if (query.isLoading) return <Spinner />;
  if (query.error || !query.data) return <ErrorState error={query.error} onRetry={() => query.refetch()} />;

  const d = query.data.dispute;
  const s = disputeStatus(d.status);
  const p = priority(d.priority);
  const ai = d.aiAnalysis;
  const isOpen = OPEN_STATUSES.includes(d.status);

  return (
    <>
      <PageHeader
        back={<BackLink to="/disputes" label="Litiges" />}
        title={disputeType[d.type] ?? d.type}
        subtitle={
          <span className="flex flex-wrap items-center gap-2">
            <Badge tone={s.tone}>{s.label}</Badge>
            <Badge tone={p.tone}>Priorité {p.label.toLowerCase()}</Badge>
            <span className="text-slate-2">Ouvert le {formatDateTime(d.createdAt)}</span>
          </span>
        }
      />

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card title="Plainte">
            <dl className="mb-4 divide-y divide-line/60">
              <Field label="Plaignant">
                {d.claimant?.user ? <Link className="text-glacier hover:underline" to={`/users/${d.claimant.user._id}`}>{fullName(d.claimant.user)}</Link> : '—'}
                <span className="ml-1 text-slate-3">({d.claimant?.role === 'worker' ? 'déneigeur' : 'client'})</span>
              </Field>
              <Field label="Défendeur">
                {d.respondent?.user ? <Link className="text-glacier hover:underline" to={`/users/${d.respondent.user._id}`}>{fullName(d.respondent.user)}</Link> : '—'}
              </Field>
              <Field label="Montant réclamé">{formatMoney(d.claimedAmount)}</Field>
              <Field label="Réservation">
                {d.reservation ? <Link className="text-glacier hover:underline" to={`/reservations/${d.reservation._id}`}>{formatMoney(d.reservation.totalPrice)} · {formatDateTime(d.reservation.departureTime)}</Link> : '—'}
              </Field>
            </dl>
            <p className="whitespace-pre-line rounded-lg bg-ice px-4 py-3">{d.description || 'Aucune description.'}</p>
            <h3 className="mb-2 mt-5 font-extrabold">Preuves du plaignant</h3>
            <Photos photos={d.evidence?.photos} />
          </Card>

          <Card title="Réponse du défendeur">
            {d.response?.text ? (
              <>
                <p className="whitespace-pre-line rounded-lg bg-ice px-4 py-3">{d.response.text}</p>
                <p className="mb-4 mt-1 text-xs text-slate-3">Envoyée le {formatDateTime(d.response.submittedAt)}</p>
              </>
            ) : (
              <p className="mb-4 text-slate-3">
                Pas encore de réponse{d.deadlines?.responseDeadline ? ` (échéance : ${formatDateTime(d.deadlines.responseDeadline)})` : ''}.
              </p>
            )}
            {/* Le defendeur peut envoyer des photos avant d'ecrire sa reponse */}
            {(d.response?.photos?.length ?? 0) > 0 && <Photos photos={d.response?.photos} />}
          </Card>

          {d.resolution?.decision && (
            <Card title="Décision rendue">
              <dl className="divide-y divide-line/60">
                <Field label="Décision">{disputeDecisions[d.resolution.decision] ?? d.resolution.decision}</Field>
                <Field label="Remboursé">{formatMoney(d.resolution.refundAmount)}</Field>
                <Field label="Sanctions">
                  Déneigeur : {penalties[d.resolution.workerPenalty ?? 'none']} · Client : {penalties[d.resolution.clientPenalty ?? 'none']}
                </Field>
                <Field label="Par">{fullName(d.resolution.resolvedBy)} · {formatDateTime(d.resolution.resolvedAt)}</Field>
              </dl>
              {d.resolution.notes && <p className="mt-3 whitespace-pre-line rounded-lg bg-ice px-4 py-3">{d.resolution.notes}</p>}
            </Card>
          )}
        </div>

        <div className="space-y-6">
          {ai?.recommendedDecision && (
            <Card title={<span className="flex items-center gap-2"><Sparkles className="h-4 w-4 text-glacier" aria-hidden />Analyse IA</span>}>
              <p className="font-bold">{disputeDecisions[ai.recommendedDecision] ?? ai.recommendedDecision}</p>
              {ai.confidence !== undefined && <p className="tabular text-slate-2">Confiance : {Math.round(ai.confidence * (ai.confidence <= 1 ? 100 : 1))} %</p>}
              {ai.suggestedRefundPercent ? <p className="tabular text-slate-2">Remboursement suggéré : {ai.suggestedRefundPercent} %</p> : null}
              {ai.reasoning && <p className="mt-3 text-slate-2">{ai.reasoning}</p>}
              <p className="mt-3 text-xs text-slate-3">Recommandation indicative : la décision reste la vôtre.</p>
            </Card>
          )}
          {isOpen && <ResolveForm dispute={d} />}
          <AdminNotes dispute={d} />
        </div>
      </div>
    </>
  );
}
