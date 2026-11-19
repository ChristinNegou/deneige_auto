import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Check, ImageOff, RefreshCw, Sparkles, X } from 'lucide-react';
import { Badge, Button, Card, ErrorState, Field, Label, Modal, PageHeader, Spinner, Textarea, useToast } from '../components/ui';
import { api } from '../lib/api';
import { formatDate, formatDateTime } from '../lib/format';
import { verificationStatus } from '../lib/labels';
import type { VerificationDetail } from '../types';
import { BackLink } from './UserDetailPage';

const DOCS = [
  ['idFront', 'Pièce d’identité (recto)'],
  ['idBack', 'Pièce d’identité (verso)'],
  ['selfie', 'Selfie'],
] as const;

function DocumentImage({ url, label }: { url?: string; label: string }) {
  return (
    <figure>
      <figcaption className="mb-2 text-xs font-bold text-slate-2">{label}</figcaption>
      {url ? (
        <a href={url} target="_blank" rel="noreferrer" className="block overflow-hidden rounded-xl border border-line bg-ice">
          <img src={url} alt={label} className="aspect-[4/3] w-full object-contain" />
        </a>
      ) : (
        <div className="flex aspect-[4/3] items-center justify-center rounded-xl border border-dashed border-line text-slate-3">
          <ImageOff className="h-5 w-5" aria-hidden />
        </div>
      )}
    </figure>
  );
}

export function VerificationDetailPage() {
  const { id = '' } = useParams();
  const qc = useQueryClient();
  const toast = useToast();
  const [rejectOpen, setRejectOpen] = useState(false);
  const [reason, setReason] = useState('');
  const [notes, setNotes] = useState('');

  const query = useQuery({
    queryKey: ['verification', id],
    queryFn: () => api<{ data: VerificationDetail }>(`/admin/verifications/${id}`),
  });

  const decide = useMutation({
    mutationFn: (decision: 'approved' | 'rejected') =>
      api<{ message: string }>(`/admin/verifications/${id}/decision`, {
        method: 'POST',
        body: { decision, reason: decision === 'rejected' ? reason : undefined, notes: notes || undefined },
      }),
    onSuccess: (res) => {
      toast(res.message);
      setRejectOpen(false);
      qc.invalidateQueries({ queryKey: ['verification', id] });
      qc.invalidateQueries({ queryKey: ['verifications'] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Décision refusée', 'danger'),
  });

  // Relance l'analyse IA (ex. apres avoir configure la cle Claude)
  const reanalyze = useMutation({
    mutationFn: () => api<{ message: string }>(`/admin/verifications/${id}/reanalyze`, { method: 'POST' }),
    onSuccess: (res) => {
      toast(res.message);
      qc.invalidateQueries({ queryKey: ['verification', id] });
      qc.invalidateQueries({ queryKey: ['verifications'] });
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Analyse impossible', 'danger'),
  });

  if (query.isLoading) return <Spinner />;
  if (query.error || !query.data) return <ErrorState error={query.error} onRetry={() => query.refetch()} />;

  const { user, verification: v } = query.data.data;
  const s = verificationStatus(v.status);
  const ai = v.aiAnalysis;
  const pending = v.status === 'pending';

  return (
    <>
      <PageHeader
        back={<BackLink to="/verifications?status=pending" label="Vérifications" />}
        title={user.name}
        subtitle={
          <span className="flex flex-wrap items-center gap-2">
            <Badge tone={s.tone}>{s.label}</Badge>
            <span className="text-slate-2">
              {user.email} · <Link className="text-glacier hover:underline" to={`/users/${user.id}`}>Voir le compte</Link>
            </span>
          </span>
        }
        actions={
          pending && (
            <>
              <Button icon={<RefreshCw className="h-4 w-4" />} loading={reanalyze.isPending} onClick={() => reanalyze.mutate()}>
                Relancer l’analyse IA
              </Button>
              <Button variant="danger" icon={<X className="h-4 w-4" />} onClick={() => setRejectOpen(true)}>
                Refuser
              </Button>
              <Button variant="primary" icon={<Check className="h-4 w-4" />} loading={decide.isPending && !rejectOpen} onClick={() => decide.mutate('approved')}>
                Approuver
              </Button>
            </>
          )
        }
      />

      <Card title="Documents" className="mb-6">
        <div className="grid gap-4 md:grid-cols-3">
          {DOCS.map(([key, label]) => (
            <DocumentImage key={key} url={v.documents?.[key]?.url} label={label} />
          ))}
        </div>
        <p className="mt-3 text-xs text-slate-3">Cliquez sur une image pour l’ouvrir en grand. Comparez le visage du selfie à la photo de la pièce.</p>
      </Card>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card title={<span className="flex items-center gap-2"><Sparkles className="h-4 w-4 text-glacier" aria-hidden />Analyse automatique</span>}>
          {ai && (ai.confidence !== undefined || ai.issues?.length || ai.recommendation) ? (
            <dl className="divide-y divide-line/60">
              {ai.recommendation && <Field label="Recommandation">{ai.recommendation}</Field>}
              {ai.confidence !== undefined && <Field label="Confiance">{Math.round(ai.confidence * (ai.confidence <= 1 ? 100 : 1))} %</Field>}
              {ai.faceMatch?.score !== undefined && <Field label="Correspondance du visage">{Math.round(ai.faceMatch.score * (ai.faceMatch.score <= 1 ? 100 : 1))} %</Field>}
              <Field label="Problèmes détectés">{ai.issues?.length ? ai.issues.join(', ') : 'Aucun'}</Field>
            </dl>
          ) : (
            <p className="text-slate-3">Pas d’analyse disponible pour ce dossier.</p>
          )}
        </Card>

        <Card title="Dossier">
          <dl className="divide-y divide-line/60">
            <Field label="Soumis le">{formatDateTime(v.submittedAt)}</Field>
            <Field label="Tentatives">{v.attemptsCount ?? 0}</Field>
            <Field label="Travaux terminés">{user.totalJobsCompleted ?? 0}</Field>
            <Field label="Inscrit le">{formatDate(user.createdAt)}</Field>
            {v.decision?.result && (
              <Field label="Dernière décision">
                {verificationStatus(v.decision.result).label} · {formatDateTime(v.decision.decidedAt)}
              </Field>
            )}
            {v.decision?.reason && <Field label="Raison">{v.decision.reason}</Field>}
            {v.expiresAt && <Field label="Expire le">{formatDate(v.expiresAt)}</Field>}
          </dl>
          {pending && (
            <div className="mt-4">
              <Label htmlFor="notes">Note interne (facultative)</Label>
              <Textarea id="notes" value={notes} onChange={(e) => setNotes(e.target.value)} />
            </div>
          )}
        </Card>
      </div>

      <Modal
        open={rejectOpen}
        onClose={() => setRejectOpen(false)}
        title="Refuser la vérification"
        footer={
          <>
            <Button onClick={() => setRejectOpen(false)}>Annuler</Button>
            <Button variant="danger" disabled={!reason.trim()} loading={decide.isPending} onClick={() => decide.mutate('rejected')}>
              Refuser
            </Button>
          </>
        }
      >
        <p className="text-slate-2">Le déneigeur recevra cette raison et pourra soumettre de nouveaux documents.</p>
        <div>
          <Label htmlFor="reject-reason">Raison du refus</Label>
          <Textarea id="reject-reason" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Ex. : photo de la pièce floue, visage non visible" />
        </div>
      </Modal>
    </>
  );
}
