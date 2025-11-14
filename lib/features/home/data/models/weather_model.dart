// lib/features/home/data/models/weather_model.dart

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/weather.dart';

part 'weather_model.g.dart';

@JsonSerializable()
class WeatherModel extends Weather {
  const WeatherModel({
    required super.location,
    required super.temperature,
    required super.condition,
    required super.conditionCode,
    required super.humidity,
    required super.windSpeed,
    super.snowDepth,
    super.nextSnowfall,
    required super.iconUrl,
    required super.timestamp,
  });

  /// Factory depuis OpenWeatherMap API
  factory WeatherModel.fromOpenWeatherJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List)[0] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;

    // Extraire la neige (si présente dans les 3 dernières heures)
    int? snowDepth;
    if (json.containsKey('snow')) {
      final snow = json['snow'] as Map<String, dynamic>;
      if (snow.containsKey('3h')) {
        // Convertir mm en cm (approximatif: 1mm pluie ≈ 1cm neige)
        snowDepth = ((snow['3h'] as num).toDouble() * 10).round();
      }
    }

    return WeatherModel(
      location: json['name'] as String,
      temperature: (main['temp'] as num).toDouble(),
      condition: weather['description'] as String,
      conditionCode: weather['main'] as String,
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble() * 3.6, // m/s → km/h
      snowDepth: snowDepth,
      iconUrl: 'https://openweathermap.org/img/wn/${weather['icon']}@2x.png',
      timestamp: DateTime.now(),
    );
  }

  /// Factory pour JSON custom (votre backend)
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      location: json['location'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      condition: json['condition'] as String,
      conditionCode: json['conditionCode'] as String,
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      snowDepth: json['snowDepth'] as int?,
      nextSnowfall: json['nextSnowfall'] != null
          ? DateTime.parse(json['nextSnowfall'] as String)
          : null,
      iconUrl: json['iconUrl'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'condition': condition,
      'conditionCode': conditionCode,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'snowDepth': snowDepth,
      'nextSnowfall': nextSnowfall?.toIso8601String(),
      'iconUrl': iconUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Factory Mock pour tests
  factory WeatherModel.mock() {
    return WeatherModel(
      location: 'Trois-Rivières, QC',
      temperature: -5.0,
      condition: 'Neigeux',
      conditionCode: 'Snow',
      humidity: 75,
      windSpeed: 15.5,
      snowDepth: 12,
      nextSnowfall: DateTime.now().add(const Duration(hours: 6)),
      iconUrl: 'https://openweathermap.org/img/wn/13d@2x.png',
      timestamp: DateTime.now(),
    );
  }
}