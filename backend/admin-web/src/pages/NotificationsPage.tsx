import { useState } from 'react';
import { useMutation, useQuery } from '@tanstack/react-query';
import { BellRing, Megaphone } from 'lucide-react';
import { Button, Card, Input, Label, Modal, PageHeader, Select, Textarea, useToast } from '../components/ui';
import { api } from '../lib/api';
import type { FcmStatus } from '../types';

const AUDIENCES: Record<string, string> = {
  '': 'Tous les utilisateurs',
  client: 'Clients seulement',
  snowWorker: 'Déneigeurs seulement',
};

const ROLE_LABELS: Record<string, string> = { client: 'Clients', snowWorker: 'Déneigeurs', admin: 'Administrateurs' };

function BroadcastCard({ stats }: { stats?: FcmStatus['stats'] }) {
  const toast = useToast();
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [targetRole, setTargetRole] = useState('');
  const [priority, setPriority] = useState('normal');
  const [confirming, setConfirming] = useState(false);

  const audienceSize = !stats ? null : targetRole ? stats.byRole[targetRole]?.total ?? 0 : stats.total;

  const send = useMutation({
    mutationFn: () =>
      api<{ message: string }>('/admin/notifications/broadcast', {
        method: 'POST',
        body: { title, message, priority, targetRole: targetRole || undefined },
      }),
    onSuccess: (res) => {
      toast(res.message);
      setConfirming(false);
      setTitle('');
      setMessage('');
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Envoi refusé', 'danger'),
  });

  return (
    <Card title="Envoyer une annonce" className="lg:col-span-3">
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <div>
            <Label htmlFor="audience">Destinataires</Label>
            <Select id="audience" value={targetRole} onChange={(e) => setTargetRole(e.target.value)}>
              {Object.entries(AUDIENCES).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </Select>
          </div>
          <div>
            <Label htmlFor="priority">Importance</Label>
            <Select id="priority" value={priority} onChange={(e) => setPriority(e.target.value)}>
              <option value="low">Faible</option>
              <option value="normal">Normale</option>
              <option value="high">Haute</option>
              <option value="urgent">Urgente</option>
            </Select>
          </div>
        </div>
        <div>
          <Label htmlFor="title">Titre</Label>
          <Input id="title" maxLength={80} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Ex. : Tempête prévue cette nuit" />
        </div>
        <div>
          <Label htmlFor="message">Message</Label>
          <Textarea id="message" maxLength={500} value={message} onChange={(e) => setMessage(e.target.value)} placeholder="Ce que les utilisateurs liront dans l’application." />
          <p className="tabular mt-1 text-right text-xs text-slate-3">{message.length} / 500</p>
        </div>
        <div className="flex items-center justify-between gap-3">
          <p className="text-slate-2">{audienceSize !== null && `${audienceSize} personne(s) recevront cette annonce.`}</p>
          <Button variant="accent" icon={<Megaphone className="h-4 w-4" />} disabled={!title.trim() || !message.trim()} onClick={() => setConfirming(true)}>
            Envoyer l’annonce
          </Button>
        </div>
      </div>

      <Modal
        open={confirming}
        onClose={() => setConfirming(false)}
        title="Confirmer l’envoi"
        footer={
          <>
            <Button onClick={() => setConfirming(false)}>Annuler</Button>
            <Button variant="accent" loading={send.isPending} onClick={() => send.mutate()}>
              Envoyer à {audienceSize ?? '…'} personne(s)
            </Button>
          </>
        }
      >
        <p className="text-slate-2">
          {AUDIENCES[targetRole]} recevront cette notification. Un envoi ne peut pas être annulé.
        </p>
        <div className="rounded-xl border border-line p-4">
          <p className="font-extrabold">{title}</p>
          <p className="mt-1 whitespace-pre-line text-slate-2">{message}</p>
        </div>
      </Modal>
    </Card>
  );
}

function TestPushCard() {
  const toast = useToast();
  const [email, setEmail] = useState('');
  const [result, setResult] = useState<string | null>(null);
  const test = useMutation({
    mutationFn: () =>
      api<{ message: string; user: { hasFcmToken: boolean }; firebase?: { status?: string } }>('/admin/notifications/test', {
        method: 'POST',
        body: { email: email.trim() },
      }),
    onSuccess: (res) => {
      setResult(
        res.user.hasFcmToken
          ? `${res.message}. Firebase : ${res.firebase?.status ?? 'inconnu'}.`
          : `${res.message}, mais cet appareil n’est pas inscrit aux notifications push : elle n’apparaîtra que dans l’application.`,
      );
    },
    onError: (e) => toast(e instanceof Error ? e.message : 'Test impossible', 'danger'),
  });

  return (
    <Card title="Tester une notification push">
      <p className="mb-3 text-slate-2">Envoie une notification de test à un seul compte, pour vérifier qu’elle arrive sur son téléphone.</p>
      <Label htmlFor="test-email">Courriel du compte</Label>
      <div className="flex gap-2">
        <Input id="test-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="nom@exemple.com" />
        <Button icon={<BellRing className="h-4 w-4" />} disabled={!email.includes('@')} loading={test.isPending} onClick={() => test.mutate()}>
          Tester
        </Button>
      </div>
      {result && <p className="mt-3 rounded-lg bg-ice px-3 py-2">{result}</p>}
    </Card>
  );
}

export function NotificationsPage() {
  const status = useQuery({
    queryKey: ['notifications', 'fcm-status'],
    queryFn: () => api<FcmStatus>('/admin/notifications/fcm-status'),
  });
  const stats = status.data?.stats;

  return (
    <>
      <PageHeader title="Notifications" subtitle="Annonces envoyées dans l’application et sur les téléphones." />
      <div className="grid gap-6 lg:grid-cols-5">
        <BroadcastCard stats={stats} />
        <div className="space-y-6 lg:col-span-2">
          <Card title="Téléphones joignables">
            {stats ? (
              <>
                <p className="tabular text-[26px] font-extrabold tracking-tight">
                  {stats.withFcmToken} <span className="text-base font-semibold text-slate-2">sur {stats.total} comptes</span>
                </p>
                <p className="mb-3 text-slate-2">reçoivent les notifications push. Les autres ne les voient que dans l’application.</p>
                <dl className="divide-y divide-line/60">
                  {Object.entries(stats.byRole).map(([role, r]) => (
                    <div key={role} className="flex justify-between py-2">
                      <dt className="text-slate-2">{ROLE_LABELS[role] ?? role}</dt>
                      <dd className="tabular font-bold">
                        {r.withToken} / {r.total}
                      </dd>
                    </div>
                  ))}
                </dl>
              </>
            ) : (
              <p className="text-slate-3">Chargement…</p>
            )}
          </Card>
          <TestPushCard />
        </div>
      </div>
    </>
  );
}
