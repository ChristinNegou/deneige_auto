/// Analyse IA des photos de job
class PhotoAnalysis {
  final String vehicleType;
  final bool vehicleDetected;
  final int? estimatedSnowDepthCm;
  final int qualityScore;
  final int completenessScore;
  final List<String> issues;
  final String summary;
  final String? beforePhotoQuality;
  final String? afterPhotoQuality;
  final bool isSuspiciousPhoto;
  final PhotosAnalyzedCount photosAnalyzed;
  final DateTime analyzedAt;
  final String modelVersion;

  const PhotoAnalysis({
    required this.vehicleType,
    required this.vehicleDetected,
    this.estimatedSnowDepthCm,
    required this.qualityScore,
    required this.completenessScore,
    required this.issues,
    required this.summary,
    this.beforePhotoQuality,
    this.afterPhotoQuality,
    required this.isSuspiciousPhoto,
    required this.photosAnalyzed,
    required this.analyzedAt,
    required this.modelVersion,
  });

  factory PhotoAnalysis.fromJson(Map<String, dynamic> json) {
    return PhotoAnalysis(
      vehicleType: json['vehicleType'] as String? ?? 'unknown',
      vehicleDetected: json['vehicleDetected'] as bool? ?? true,
      estimatedSnowDepthCm: (json['estimatedSnowDepthCm'] as num?)?.toInt(),
      qualityScore: (json['qualityScore'] as num?)?.toInt() ?? 0,
      completenessScore: (json['completenessScore'] as num?)?.toInt() ?? 0,
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
      beforePhotoQuality: json['beforePhotoQuality'] as String?,
      afterPhotoQuality: json['afterPhotoQuality'] as String?,
      isSuspiciousPhoto: json['isSuspiciousPhoto'] as bool? ?? false,
      photosAnalyzed: PhotosAnalyzedCount.fromJson(
          json['photosAnalyzed'] as Map<String, dynamic>? ?? {}),
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'] as String)
          : DateTime.now(),
      modelVersion: json['modelVersion'] as String? ?? '',
    );
  }

  /// Score global (moyenne des deux scores)
  int get overallScore => ((qualityScore + completenessScore) / 2).round();

  /// Couleur du score
  String get scoreColor {
    if (overallScore >= 80) return 'green';
    if (overallScore >= 60) return 'orange';
    return 'red';
  }

  /// Label du score
  String get scoreLabel {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Très bien';
    if (overallScore >= 70) return 'Bien';
    if (overallScore >= 60) return 'Acceptable';
    if (overallScore >= 50) return 'À améliorer';
    return 'Insuffisant';
  }

  /// Vérifie si des problèmes ont été détectés
  bool get hasIssues => issues.isNotEmpty;

  /// Traduit les issues en français
  List<String> get issuesLabels {
    return issues.map((issue) {
      switch (issue) {
        case 'neige_residuelle':
          return 'Neige résiduelle détectée';
        case 'vitres_non_degagees':
          return 'Vitres non complètement dégagées';
        case 'toit_non_degage':
          return 'Toit non dégagé';
        case 'photo_floue':
          return 'Photo floue';
        case 'photo_sombre':
          return 'Photo trop sombre';
        case 'vehicule_different':
          return 'Véhicule différent détecté';
        case 'travail_incomplet':
          return 'Travail incomplet';
        case 'pas_de_vehicule':
          return 'Aucun véhicule détecté';
        case 'photo_fake':
          return 'Photo suspecte détectée';
        default:
          return issue;
      }
    }).toList();
  }

  /// Label du type de véhicule
  String get vehicleTypeLabel {
    switch (vehicleType) {
      case 'compact':
        return 'Compacte';
      case 'sedan':
        return 'Berline';
      case 'suv':
        return 'VUS';
      case 'truck':
        return 'Camion';
      case 'minivan':
        return 'Fourgonnette';
      default:
        return 'Véhicule';
    }
  }

  /// Vérifie si la photo est valide (véhicule détecté et pas suspecte)
  bool get isValidPhoto => vehicleDetected && !isSuspiciousPhoto;

  /// Vérifie si des alertes critiques existent
  bool get hasCriticalIssues =>
      !vehicleDetected ||
      isSuspiciousPhoto ||
      issues.contains('pas_de_vehicule') ||
      issues.contains('photo_fake');
}

class PhotosAnalyzedCount {
  final int before;
  final int after;

  const PhotosAnalyzedCount({required this.before, required this.after});

  factory PhotosAnalyzedCount.fromJson(Map<String, dynamic> json) {
    return PhotosAnalyzedCount(
      before: (json['before'] as num?)?.toInt() ?? 0,
      after: (json['after'] as num?)?.toInt() ?? 0,
    );
  }

  int get total => before + after;
}

/// Analyse rapide d'une photo unique
class SinglePhotoAnalysis {
  final bool valid;
  final String quality;
  final List<String> issues;
  final bool isVehicle;

  const SinglePhotoAnalysis({
    required this.valid,
    required this.quality,
    required this.issues,
    required this.isVehicle,
  });

  factory SinglePhotoAnalysis.fromJson(Map<String, dynamic> json) {
    return SinglePhotoAnalysis(
      valid: json['valid'] as bool? ?? true,
      quality: json['quality'] as String? ?? 'average',
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isVehicle: json['isVehicle'] as bool? ?? true,
    );
  }

  bool get isGoodQuality => quality == 'good';
  bool get hasIssues => issues.isNotEmpty;
}
