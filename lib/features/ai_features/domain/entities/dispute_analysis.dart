/// Analyse IA d'un litige
class DisputeAnalysis {
  final int evidenceStrength;
  final String recommendedDecision;
  final double confidence;
  final String? reasoning;
  final List<String> riskFactors;
  final int suggestedRefundPercent;
  final String? suggestedPenalty;
  final List<KeyFinding> keyFindings;
  final DateTime analyzedAt;
  final bool reviewedByAdmin;

  const DisputeAnalysis({
    required this.evidenceStrength,
    required this.recommendedDecision,
    required this.confidence,
    this.reasoning,
    required this.riskFactors,
    required this.suggestedRefundPercent,
    this.suggestedPenalty,
    required this.keyFindings,
    required this.analyzedAt,
    required this.reviewedByAdmin,
  });

  factory DisputeAnalysis.fromJson(Map<String, dynamic> json) {
    return DisputeAnalysis(
      evidenceStrength: (json['evidenceStrength'] as num?)?.toInt() ?? 0,
      recommendedDecision: json['recommendedDecision'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reasoning: json['reasoning'] as String?,
      riskFactors: (json['riskFactors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedRefundPercent:
          (json['suggestedRefundPercent'] as num?)?.toInt() ?? 0,
      suggestedPenalty: json['suggestedPenalty'] as String?,
      keyFindings: (json['keyFindings'] as List<dynamic>?)
              ?.map((e) => KeyFinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'] as String)
          : DateTime.now(),
      reviewedByAdmin: json['reviewedByAdmin'] as bool? ?? false,
    );
  }

  /// Couleur selon la force des preuves
  String get evidenceColor {
    if (evidenceStrength >= 80) return 'green';
    if (evidenceStrength >= 60) return 'yellow';
    if (evidenceStrength >= 40) return 'orange';
    return 'red';
  }

  /// Label de la force des preuves
  String get evidenceLabel {
    if (evidenceStrength >= 80) return 'Tres solides';
    if (evidenceStrength >= 60) return 'Solides';
    if (evidenceStrength >= 40) return 'Moyennes';
    if (evidenceStrength >= 20) return 'Faibles';
    return 'Insuffisantes';
  }

  /// Label du niveau de confiance
  String get confidenceLabel {
    if (confidence >= 0.9) return 'Tres haute';
    if (confidence >= 0.75) return 'Haute';
    if (confidence >= 0.5) return 'Moyenne';
    if (confidence >= 0.25) return 'Basse';
    return 'Tres basse';
  }

  /// Traduit la decision recommandee
  String get decisionLabel {
    switch (recommendedDecision.toLowerCase()) {
      case 'full_refund':
        return 'Remboursement complet';
      case 'partial_refund':
        return 'Remboursement partiel';
      case 'no_refund':
        return 'Pas de remboursement';
      case 'redo_service':
        return 'Refaire le service';
      case 'mediation':
        return 'Mediation requise';
      default:
        return recommendedDecision;
    }
  }

  /// Indicateurs favorables au client
  List<KeyFinding> get findingsForClient =>
      keyFindings.where((f) => f.impact == 'favorable_client').toList();

  /// Indicateurs favorables au worker
  List<KeyFinding> get findingsForWorker =>
      keyFindings.where((f) => f.impact == 'favorable_worker').toList();

  /// Indicateurs neutres
  List<KeyFinding> get neutralFindings =>
      keyFindings.where((f) => f.impact == 'neutral').toList();
}

class KeyFinding {
  final String category;
  final String finding;
  final String impact;

  const KeyFinding({
    required this.category,
    required this.finding,
    required this.impact,
  });

  factory KeyFinding.fromJson(Map<String, dynamic> json) {
    return KeyFinding(
      category: json['category'] as String? ?? '',
      finding: json['finding'] as String? ?? '',
      impact: json['impact'] as String? ?? 'neutral',
    );
  }

  /// Icone selon l'impact
  String get impactIcon {
    switch (impact) {
      case 'favorable_client':
        return '👤';
      case 'favorable_worker':
        return '🛠️';
      default:
        return '⚖️';
    }
  }

  /// Couleur selon l'impact
  String get impactColor {
    switch (impact) {
      case 'favorable_client':
        return 'blue';
      case 'favorable_worker':
        return 'green';
      default:
        return 'gray';
    }
  }

  /// Label de la categorie
  String get categoryLabel {
    switch (category.toLowerCase()) {
      case 'photos':
        return 'Photos';
      case 'gps':
        return 'GPS';
      case 'timing':
        return 'Delais';
      case 'history':
        return 'Historique';
      case 'communication':
        return 'Communication';
      default:
        return category;
    }
  }
}
