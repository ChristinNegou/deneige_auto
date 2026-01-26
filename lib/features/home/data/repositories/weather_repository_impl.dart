import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_datasource.dart';
import '../models/weather_model.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDatasource remoteDatasource;

  WeatherRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, Weather>> getCurrentWeather() async {
    try {
      final weather = await remoteDatasource.getCurrentWeather();
      return Right(weather);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Weather>> getWeatherByLocation(
    double lat,
    double lon,
  ) async {
    try {
      final weather = await remoteDatasource.getWeatherByCoordinates(lat, lon);
      return Right(weather);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Weather>> getWeatherForecast(
    DateTime date, {
    String? city,
    double? lat,
    double? lon,
  }) async {
    try {
      // Utiliser l'endpoint de prévisions pour obtenir les données forecast
      final forecastData = await remoteDatasource.getForecast();

      // Chercher la prévision la plus proche de la date demandée
      final list = forecastData['list'] as List<dynamic>? ?? [];

      if (list.isNotEmpty) {
        // Trouver l'entrée la plus proche de la date demandée
        Map<String, dynamic>? closest;
        Duration? closestDiff;

        for (final entry in list) {
          final dt = DateTime.fromMillisecondsSinceEpoch(
            (entry['dt'] as int) * 1000,
          );
          final diff = dt.difference(date).abs();
          if (closestDiff == null || diff < closestDiff) {
            closestDiff = diff;
            closest = entry as Map<String, dynamic>;
          }
        }

        if (closest != null) {
          return Right(WeatherModel.fromOpenWeatherJson(closest));
        }
      }

      // Fallback: utiliser la météo actuelle
      final weather = await remoteDatasource.getCurrentWeather();
      return Right(weather);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
