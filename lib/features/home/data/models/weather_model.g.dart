// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherModel _$WeatherModelFromJson(Map<String, dynamic> json) => WeatherModel(
      temperature: (json['temperature'] as num).toDouble(),
      condition: json['condition'] as String,
      humidity: (json['humidity'] as num).toInt(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      snowDepthCm: (json['snowDepthCm'] as num?)?.toInt() ?? 0,
      icon: json['icon'] as String? ?? '☁️',
      hasSnowAlert: json['hasSnowAlert'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$WeatherModelToJson(WeatherModel instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'condition': instance.condition,
      'humidity': instance.humidity,
      'windSpeed': instance.windSpeed,
      'snowDepthCm': instance.snowDepthCm,
      'icon': instance.icon,
      'hasSnowAlert': instance.hasSnowAlert,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
    };
