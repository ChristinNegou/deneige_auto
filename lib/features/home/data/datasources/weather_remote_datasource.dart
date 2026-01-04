// lib/features/home/data/datasources/weather_remote_datasource.dart

import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import '../../../../core/config/app_config.dart';

abstract class WeatherRemoteDatasource {
  Future<WeatherModel> getCurrentWeather();
  Future<WeatherModel> getWeatherByCoordinates(double lat, double lon);
}

class WeatherRemoteDatasourceImpl implements WeatherRemoteDatasource {
  final Dio dio;

  WeatherRemoteDatasourceImpl({required this.dio});

  @override
  Future<WeatherModel> getCurrentWeather() async {
    try {
      final response = await dio.get(
        '${AppConfig.openWeatherBaseUrl}/weather',
        queryParameters: {
          'q': '${AppConfig.defaultCity},${AppConfig.defaultCountryCode}',
          'appid': AppConfig.openWeatherApiKey,
          'units': 'metric', // Celsius
          'lang': 'fr', // Texte en français
        },
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromOpenWeatherJson(response.data);
      } else {
        throw Exception('Failed to load weather');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Clé API invalide. Vérifiez votre configuration.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Ville non trouvée.');
      }
      throw Exception('Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<WeatherModel> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final response = await dio.get(
        '${AppConfig.openWeatherBaseUrl}/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': AppConfig.openWeatherApiKey,
          'units': 'metric',
          'lang': 'fr',
        },
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromOpenWeatherJson(response.data);
      } else {
        throw Exception('Failed to load weather');
      }
    } on DioException catch (e) {
      throw Exception('Erreur météo: ${e.message}');
    }
  }

  /// Récupère les prévisions (pour détecter la neige à venir)
  Future<Map<String, dynamic>> getForecast() async {
    try {
      final response = await dio.get(
        '${AppConfig.openWeatherBaseUrl}/forecast',
        queryParameters: {
          'q': '${AppConfig.defaultCity},${AppConfig.defaultCountryCode}',
          'appid': AppConfig.openWeatherApiKey,
          'units': 'metric',
          'lang': 'fr',
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Erreur prévisions: $e');
    }
  }
}
