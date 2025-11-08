import 'package:equatable/equatable.dart';

/// Entity représentant les conditions météorologiques
class Weather extends Equatable {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final int snowDepthCm;
  final String icon;
  final bool hasSnowAlert;
  final String description;
  final DateTime timestamp;

  const Weather({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    this.snowDepthCm = 0,
    this.icon = '☁️',
    this.hasSnowAlert = false,
    this.description = '',
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    temperature,
    condition,
    humidity,
    windSpeed,
    snowDepthCm,
    icon,
    hasSnowAlert,
    description,
    timestamp,
  ];
}