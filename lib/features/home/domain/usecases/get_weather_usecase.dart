// lib/features/home/domain/usecases/get_weather_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/location_service.dart';
import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

class GetWeatherUseCase {
  final WeatherRepository repository;
  final LocationService locationService;

  GetWeatherUseCase({
    required this.repository,
    required this.locationService,
  });

  /// Récupère la météo pour la position actuelle
  Future<Either<Failure, Weather>> call() async {
    try {
      // Obtenir la position (ou position par défaut)
      final position = await locationService.getPositionOrDefault();

      // Récupérer la météo pour cette position
      return await repository.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Récupère la météo pour la position par défaut (Trois-Rivières)
  Future<Either<Failure, Weather>> callDefault() async {
    return await repository.getCurrentWeather();
  }
}