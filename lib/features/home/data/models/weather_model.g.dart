// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherModel _$WeatherModelFromJson(Map<String, dynamic> json) => WeatherModel(
      location: json['location'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      condition: json['condition'] as String,
      conditionCode: json['conditionCode'] as String,
      humidity: (json['humidity'] as num).toInt(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      snowDepth: (json['snowDepth'] as num?)?.toInt(),
      nextSnowfall: json['nextSnowfall'] == null
          ? null
          : DateTime.parse(json['nextSnowfall'] as String),
      iconUrl: json['iconUrl'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$WeatherModelToJson(WeatherModel instance) =>
    <String, dynamic>{
      'location': instance.location,
      'temperature': instance.temperature,
      'condition': instance.condition,
      'conditionCode': instance.conditionCode,
      'humidity': instance.humidity,
      'windSpeed': instance.windSpeed,
      'snowDepth': instance.snowDepth,
      'nextSnowfall': instance.nextSnowfall?.toIso8601String(),
      'iconUrl': instance.iconUrl,
      'timestamp': instance.timestamp.toIso8601String(),
    };
