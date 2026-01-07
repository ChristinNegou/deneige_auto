import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final bool isLoading;
  final VoidCallback onToggle;

  const AvailabilityToggle({
    super.key,
    required this.isAvailable,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAvailable
              ? [AppTheme.success, AppTheme.success.withValues(alpha: 0.7)]
              : [AppTheme.textTertiary, AppTheme.textTertiary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? AppTheme.success : AppTheme.textTertiary).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAvailable ? Icons.wifi_tethering : Icons.wifi_off,
              color: AppTheme.background,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'Vous êtes en ligne' : 'Vous êtes hors ligne',
                  style: TextStyle(
                    color: AppTheme.background,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAvailable
                      ? 'Vous recevez les demandes de déneigement'
                      : 'Activez pour recevoir des demandes',
                  style: TextStyle(
                    color: AppTheme.background.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
              ),
            )
          else
            Transform.scale(
              scale: 1.2,
              child: Switch(
                value: isAvailable,
                onChanged: (_) => onToggle(),
                activeColor: AppTheme.background,
                activeTrackColor: AppTheme.background.withValues(alpha: 0.5),
                inactiveThumbColor: AppTheme.background,
                inactiveTrackColor: AppTheme.background.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }
}
