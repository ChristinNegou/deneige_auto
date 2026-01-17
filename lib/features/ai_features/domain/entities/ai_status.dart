/// Statut des services IA
class AIStatus {
  final bool photoAnalysisEnabled;
  final bool demandPredictionEnabled;
  final bool smartMatchingEnabled;
  final bool disputeAnalysisEnabled;
  final bool pricingEnabled;
  final String modelVersion;
  final DateTime lastUpdated;

  const AIStatus({
    required this.photoAnalysisEnabled,
    required this.demandPredictionEnabled,
    required this.smartMatchingEnabled,
    required this.disputeAnalysisEnabled,
    required this.pricingEnabled,
    required this.modelVersion,
    required this.lastUpdated,
  });

  factory AIStatus.fromJson(Map<String, dynamic> json) {
    return AIStatus(
      photoAnalysisEnabled: json['photoAnalysisEnabled'] as bool? ?? false,
      demandPredictionEnabled:
          json['demandPredictionEnabled'] as bool? ?? false,
      smartMatchingEnabled: json['smartMatchingEnabled'] as bool? ?? false,
      disputeAnalysisEnabled: json['disputeAnalysisEnabled'] as bool? ?? false,
      pricingEnabled: json['pricingEnabled'] as bool? ?? false,
      modelVersion: json['modelVersion'] as String? ?? '',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  /// Nombre de services actifs
  int get activeServicesCount {
    int count = 0;
    if (photoAnalysisEnabled) count++;
    if (demandPredictionEnabled) count++;
    if (smartMatchingEnabled) count++;
    if (disputeAnalysisEnabled) count++;
    if (pricingEnabled) count++;
    return count;
  }

  /// Tous les services sont actifs
  bool get allServicesActive => activeServicesCount == 5;

  /// Au moins un service est actif
  bool get hasActiveServices => activeServicesCount > 0;
}

/// Statistiques de matching
class MatchingStats {
  final int totalMatches;
  final int successfulMatches;
  final double averageScore;
  final double acceptanceRate;
  final DateTime periodStart;
  final DateTime periodEnd;

  const MatchingStats({
    required this.totalMatches,
    required this.successfulMatches,
    required this.averageScore,
    required this.acceptanceRate,
    required this.periodStart,
    required this.periodEnd,
  });

  factory MatchingStats.fromJson(Map<String, dynamic> json) {
    return MatchingStats(
      totalMatches: (json['totalMatches'] as num?)?.toInt() ?? 0,
      successfulMatches: (json['successfulMatches'] as num?)?.toInt() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0,
      acceptanceRate: (json['acceptanceRate'] as num?)?.toDouble() ?? 0,
      periodStart: json['periodStart'] != null
          ? DateTime.parse(json['periodStart'] as String)
          : DateTime.now().subtract(const Duration(days: 7)),
      periodEnd: json['periodEnd'] != null
          ? DateTime.parse(json['periodEnd'] as String)
          : DateTime.now(),
    );
  }

  /// Taux de succes
  double get successRate =>
      totalMatches > 0 ? successfulMatches / totalMatches : 0;
}

/// Precision des predictions
class PredictionAccuracy {
  final DateTime date;
  final String zone;
  final String predictedDemand;
  final int predictedCount;
  final int actualCount;
  final double accuracy;

  const PredictionAccuracy({
    required this.date,
    required this.zone,
    required this.predictedDemand,
    required this.predictedCount,
    required this.actualCount,
    required this.accuracy,
  });

  factory PredictionAccuracy.fromJson(Map<String, dynamic> json) {
    return PredictionAccuracy(
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      zone: json['zone'] as String? ?? '',
      predictedDemand: json['predictedDemand'] as String? ?? '',
      predictedCount: (json['predictedCount'] as num?)?.toInt() ?? 0,
      actualCount: (json['actualCount'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Label de precision
  String get accuracyLabel {
    if (accuracy >= 0.9) return 'Excellente';
    if (accuracy >= 0.75) return 'Bonne';
    if (accuracy >= 0.5) return 'Moyenne';
    if (accuracy >= 0.25) return 'Faible';
    return 'Mauvaise';
  }

  /// Ecart entre prediction et realite
  int get deviation => (predictedCount - actualCount).abs();
}
