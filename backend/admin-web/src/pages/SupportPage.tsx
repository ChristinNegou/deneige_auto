import { useState } from 'react';
import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import clsx from 'clsx';
import { LifeBuoy, Send } from 'lucide-react';
import { Badge, Button, Card, EmptyState, ErrorState, Label, PageHeader, Pager, Select, Spinner, Textarea, useToast } from '../components/ui';
import { api } from '../lib/api';
import { formatDateTime, formatRelative } from '../lib/format';
import { supportStatus, supportSubject } from '../lib/labels';
import { useListParams } from '../lib/useListParams';
import type { SupportRequest } from '../types';

function TicketPanel({ ticket }: { ticket: SupportRequest }) {
  const qc = useQueryClient();
  const toast = useToast();
  const [reply, setReply] = useState('');
  const [sendEmail, setSendEmail] = useState(true);
  const [status, setStatus] = useState(ticket.status);
  const [notes, setNotes] = useState(ticket.adminNotes ?? '');

  const refresh = () => qc.invalidateQueries({ queryKey: ['support'] });

  const respond = useMutation({
    mutationFn: () =>
      api<{ message?: string }>(`/support/requests/${ticket._id}/respond`, {
        method: 'POST',
        body: { message: reply, sendEmail, sendNotification: true },
      }),
    onSuccess: (res) => {
      toast(res.message ?? 'Réponse envoyée');
      setReply('');
      refresh();
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Réponse non envoyée', 'danger'),
  });

  const update = useMutation({
    mutationFn: () =>
      api(`/support/requests/${ticket._id}`, { method: 'PUT', body: { status, adminNotes: notes } }),
    onSuccess: () => {
      toast('Ticket mis à jour');
      refresh();
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Mise à jour refusée', 'danger'),
  });

  const s = supportStatus(ticket.status);

  return (
    <Card title={supportSubject[ticket.subject] ?? ticket.subject} actions={<Badge tone={s.tone}>{s.label}</Badge>}>
      <p className="text-slate-2">
        {ticket.userName || 'Utilisateur'} · {ticket.userEmail ?? '—'}
      </p>
      <p className="mb-4 text-xs text-slate-3">Reçu le {formatDateTime(ticket.createdAt)}</p>
      <p className="whitespace-pre-line rounded-lg bg-ice px-4 py-3">{ticket.message}</p>

      {!!ticket.responses?.length && (
        <div className="mt-4 space-y-2">
          {ticket.responses.map((r, i) => (
            <div key={i} className="rounded-lg border border-line/70 px-4 py-3">
              <p className="text-xs text-slate-3">Réponse envoyée le {formatDateTime(r.sentAt)}</p>
              <p className="mt-1 whitespace-pre-line">{r.message}</p>
            </div>
          ))}
        </div>
      )}

      <div className="mt-5">
        <Label htmlFor="reply">Répondre à l’utilisateur</Label>
        <Textarea id="reply" value={reply} onChange={(e) => setReply(e.target.value)} placeholder="Votre réponse…" />
        <div className="mt-2 flex items-center justify-between gap-3">
          <label className="flex items-center gap-2 text-slate-2">
            <input type="checkbox" checked={sendEmail} onChange={(e) => setSendEmail(e.target.checked)} className="h-4 w-4 accent-ink" />
            Envoyer aussi par courriel
          </label>
          <Button variant="accent" icon={<Send className="h-4 w-4" />} disabled={!reply.trim()} loading={respond.isPending} onClick={() => respond.mutate()}>
            Envoyer la réponse
          </Button>
        </div>
      </div>

      <div className="mt-6 space-y-3 border-t border-line/70 pt-5">
        <div>
          <Label htmlFor="ticket-status">Statut</Label>
          <Select id="ticket-status" value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="pending">Nouveau</option>
            <option value="in_progress">En cours</option>
            <option value="resolved">Résolu</option>
            <option value="closed">Fermé</option>
          </Select>
        </div>
        <div>
          <Label htmlFor="ticket-notes">Notes internes</Label>
          <Textarea id="ticket-notes" value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Visible par les administrateurs seulement" />
        </div>
        <Button loading={update.isPending} disabled={status === ticket.status && notes === (ticket.adminNotes ?? '')} onClick={() => update.mutate()}>
          Enregistrer
        </Button>
      </div>
    </Card>
  );
}

export function SupportPage() {
  const { values, page, set } = useListParams(['status'] as const);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const query = useQuery({
    queryKey: ['support', values, page],
    queryFn: () =>
      api<{ requests: SupportRequest[]; total: number; totalPages: number }>('/support/requests', {
        query: { page, limit: 20, status: values.status },
      }),
    placeholderData: keepPreviousData,
  });

  const tickets = query.data?.requests ?? [];
  const selected = tickets.find((t) => t._id === selectedId) ?? null;

  return (
    <>
      <PageHeader title="Support" subtitle="Demandes envoyées depuis l’application." />
      <div className="grid gap-6 lg:grid-cols-5">
        <Card padded={false} className="lg:col-span-2">
          <div className="border-b border-line/70 px-5 py-3">
            <Select value={values.status} onChange={(e) => set('status', e.target.value)} aria-label="Statut">
              <option value="">Tous les tickets</option>
              <option value="pending">Nouveaux</option>
              <option value="in_progress">En cours</option>
              <option value="resolved">Résolus</option>
              <option value="closed">Fermés</option>
            </Select>
          </div>
          {query.isLoading ? (
            <Spinner />
          ) : query.error ? (
            <ErrorState error={query.error} onRetry={() => query.refetch()} />
          ) : tickets.length ? (
            <>
              <ul className="divide-y divide-line/60">
                {tickets.map((t) => {
                  const s = supportStatus(t.status);
                  return (
                    <li key={t._id}>
                      <button
                        onClick={() => setSelectedId(t._id)}
                        aria-current={t._id === selectedId}
                        className={clsx('block w-full px-5 py-3 text-left hover:bg-ice/70', t._id === selectedId && 'bg-ice')}
                      >
                        <span className="flex items-center justify-between gap-3">
                          <span className="truncate font-bold">{supportSubject[t.subject] ?? t.subject}</span>
                          <Badge tone={s.tone}>{s.label}</Badge>
                        </span>
                        <span className="mt-0.5 block truncate text-xs text-slate-2">
                          {t.userName || t.userEmail} · {formatRelative(t.createdAt)}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
              <Pager page={page} pages={query.data?.totalPages ?? 1} total={query.data?.total ?? 0} onPage={(p) => set('page', p)} />
            </>
          ) : (
            <EmptyState icon={<LifeBuoy className="h-5 w-5" />} title="Aucun ticket" hint="Les demandes de support envoyées depuis l’application apparaîtront ici." />
          )}
        </Card>

        <div className="lg:col-span-3">
          {selected ? (
            <TicketPanel key={selected._id + selected.status + (selected.adminNotes ?? '')} ticket={selected} />
          ) : (
            <Card>
              <EmptyState icon={<LifeBuoy className="h-5 w-5" />} title="Sélectionnez un ticket" hint="Choisissez une demande dans la liste pour la lire et y répondre." />
            </Card>
          )}
        </div>
      </div>
    </>
  );
}
