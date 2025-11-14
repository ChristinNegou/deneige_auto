// lib/features/home/data/datasources/weather_mock_datasource.dart

import '../models/weather_model.dart';

class WeatherMockDatasource {
  Future<WeatherModel> getCurrentWeather() async {
    // Simuler latence réseau
    await Future.delayed(const Duration(seconds: 1));

    // Retourner données mockées
    return WeatherModel.mock();
  }
}