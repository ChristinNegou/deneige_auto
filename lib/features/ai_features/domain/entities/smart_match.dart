/// Resultat du smart matching IA
class SmartMatchResult {
  final List<WorkerMatch> suggestedWorkers;
  final DateTime matchedAt;
  final String? reasoning;

  const SmartMatchResult({
    required this.suggestedWorkers,
    required this.matchedAt,
    this.reasoning,
  });

  factory SmartMatchResult.fromJson(Map<String, dynamic> json) {
    return SmartMatchResult(
      suggestedWorkers: (json['suggestedWorkers'] as List<dynamic>?)
              ?.map((e) => WorkerMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'] as String)
          : DateTime.now(),
      reasoning: json['reasoning'] as String?,
    );
  }

  bool get hasMatches => suggestedWorkers.isNotEmpty;
  WorkerMatch? get bestMatch =>
      suggestedWorkers.isNotEmpty ? suggestedWorkers.first : null;
}

class WorkerMatch {
  final String workerId;
  final String workerName;
  final double score;
  final int ranking;
  final MatchFactors factors;
  final String? reasoning;
  final double? distanceKm;
  final double? rating;

  const WorkerMatch({
    required this.workerId,
    required this.workerName,
    required this.score,
    required this.ranking,
    required this.factors,
    this.reasoning,
    this.distanceKm,
    this.rating,
  });

  factory WorkerMatch.fromJson(Map<String, dynamic> json) {
    return WorkerMatch(
      workerId: json['workerId'] as String? ?? '',
      workerName: json['workerName'] as String? ?? 'Inconnu',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      ranking: (json['ranking'] as num?)?.toInt() ?? 0,
      factors:
          MatchFactors.fromJson(json['factors'] as Map<String, dynamic>? ?? {}),
      reasoning: json['reasoning'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  String get scoreLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Tres bien';
    if (score >= 70) return 'Bien';
    if (score >= 60) return 'Acceptable';
    return 'Moyen';
  }
}

class MatchFactors {
  final FactorScore distance;
  final FactorScore availability;
  final FactorScore rating;
  final FactorScore equipment;
  final FactorScore experience;
  final FactorScore specialization;

  const MatchFactors({
    required this.distance,
    required this.availability,
    required this.rating,
    required this.equipment,
    required this.experience,
    required this.specialization,
  });

  factory MatchFactors.fromJson(Map<String, dynamic> json) {
    return MatchFactors(
      distance:
          FactorScore.fromJson(json['distance'] as Map<String, dynamic>? ?? {}),
      availability: FactorScore.fromJson(
          json['availability'] as Map<String, dynamic>? ?? {}),
      rating:
          FactorScore.fromJson(json['rating'] as Map<String, dynamic>? ?? {}),
      equipment: FactorScore.fromJson(
          json['equipment'] as Map<String, dynamic>? ?? {}),
      experience: FactorScore.fromJson(
          json['experience'] as Map<String, dynamic>? ?? {}),
      specialization: FactorScore.fromJson(
          json['specialization'] as Map<String, dynamic>? ?? {}),
    );
  }

  List<FactorScore> get allFactors => [
        distance,
        availability,
        rating,
        equipment,
        experience,
        specialization,
      ];
}

class FactorScore {
  final dynamic value;
  final double score;
  final String? label;

  const FactorScore({
    required this.value,
    required this.score,
    this.label,
  });

  factory FactorScore.fromJson(Map<String, dynamic> json) {
    return FactorScore(
      value: json['value'],
      score: (json['score'] as num?)?.toDouble() ?? 0,
      label: json['label'] as String?,
    );
  }
}
