/** Libelles et teintes des statuts, alignes sur les valeurs du serveur. */

export type Tone = 'neutral' | 'info' | 'ok' | 'warn' | 'danger' | 'progress' | 'route';

export interface Label {
  label: string;
  tone: Tone;
}

const pick = (map: Record<string, Label>, value?: string | null): Label =>
  (value && map[value]) || { label: value ?? '—', tone: 'neutral' };

export const roleLabel = (role?: string) =>
  pick(
    {
      client: { label: 'Client', tone: 'info' },
      snowWorker: { label: 'Déneigeur', tone: 'progress' },
      admin: { label: 'Admin', tone: 'neutral' },
    },
    role,
  );

export const reservationStatus = (status?: string) =>
  pick(
    {
      pending: { label: 'En attente', tone: 'warn' },
      assigned: { label: 'Assignée', tone: 'info' },
      enRoute: { label: 'En route', tone: 'route' },
      inProgress: { label: 'En cours', tone: 'progress' },
      completed: { label: 'Terminée', tone: 'ok' },
      cancelled: { label: 'Annulée', tone: 'neutral' },
    },
    status,
  );

export const paymentStatus = (status?: string) =>
  pick(
    {
      pending: { label: 'Non payé', tone: 'warn' },
      paid: { label: 'Payé', tone: 'ok' },
      refunded: { label: 'Remboursé', tone: 'neutral' },
      partially_refunded: { label: 'Remb. partiel', tone: 'info' },
      failed: { label: 'Échec', tone: 'danger' },
    },
    status,
  );

export const disputeStatus = (status?: string) =>
  pick(
    {
      open: { label: 'Ouvert', tone: 'warn' },
      under_review: { label: 'En examen', tone: 'info' },
      pending_response: { label: 'Attente réponse', tone: 'route' },
      resolved: { label: 'Résolu', tone: 'ok' },
      closed: { label: 'Fermé', tone: 'neutral' },
      appealed: { label: 'En appel', tone: 'progress' },
      escalated: { label: 'Escaladé', tone: 'danger' },
    },
    status,
  );

export const disputeType: Record<string, string> = {
  no_show: 'Déneigeur absent',
  incomplete_work: 'Travail incomplet',
  quality_issue: 'Qualité insuffisante',
  late_arrival: 'Retard',
  damage: 'Dommage',
  wrong_location: 'Mauvais endroit',
  overcharge: 'Surfacturation',
  unprofessional: 'Comportement',
  payment_issue: 'Paiement',
  other: 'Autre',
};

export const priority = (value?: string) =>
  pick(
    {
      low: { label: 'Basse', tone: 'neutral' },
      medium: { label: 'Moyenne', tone: 'info' },
      high: { label: 'Haute', tone: 'warn' },
      urgent: { label: 'Urgente', tone: 'danger' },
    },
    value,
  );

export const verificationStatus = (status?: string) =>
  pick(
    {
      not_submitted: { label: 'Non soumise', tone: 'neutral' },
      pending: { label: 'À examiner', tone: 'warn' },
      approved: { label: 'Approuvée', tone: 'ok' },
      rejected: { label: 'Refusée', tone: 'danger' },
      expired: { label: 'Expirée', tone: 'neutral' },
    },
    status,
  );

export const supportStatus = (status?: string) =>
  pick(
    {
      pending: { label: 'Nouveau', tone: 'warn' },
      in_progress: { label: 'En cours', tone: 'info' },
      resolved: { label: 'Résolu', tone: 'ok' },
      closed: { label: 'Fermé', tone: 'neutral' },
    },
    status,
  );

export const serviceOptions: Record<string, string> = {
  windowScraping: 'Grattage des vitres',
  doorDeicing: 'Dégivrage des portes',
  wheelClearance: 'Dégagement des roues',
};

export const equipment: Record<string, string> = {
  shovel: 'Pelle',
  brush: 'Brosse à neige',
  ice_scraper: 'Grattoir',
  salt_spreader: 'Épandeur de sel',
  snow_blower: 'Souffleuse',
  roof_broom: 'Balai de toit',
  microfiber_cloth: 'Chiffon microfibre',
  deicer_spray: 'Dégivrant',
};

export const supportSubject: Record<string, string> = {
  bug: 'Problème technique',
  question: 'Question',
  suggestion: 'Suggestion',
  other: 'Autre demande',
};

export const payoutStatus: Record<string, string> = {
  pending: 'En attente',
  pending_account: 'Compte Stripe manquant',
  pending_payment: 'Paiement en attente',
  processing: 'En cours',
  completed: 'Versé',
  paid: 'Versé',
  failed: 'Échec',
};

export const disputeDecisions: Record<string, string> = {
  favor_claimant: 'En faveur du plaignant',
  favor_respondent: 'En faveur du défendeur',
  partial_refund: 'Remboursement partiel',
  full_refund: 'Remboursement complet',
  no_action: 'Aucune action',
};

export const penalties: Record<string, string> = {
  none: 'Aucune',
  warning: 'Avertissement',
  suspension_3days: 'Suspension 3 jours',
  suspension_7days: 'Suspension 7 jours',
  suspension_30days: 'Suspension 30 jours',
  permanent_ban: 'Bannissement',
};
