import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../reservation/domain/entities/weather.dart';

/// Interface du repository météo
/// Définit le contrat que l'implémentation doit respecter
abstract class WeatherRepository {
  /// Récupère la météo actuelle
  /// 
  /// Peut utiliser soit le nom de la ville, soit les coordonnées GPS
  /// Paramètres:
  /// - [city]: Nom de la ville (ex: "Trois-Rivières,CA")
  /// - [lat]: Latitude GPS
  /// - [lon]: Longitude GPS
  Future<Either<Failure, Weather>> getCurrentWeather({
    String? city,
    double? lat,
    double? lon,
  });
  
  /// Récupère les prévisions météo pour une date donnée
  /// 
  /// Paramètres:
  /// - [date]: Date pour laquelle obtenir les prévisions
  /// - [city]: Nom de la ville (optionnel)
  /// - [lat]: Latitude GPS (optionnel)
  /// - [lon]: Longitude GPS (optionnel)
  Future<Either<Failure, Weather>> getWeatherForecast(
    DateTime date, {
    String? city,
    double? lat,
    double? lon,
  });
}