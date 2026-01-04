// lib/features/home/domain/entities/weather.dart

import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final String location;
  final double temperature; // en Celsius
  final String condition; // Ex: "Ensoleillé", "Neigeux", "Nuageux"
  final String conditionCode; // Ex: "sunny", "snow", "cloudy"
  final int humidity; // en %
  final double windSpeed; // en km/h
  final int? snowDepth; // Profondeur de neige en cm (optionnel)
  final DateTime? nextSnowfall; // Prochaine chute de neige prévue
  final String iconUrl; // URL de l'icône météo
  final DateTime timestamp;

  const Weather({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.conditionCode,
    required this.humidity,
    required this.windSpeed,
    this.snowDepth,
    this.nextSnowfall,
    required this.iconUrl,
    required this.timestamp,
  });

  /// Vérifie s'il y a une alerte neige
  bool get hasSnowAlert {
    return conditionCode.contains('snow') ||
        (snowDepth != null && snowDepth! > 5) ||
        (nextSnowfall != null &&
            nextSnowfall!.difference(DateTime.now()).inHours < 24);
  }

  /// Retourne la description de l'alerte
  String? get alertDescription {
    if (!hasSnowAlert) return null;

    if (nextSnowfall != null) {
      final hoursUntil = nextSnowfall!.difference(DateTime.now()).inHours;
      if (hoursUntil < 6) {
        return 'Neige prévue dans ${hoursUntil}h';
      } else if (hoursUntil < 24) {
        return 'Neige prévue aujourd\'hui';
      }
    }

    if (snowDepth != null && snowDepth! > 10) {
      return 'Forte accumulation: ${snowDepth}cm';
    }

    if (conditionCode.contains('snow')) {
      return 'Chutes de neige en cours';
    }

    return 'Conditions hivernales';
  }

  /// Retourne l'emoji selon la condition
  String get emoji {
    switch (conditionCode.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return '☀️';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'snow':
      case 'snowy':
        return '❄️';
      case 'fog':
        return '🌫️';
      case 'storm':
        return '⛈️';
      default:
        return '🌤️';
    }
  }

  Weather copyWith({
    String? location,
    double? temperature,
    String? condition,
    String? conditionCode,
    int? humidity,
    double? windSpeed,
    int? snowDepth,
    DateTime? nextSnowfall,
    String? iconUrl,
    DateTime? timestamp,
  }) {
    return Weather(
      location: location ?? this.location,
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      conditionCode: conditionCode ?? this.conditionCode,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      snowDepth: snowDepth ?? this.snowDepth,
      nextSnowfall: nextSnowfall ?? this.nextSnowfall,
      iconUrl: iconUrl ?? this.iconUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        location,
        temperature,
        condition,
        conditionCode,
        humidity,
        windSpeed,
        snowDepth,
        nextSnowfall,
        iconUrl,
        timestamp,
      ];
}
