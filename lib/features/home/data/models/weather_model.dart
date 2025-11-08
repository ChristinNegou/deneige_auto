import 'package:json_annotation/json_annotation.dart';
import '../../../reservation/domain/entities/weather.dart';

part 'weather_model.g.dart';

@JsonSerializable()
class WeatherModel extends Weather {
  const WeatherModel({
    required super.temperature,
    required super.condition,
    required super.humidity,
    required super.windSpeed,
    super.snowDepthCm,
    super.icon,
    super.hasSnowAlert,
    super.description,
    required super.timestamp,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherModelFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherModelToJson(this);

  /// Convertit les données de l'API OpenWeatherMap en WeatherModel
  factory WeatherModel.fromOpenWeatherMap(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List;
    final weather = weatherList.first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final snow = json['snow'] as Map<String, dynamic>?;
    final rain = json['rain'] as Map<String, dynamic>?;

    // Extraire les informations
    final temp = (main['temp'] as num).toDouble();
    final weatherMain = weather['main'] as String;
    final weatherDescription = weather['description'] as String;
    final weatherId = weather['id'] as int;
    final humidity = main['humidity'] as int;
    final windSpeed = (wind['speed'] as num).toDouble();
    
    // Calculer l'accumulation de neige (en cm)
    // OpenWeatherMap donne la quantité en mm pour les 1h ou 3h dernières
    int snowDepth = 0;
    if (snow != null) {
      final snow1h = snow['1h'] ?? 0;
      final snow3h = snow['3h'] ?? 0;
      final snowMm = (snow1h != 0 ? snow1h : snow3h) as num;
      snowDepth = (snowMm / 10).round(); // Conversion mm -> cm (approximatif)
    }
    
    // Détecter les alertes neige
    final hasSnowAlert = _shouldShowSnowAlert(
      weatherMain,
      weatherId,
      snowDepth,
      rain,
    );

    return WeatherModel(
      temperature: temp,
      condition: _translateCondition(weatherMain),
      humidity: humidity,
      windSpeed: windSpeed * 3.6, // Conversion m/s -> km/h
      snowDepthCm: snowDepth,
      icon: _getIconFromWeatherId(weatherId, weatherMain),
      hasSnowAlert: hasSnowAlert,
      description: _capitalizeFirstLetter(weatherDescription),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
    );
  }

  /// Détermine si une alerte neige doit être affichée
  static bool _shouldShowSnowAlert(
    String weatherMain,
    int weatherId,
    int snowDepth,
    Map<String, dynamic>? rain,
  ) {
    // Afficher l'alerte si :
    // 1. Il neige actuellement (weatherId 6xx = neige)
    // 2. Il y a plus de 2 cm de neige accumulée
    // 3. Il pleut avec des températures proches de 0 (risque de verglas)
    
    if (weatherMain.toLowerCase() == 'snow' || (weatherId >= 600 && weatherId < 700)) {
      return true;
    }
    
    if (snowDepth >= 2) {
      return true;
    }
    
    // Vérifier pluie + froid (verglas potentiel)
    if (rain != null && weatherMain.toLowerCase() == 'rain') {
      return true; // Dans un contexte de déneigement, pluie = alerte aussi
    }
    
    return false;
  }

  /// Traduit les conditions météo en français
  static String _translateCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Dégagé';
      case 'clouds':
        return 'Nuageux';
      case 'rain':
        return 'Pluvieux';
      case 'drizzle':
        return 'Bruine';
      case 'snow':
        return 'Neigeux';
      case 'thunderstorm':
        return 'Orageux';
      case 'mist':
      case 'fog':
        return 'Brouillard';
      case 'smoke':
      case 'haze':
        return 'Brume';
      case 'dust':
      case 'sand':
        return 'Poussière';
      case 'ash':
        return 'Cendres';
      case 'squall':
        return 'Bourrasques';
      case 'tornado':
        return 'Tornade';
      default:
        return condition;
    }
  }

  /// Retourne l'emoji approprié selon le code météo OpenWeatherMap
  static String _getIconFromWeatherId(int weatherId, String main) {
    // Codes OpenWeatherMap:
    // 2xx: Thunderstorm
    // 3xx: Drizzle
    // 5xx: Rain
    // 6xx: Snow
    // 7xx: Atmosphere (mist, fog, etc.)
    // 800: Clear
    // 80x: Clouds
    
    if (weatherId >= 200 && weatherId < 300) {
      return '⛈️'; // Orage
    } else if (weatherId >= 300 && weatherId < 400) {
      return '🌦️'; // Bruine
    } else if (weatherId >= 500 && weatherId < 600) {
      return '🌧️'; // Pluie
    } else if (weatherId >= 600 && weatherId < 700) {
      return '🌨️'; // Neige
    } else if (weatherId >= 700 && weatherId < 800) {
      return '🌫️'; // Brouillard
    } else if (weatherId == 800) {
      return '☀️'; // Dégagé
    } else if (weatherId > 800) {
      return '☁️'; // Nuageux
    }
    
    // Fallback sur le type principal
    return _getIconFromCondition(main);
  }

  /// Retourne l'emoji selon la condition (fallback)
  static String _getIconFromCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'snow':
        return '🌨️';
      case 'thunderstorm':
        return '⛈️';
      case 'drizzle':
        return '🌦️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  /// Met la première lettre en majuscule
  static String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}