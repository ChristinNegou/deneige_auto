import '../../domain/entities/verification_status.dart';

class VerificationStatusModel extends VerificationStatus {
  const VerificationStatusModel({
    required super.status,
    super.submittedAt,
    super.verifiedAt,
    super.expiresAt,
    super.decision,
    super.aiAnalysis,
    super.canResubmit,
    super.attemptsRemaining,
  });

  factory VerificationStatusModel.fromJson(Map<String, dynamic> json) {
    return VerificationStatusModel(
      status: _parseStatus(json['status'] as String?),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      decision: json['decision'] != null
          ? VerificationDecisionModel.fromJson(
              json['decision'] as Map<String, dynamic>)
          : null,
      aiAnalysis: json['aiAnalysis'] != null
          ? VerificationAiAnalysisModel.fromJson(
              json['aiAnalysis'] as Map<String, dynamic>)
          : null,
      canResubmit: json['canResubmit'] as bool? ?? true,
      attemptsRemaining: json['attemptsRemaining'] as int? ?? 3,
    );
  }

  static IdentityVerificationState _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return IdentityVerificationState.pending;
      case 'approved':
        return IdentityVerificationState.approved;
      case 'rejected':
        return IdentityVerificationState.rejected;
      case 'expired':
        return IdentityVerificationState.expired;
      default:
        return IdentityVerificationState.notSubmitted;
    }
  }
}

class VerificationDecisionModel extends VerificationDecision {
  const VerificationDecisionModel({
    required super.result,
    super.reason,
    super.decidedAt,
  });

  factory VerificationDecisionModel.fromJson(Map<String, dynamic> json) {
    return VerificationDecisionModel(
      result: json['result'] as String? ?? '',
      reason: json['reason'] as String?,
      decidedAt: json['decidedAt'] != null
          ? DateTime.parse(json['decidedAt'] as String)
          : null,
    );
  }
}

class VerificationAiAnalysisModel extends VerificationAiAnalysis {
  const VerificationAiAnalysisModel({
    required super.overallScore,
    super.issues,
  });

  factory VerificationAiAnalysisModel.fromJson(Map<String, dynamic> json) {
    return VerificationAiAnalysisModel(
      overallScore: json['overallScore'] as int? ?? 0,
      issues: json['issues'] != null
          ? List<String>.from(json['issues'] as List)
          : [],
    );
  }
}
