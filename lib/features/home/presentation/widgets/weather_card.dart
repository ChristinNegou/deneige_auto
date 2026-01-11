// lib/features/home/presentation/widgets/weather_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/weather.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(weather.conditionCode),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Météo',
                    style: TextStyle(
                      color: AppTheme.textPrimary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    weather.location,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                weather.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Température principale
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weather.temperature.round()}°',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.condition,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (weather.snowDepth != null)
                      Text(
                        '${weather.snowDepth} cm au sol',
                        style: TextStyle(
                          color: AppTheme.textPrimary.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Infos supplémentaires
          Row(
            children: [
              Expanded(
                child: _WeatherInfo(
                  icon: Icons.water_drop,
                  label: 'Humidité',
                  value: '${weather.humidity}%',
                ),
              ),
              Expanded(
                child: _WeatherInfo(
                  icon: Icons.air,
                  label: 'Vent',
                  value: '${weather.windSpeed.round()} km/h',
                ),
              ),
            ],
          ),

          // Alerte neige
          if (weather.hasSnowAlert) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warning,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weather.alertDescription ?? 'Alerte neige',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String conditionCode) {
    switch (conditionCode.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return [AppTheme.warning, AppTheme.warning.withValues(alpha: 0.8)];
      case 'cloudy':
      case 'overcast':
        return [AppTheme.textSecondary, AppTheme.textTertiary];
      case 'rain':
        return [AppTheme.info, AppTheme.info.withValues(alpha: 0.8)];
      case 'snow':
      case 'snowy':
        return [AppTheme.info.withValues(alpha: 0.7), AppTheme.info];
      case 'fog':
        return [
          AppTheme.textSecondary.withValues(alpha: 0.7),
          AppTheme.textSecondary
        ];
      default:
        return [AppTheme.info.withValues(alpha: 0.8), AppTheme.info];
    }
  }
}

class _WeatherInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.textPrimary.withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
