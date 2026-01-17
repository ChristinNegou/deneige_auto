/// Prediction de demande IA
class DemandPrediction {
  final DateTime date;
  final String zone;
  final String? weatherCondition;
  final int? snowDepthForecast;
  final DemandLevel predictedDemand;
  final double demandMultiplier;
  final double confidence;
  final String? reasoning;
  final int? actualReservations;
  final DateTime createdAt;

  const DemandPrediction({
    required this.date,
    required this.zone,
    this.weatherCondition,
    this.snowDepthForecast,
    required this.predictedDemand,
    required this.demandMultiplier,
    required this.confidence,
    this.reasoning,
    this.actualReservations,
    required this.createdAt,
  });

  factory DemandPrediction.fromJson(Map<String, dynamic> json) {
    return DemandPrediction(
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      zone: json['zone'] as String? ?? '',
      weatherCondition: json['weatherCondition'] as String?,
      snowDepthForecast: (json['snowDepthForecast'] as num?)?.toInt(),
      predictedDemand: DemandLevel.fromString(
          json['predictedDemand'] as String? ?? 'medium'),
      demandMultiplier: (json['demandMultiplier'] as num?)?.toDouble() ?? 1.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      reasoning: json['reasoning'] as String?,
      actualReservations: (json['actualReservations'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Couleur selon le niveau de demande
  String get demandColor {
    switch (predictedDemand) {
      case DemandLevel.low:
        return 'green';
      case DemandLevel.medium:
        return 'yellow';
      case DemandLevel.high:
        return 'orange';
      case DemandLevel.urgent:
        return 'red';
    }
  }

  /// Label du niveau de confiance
  String get confidenceLabel {
    if (confidence >= 0.9) return 'Tres haute';
    if (confidence >= 0.75) return 'Haute';
    if (confidence >= 0.5) return 'Moyenne';
    if (confidence >= 0.25) return 'Basse';
    return 'Tres basse';
  }

  /// Icone selon les conditions meteo
  String get weatherIcon {
    switch (weatherCondition?.toLowerCase()) {
      case 'snow':
      case 'neige':
        return '🌨️';
      case 'heavy_snow':
      case 'forte_neige':
        return '❄️';
      case 'rain':
      case 'pluie':
        return '🌧️';
      case 'freezing_rain':
      case 'verglas':
        return '🧊';
      case 'clear':
      case 'clair':
        return '☀️';
      default:
        return '☁️';
    }
  }
}

enum DemandLevel {
  low,
  medium,
  high,
  urgent;

  static DemandLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
      case 'faible':
        return DemandLevel.low;
      case 'medium':
      case 'moyenne':
        return DemandLevel.medium;
      case 'high':
      case 'haute':
      case 'elevee':
        return DemandLevel.high;
      case 'urgent':
      case 'urgente':
        return DemandLevel.urgent;
      default:
        return DemandLevel.medium;
    }
  }

  String get label {
    switch (this) {
      case DemandLevel.low:
        return 'Faible';
      case DemandLevel.medium:
        return 'Moyenne';
      case DemandLevel.high:
        return 'Elevee';
      case DemandLevel.urgent:
        return 'Urgente';
    }
  }

  String get icon {
    switch (this) {
      case DemandLevel.low:
        return '📉';
      case DemandLevel.medium:
        return '📊';
      case DemandLevel.high:
        return '📈';
      case DemandLevel.urgent:
        return '🚨';
    }
  }
}
