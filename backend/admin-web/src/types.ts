/** Types des reponses de l'API admin (champs utilises par le site seulement). */

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  pages?: number;
  totalPages?: number;
}

export interface PersonRef {
  _id: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  phoneNumber?: string;
}

export interface DashboardStats {
  users: { total: number; clients: number; workers: number; activeWorkers: number };
  reservations: {
    total: number;
    completed: number;
    cancelled: number;
    pending: number;
    today: number;
    thisMonth: number;
    completionRate: string;
  };
  revenue: {
    total: number;
    platformFeesNet: number;
    workerPayouts: number;
    tips: number;
    thisMonth: number;
    monthlyPlatformFeesNet: number;
  };
  charts: { dailyReservations: { _id: string; count: number; revenue: number }[] };
  topWorkers: { id: string; name: string; jobsCompleted: number; totalEarnings: number; rating: number }[];
  support: {
    total: number;
    pending: number;
    inProgress: number;
    resolved: number;
    todayNew: number;
    avgResponseTimeHours: number;
  };
}

export interface User {
  _id: string;
  email: string;
  firstName: string;
  lastName: string;
  phoneNumber?: string;
  phoneVerified?: boolean;
  role: 'client' | 'snowWorker' | 'admin';
  photoUrl?: string;
  isActive?: boolean;
  isSuspended?: boolean;
  suspendedUntil?: string | null;
  suspensionReason?: string | null;
  stripeCustomerId?: string | null;
  createdAt: string;
  clientProfile?: {
    totalReservations?: number;
    completedReservations?: number;
    totalSpent?: number;
    totalCancellations?: number;
    totalDisputes?: number;
    warningCount?: number;
    reliabilityScore?: number;
  };
  workerProfile?: {
    isAvailable?: boolean;
    isSuspended?: boolean;
    suspendedUntil?: string | null;
    equipmentList?: string[];
    totalJobsCompleted?: number;
    totalEarnings?: number;
    totalTipsReceived?: number;
    averageRating?: number;
    totalRatingsCount?: number;
    warningCount?: number;
    noShowCount?: number;
    reliabilityScore?: number;
    stripeConnectId?: string;
    identityVerification?: { status?: string };
  };
}

export interface Reservation {
  _id: string;
  status: string;
  paymentStatus?: string;
  paymentIntentId?: string;
  departureTime: string;
  deadlineTime?: string;
  createdAt: string;
  assignedAt?: string;
  startedAt?: string;
  completedAt?: string;
  cancelledAt?: string | null;
  cancelReason?: string | null;
  cancelledBy?: string | null;
  totalPrice: number;
  basePrice?: number;
  refundAmount?: number;
  refundedAt?: string | null;
  tipAmount?: number;
  rating?: number;
  serviceOptions?: string[];
  snowDepthCm?: number | null;
  parkingSpotNumber?: string;
  location?: { address?: string; coordinates?: number[] };
  userId?: PersonRef;
  workerId?: PersonRef | null;
  vehicle?: { make?: string; model?: string; color?: string; licensePlate?: string; year?: number };
  payout?: {
    status?: string;
    workerAmount?: number;
    platformFee?: number;
    stripeFee?: number;
    tipAmount?: number;
    error?: string | null;
  };
  dispute?: { hasDispute?: boolean };
}

export interface Verification {
  userId: string;
  name: string;
  email: string;
  photoUrl?: string;
  createdAt: string;
  verification: { status: string; submittedAt?: string; attemptsCount?: number };
}

export interface VerificationDetail {
  user: {
    id: string;
    name: string;
    email: string;
    photoUrl?: string;
    totalJobsCompleted?: number;
    averageRating?: number;
    createdAt: string;
  };
  verification: {
    status: string;
    documents?: Record<'idFront' | 'idBack' | 'selfie', { url?: string } | undefined>;
    aiAnalysis?: {
      confidence?: number;
      recommendation?: string;
      issues?: string[];
      extractedData?: Record<string, unknown>;
      faceMatch?: { score?: number; match?: boolean };
    };
    decision?: { result?: string; decidedAt?: string; reason?: string | null; adminNotes?: string | null };
    submittedAt?: string;
    verifiedAt?: string;
    expiresAt?: string;
    attemptsCount?: number;
  };
}

export interface DisputeParty {
  user?: PersonRef;
  role?: 'client' | 'worker';
}

export interface Dispute {
  _id: string;
  type: string;
  status: string;
  priority?: string;
  description?: string;
  claimedAmount?: number;
  createdAt: string;
  reservation?: Partial<Reservation> & { _id: string };
  claimant?: DisputeParty;
  respondent?: DisputeParty;
  evidence?: { photos?: { url: string; description?: string }[] };
  response?: { text?: string; submittedAt?: string; photos?: { url: string }[] };
  resolution?: {
    decision?: string;
    refundAmount?: number;
    workerPenalty?: string;
    clientPenalty?: string;
    notes?: string;
    resolvedAt?: string;
    resolvedBy?: PersonRef;
  };
  deadlines?: { responseDeadline?: string; resolutionDeadline?: string };
  adminNotes?: { note: string; addedAt?: string; addedBy?: PersonRef }[];
  aiAnalysis?: {
    recommendedDecision?: string;
    confidence?: number;
    reasoning?: string;
    suggestedRefundPercent?: number;
    riskFactors?: string[];
  };
}

export interface SupportRequest {
  _id: string;
  userId?: string;
  userEmail?: string;
  userName?: string;
  subject: string;
  message: string;
  status: string;
  adminNotes?: string;
  createdAt: string;
  resolvedAt?: string;
}

/* ---------- Phase 2 ---------- */

export interface RevenueRow {
  _id: string | number;
  totalRevenue: number;
  platformFees: number;
  workerPayouts: number;
  tips: number;
  count: number;
}

export interface Reconciliation {
  period: { start: string; end: string };
  localDatabase: {
    totalRevenue: number;
    platformFeesNet: number;
    workerPayouts: number;
    stripeFees: number;
    tips: number;
    reservationCount: number;
  };
  stripe: {
    balance?: { available: number; pending: number; currency: string };
    chargesTotal: number;
    chargesCount: number;
    transfersTotal: number;
    refundsTotal: number;
    feesTotal: number;
    error?: string | null;
  };
  discrepancies: Record<string, { local: number; stripe: number; difference: number; percentDiff?: string }>;
  problematicReservations: {
    id: string;
    totalPrice: number;
    status: string;
    paymentStatus: string;
    payoutStatus: string;
    createdAt: string;
  }[];
  recommendations: { type: string; message: string; action?: string }[];
}

export interface PayoutSummary {
  found: number;
  noAccount?: number;
  processed?: number;
  succeeded?: number;
  failed?: number;
  fixed?: number;
  // Les deux routes ne nomment pas leurs champs pareil (reservationId/amount ou id/workerAmount)
  details?: {
    reservationId?: string;
    id?: string;
    workerName?: string;
    amount?: number;
    workerAmount?: number;
    totalPrice?: number;
    hasStripeConnect?: boolean;
  }[];
}

export interface WorkerWarning {
  id: string;
  name: string;
  email: string;
  warningCount: number;
  isSuspended: boolean;
}

export interface ConnectAccount {
  stripeAccountId: string;
  email?: string | null;
  chargesEnabled: boolean;
  payoutsEnabled: boolean;
  detailsSubmitted: boolean;
  created?: string | null;
  country?: string | null;
  workerId?: string | null;
  workerName?: string | null;
  workerEmail?: string | null;
  isOrphan?: boolean;
  isInvalidOnStripe?: boolean;
}

export interface FcmStatus {
  stats: {
    total: number;
    withFcmToken: number;
    withoutFcmToken: number;
    byRole: Record<string, { total: number; withToken: number }>;
  };
}
