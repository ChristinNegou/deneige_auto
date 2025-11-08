import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../reservation/domain/entities/weather.dart';
import '../repositories/weather_repository.dart';

/// Use case pour récupérer les prévisions météo
class GetWeatherForecastUseCase {
  final WeatherRepository repository;

  GetWeatherForecastUseCase(this.repository);

  /// Récupère les prévisions météo pour une date donnée
  Future<Either<Failure, Weather>> call(
    DateTime date, {
    String? city,
    double? lat,
    double? lon,
  }) async {
    return await repository.getWeatherForecast(
      date,
      city: city,
      lat: lat,
      lon: lon,
    );
  }
}