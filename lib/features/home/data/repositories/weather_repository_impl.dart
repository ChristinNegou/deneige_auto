import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_datasource.dart';

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
      // Si des coordonnées sont fournies, les utiliser
      if (lat != null && lon != null) {
        final weather =
            await remoteDatasource.getWeatherByCoordinates(lat, lon);
        return Right(weather);
      }

      // Sinon, utiliser la météo actuelle par défaut
      final weather = await remoteDatasource.getCurrentWeather();
      return Right(weather);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
