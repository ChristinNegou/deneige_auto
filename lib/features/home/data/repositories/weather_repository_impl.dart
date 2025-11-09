import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../reservation/domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_datasource.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;

  WeatherRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Weather>> getCurrentWeather({
    String? city,
    double? lat,
    double? lon,
  }) async {
    try {
      final weather = await remoteDataSource.getCurrentWeather(
        city: city,
        lat: lat,
        lon: lon,
      );
      return Right(weather);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
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
      final weather = await remoteDataSource.getWeatherForecast(
        date,
        city: city,
        lat: lat,
        lon: lon,
      );
      return Right(weather);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }
}