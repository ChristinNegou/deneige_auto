// lib/features/home/domain/repositories/weather_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/weather.dart';

abstract class WeatherRepository {
  Future<Either<Failure, Weather>> getCurrentWeather();

  Future<Either<Failure, Weather>> getWeatherByLocation(
    double latitude,
    double longitude,
  );

  Future<Either<Failure, Weather>> getWeatherForecast(
    DateTime date, {
    String? city,
    double? lat,
    double? lon,
  });
}
