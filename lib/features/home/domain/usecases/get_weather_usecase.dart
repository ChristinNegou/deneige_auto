import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../reservation/domain/entities/weather.dart';
import '../repositories/weather_repository.dart';

/// Use case pour récupérer la météo actuelle
/// 
/// Responsabilité : Orchestrer la logique métier pour obtenir la météo
class GetWeatherUseCase {
  final WeatherRepository repository;

  GetWeatherUseCase(this.repository);

  /// Appelle le repository pour obtenir la météo actuelle
  /// 
  /// Paramètres optionnels:
  /// - [city]: Nom de la ville
  /// - [lat]: Latitude
  /// - [lon]: Longitude
  /// 
  /// Si aucun paramètre n'est fourni, utilise les coordonnées par défaut
  /// (Trois-Rivières selon votre config)
  Future<Either<Failure, Weather>> call({
    String? city,
    double? lat,
    double? lon,
  }) async {
    return await repository.getCurrentWeather(
      city: city,
      lat: lat,
      lon: lon,
    );
  }
}