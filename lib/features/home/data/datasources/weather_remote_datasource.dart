// lib/features/home/data/datasources/weather_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/weather_model.dart';
import '../../../../core/config/app_config.dart';

abstract class WeatherRemoteDatasource {
  Future<WeatherModel> getCurrentWeather();
  Future<WeatherModel> getWeatherByCoordinates(double lat, double lon);
  Future<Map<String, dynamic>> getForecast();
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
          'lang': 'fr', // Texte en francais
        },
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromOpenWeatherJson(response.data);
      } else {
        throw const ServerException(
            message: 'Erreur lors du chargement de la meteo');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement de la meteo: $e');
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
        throw const ServerException(
            message: 'Erreur lors du chargement de la meteo');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement de la meteo: $e');
    }
  }

  /// Recupere les previsions (pour detecter la neige a venir)
  @override
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
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement des previsions: $e');
    }
  }

  AppException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String?;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Delai de connexion depasse. Verifiez votre connexion.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Impossible de se connecter au serveur.',
        );
      default:
        if (statusCode == 401) {
          return const ServerException(
            message: 'Cle API invalide. Verifiez votre configuration.',
            statusCode: 401,
          );
        }
        if (statusCode == 404) {
          return const ServerException(
            message: 'Ville non trouvee.',
            statusCode: 404,
          );
        }
        return ServerException(
          message: message ?? 'Une erreur serveur est survenue.',
          statusCode: statusCode,
        );
    }
  }
}
