import 'package:equatable/equatable.dart';

enum IdentityVerificationState {
  notSubmitted,
  pending,
  approved,
  rejected,
  expired,
}

class VerificationStatus extends Equatable {
  final IdentityVerificationState status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final VerificationDecision? decision;
  final VerificationAiAnalysis? aiAnalysis;
  final bool canResubmit;
  final int attemptsRemaining;

  const VerificationStatus({
    required this.status,
    this.submittedAt,
    this.verifiedAt,
    this.expiresAt,
    this.decision,
    this.aiAnalysis,
    this.canResubmit = true,
    this.attemptsRemaining = 3,
  });

  bool get isVerified => status == IdentityVerificationState.approved;
  bool get isPending => status == IdentityVerificationState.pending;
  bool get isRejected => status == IdentityVerificationState.rejected;
  bool get needsVerification =>
      status == IdentityVerificationState.notSubmitted ||
      status == IdentityVerificationState.rejected ||
      status == IdentityVerificationState.expired;

  String get statusText {
    switch (status) {
      case IdentityVerificationState.notSubmitted:
        return 'Non soumis';
      case IdentityVerificationState.pending:
        return 'En cours de vérification';
      case IdentityVerificationState.approved:
        return 'Vérifié';
      case IdentityVerificationState.rejected:
        return 'Refusé';
      case IdentityVerificationState.expired:
        return 'Expiré';
    }
  }

  @override
  List<Object?> get props => [
        status,
        submittedAt,
        verifiedAt,
        expiresAt,
        decision,
        aiAnalysis,
        canResubmit,
        attemptsRemaining,
      ];
}

class VerificationDecision extends Equatable {
  final String result;
  final String? reason;
  final DateTime? decidedAt;

  const VerificationDecision({
    required this.result,
    this.reason,
    this.decidedAt,
  });

  @override
  List<Object?> get props => [result, reason, decidedAt];
}

class VerificationAiAnalysis extends Equatable {
  final int overallScore;
  final List<String> issues;

  const VerificationAiAnalysis({
    required this.overallScore,
    this.issues = const [],
  });

  @override
  List<Object?> get props => [overallScore, issues];
}
