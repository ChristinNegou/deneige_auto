import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';

class ServiceOptionTile extends StatelessWidget {
  final ServiceOption option;
  final bool isSelected;
  final double price;
  final VoidCallback onToggle;

  const ServiceOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.price,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getOptionIcon(option),
                color:
                    isSelected ? AppTheme.background : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getOptionTitle(option),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getOptionDescription(option),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${price.toStringAsFixed(2)} \$',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          isSelected ? AppTheme.primary : AppTheme.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: AppTheme.background,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getOptionIcon(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return Icons.cleaning_services;
      case ServiceOption.doorDeicing:
        return Icons.door_front_door;
      case ServiceOption.wheelClearance:
        return Icons.tire_repair;
    }
  }

  String _getOptionTitle(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return 'Grattage des vitres';
      case ServiceOption.doorDeicing:
        return 'Déglaçage des portes';
      case ServiceOption.wheelClearance:
        return 'Dégagement des roues';
    }
  }

  String _getOptionDescription(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return 'Grattage complet de toutes les vitres';
      case ServiceOption.doorDeicing:
        return 'Dégivrage des poignées et serrures';
      case ServiceOption.wheelClearance:
        return 'Dégagement de la neige autour des roues';
    }
  }
}
