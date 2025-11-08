import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../reservation/domain/entities/weather.dart';
import '../models/weather_model.dart';

abstract class WeatherRemoteDataSource {
  Future<Weather> getCurrentWeather({String? city, double? lat, double? lon});
  Future<Weather> getWeatherForecast(DateTime date, {String? city, double? lat, double? lon});
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final Dio dio;
  final String apiKey;
  
  // Coordonnées par défaut (Trois-Rivières, QC)
  static const double defaultLat = 46.3432;
  static const double defaultLon = -72.5476;
  static const String defaultCity = 'Trois-Rivières,CA';

  WeatherRemoteDataSourceImpl({
    required this.dio,
    required this.apiKey,
  });

  @override
  Future<Weather> getCurrentWeather({
    String? city,
    double? lat,
    double? lon,
  }) async {
    try {
      // Préparer les paramètres de la requête
      final queryParams = <String, dynamic>{
        'appid': apiKey,
        'units': 'metric', // Pour avoir les températures en Celsius
        'lang': 'fr', // Pour avoir les descriptions en français
      };

      // Utiliser les coordonnées GPS si disponibles, sinon le nom de ville
      if (lat != null && lon != null) {
        queryParams['lat'] = lat;
        queryParams['lon'] = lon;
      } else {
        queryParams['q'] = city ?? defaultCity;
      }

      final response = await dio.get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromOpenWeatherMap(response.data);
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération de la météo',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Erreur inattendue: ${e.toString()}');
    }
  }

  @override
  Future<Weather> getWeatherForecast(
    DateTime date, {
    String? city,
    double? lat,
    double? lon,
  }) async {
    try {
      // Préparer les paramètres de la requête
      final queryParams = <String, dynamic>{
        'appid': apiKey,
        'units': 'metric',
        'lang': 'fr',
      };

      // Utiliser les coordonnées GPS si disponibles, sinon le nom de ville
      if (lat != null && lon != null) {
        queryParams['lat'] = lat;
        queryParams['lon'] = lon;
      } else {
        queryParams['q'] = city ?? defaultCity;
      }

      final response = await dio.get(
        'https://api.openweathermap.org/data/2.5/forecast',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // L'API forecast retourne une liste de prévisions toutes les 3h
        final forecasts = response.data['list'] as List;
        
        // Trouver la prévision la plus proche de la date demandée
        final targetTimestamp = date.millisecondsSinceEpoch ~/ 1000;
        
        Map<String, dynamic>? closestForecast;
        int minDiff = 999999999;
        
        for (final forecast in forecasts) {
          final forecastTime = forecast['dt'] as int;
          final diff = (forecastTime - targetTimestamp).abs();
          
          if (diff < minDiff) {
            minDiff = diff;
            closestForecast = forecast as Map<String, dynamic>;
          }
        }
        
        if (closestForecast != null) {
          return WeatherModel.fromOpenWeatherMap(closestForecast);
        } else {
          throw ServerException(message: 'Aucune prévision disponible pour cette date');
        }
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération des prévisions',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Erreur inattendue: ${e.toString()}');
    }
  }

  /// Gère les erreurs Dio et les convertit en exceptions personnalisées
  Never _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw NetworkException(message: 'Délai de connexion dépassé');
    } else if (e.type == DioExceptionType.connectionError) {
      throw NetworkException(message: 'Pas de connexion Internet');
    } else if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data['message'] ?? 'Erreur serveur';
      
      if (statusCode == 401) {
        throw ServerException(
          message: 'Clé API invalide ou expirée',
          statusCode: statusCode,
        );
      } else if (statusCode == 404) {
        throw ServerException(
          message: 'Ville non trouvée',
          statusCode: statusCode,
        );
      } else {
        throw ServerException(
          message: message,
          statusCode: statusCode,
        );
      }
    } else {
      throw NetworkException(message: 'Erreur réseau inconnue');
    }
  }
}