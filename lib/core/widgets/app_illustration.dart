import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

/// Types d'illustrations disponibles dans l'application
enum IllustrationType {
  // Onboarding
  welcome,
  calendar,
  location,
  payment,

  // États vides
  emptyReservations,
  emptyVehicles,
  emptyNotifications,
  emptyActivities,
  emptyJobs,
  emptyChat,
  emptyHistory,

  // Wizard réservation
  stepVehicle,
  stepLocation,
  stepDateTime,
  stepOptions,
  stepSummary,

  // Succès et confirmations
  success,
  paymentSuccess,

  // Erreurs
  error,
  noConnection,

  // Chargement
  loading,

  // Autres
  weather,
  earnings,
  worker,
}

/// Chemins des animations Lottie locales
class _LottieAssets {
  static const String basePath = 'assets/lottie';

  static const Map<IllustrationType, String> paths = {
    // Onboarding
    IllustrationType.welcome: '$basePath/welcome.json',
    IllustrationType.calendar: '$basePath/calendar.json',
    IllustrationType.location: '$basePath/location.json',
    IllustrationType.payment: '$basePath/payment.json',

    // États vides
    IllustrationType.emptyReservations: '$basePath/empty.json',
    IllustrationType.emptyVehicles: '$basePath/car.json',
    IllustrationType.emptyNotifications: '$basePath/empty.json',
    IllustrationType.emptyActivities: '$basePath/empty.json',
    IllustrationType.emptyJobs: '$basePath/empty.json',
    IllustrationType.emptyChat: '$basePath/empty.json',
    IllustrationType.emptyHistory: '$basePath/empty.json',

    // Wizard
    IllustrationType.stepVehicle: '$basePath/car.json',
    IllustrationType.stepLocation: '$basePath/location.json',
    IllustrationType.stepDateTime: '$basePath/calendar.json',
    IllustrationType.stepOptions: '$basePath/snowflake.json',
    IllustrationType.stepSummary: '$basePath/success.json',

    // Succès
    IllustrationType.success: '$basePath/success.json',
    IllustrationType.paymentSuccess: '$basePath/payment.json',

    // Erreurs
    IllustrationType.error: '$basePath/error.json',
    IllustrationType.noConnection: '$basePath/error.json',

    // Autres
    IllustrationType.loading: '$basePath/loading.json',
    IllustrationType.weather: '$basePath/snowflake.json',
    IllustrationType.earnings: '$basePath/payment.json',
    IllustrationType.worker: '$basePath/car.json',
  };
}

/// Widget d'illustration réutilisable avec fallback sur icône
class AppIllustration extends StatelessWidget {
  final IllustrationType type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool animate;
  final Color? fallbackIconColor;

  const AppIllustration({
    super.key,
    required this.type,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.animate = true,
    this.fallbackIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final path = _LottieAssets.paths[type];

    if (path == null) {
      return _buildFallbackIcon();
    }

    return SizedBox(
      width: width ?? 200,
      height: height ?? 200,
      child: Lottie.asset(
        path,
        fit: fit,
        animate: animate,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
        frameBuilder: (context, child, composition) {
          if (composition == null) {
            return _buildLoadingPlaceholder();
          }
          return child;
        },
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    final iconData = _getFallbackIcon();
    final color = fallbackIconColor ?? AppTheme.primary;

    return Container(
      width: width ?? 200,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: (width ?? 200) * 0.4,
        color: color,
      ),
    );
  }

  IconData _getFallbackIcon() {
    switch (type) {
      case IllustrationType.welcome:
        return Icons.ac_unit;
      case IllustrationType.calendar:
      case IllustrationType.emptyReservations:
        return Icons.calendar_today_rounded;
      case IllustrationType.location:
      case IllustrationType.stepLocation:
        return Icons.location_on_rounded;
      case IllustrationType.payment:
      case IllustrationType.paymentSuccess:
        return Icons.payment_rounded;
      case IllustrationType.emptyVehicles:
      case IllustrationType.stepVehicle:
        return Icons.directions_car_rounded;
      case IllustrationType.emptyNotifications:
        return Icons.notifications_none_rounded;
      case IllustrationType.emptyActivities:
      case IllustrationType.emptyHistory:
        return Icons.history_rounded;
      case IllustrationType.emptyJobs:
        return Icons.work_outline_rounded;
      case IllustrationType.emptyChat:
        return Icons.chat_bubble_outline_rounded;
      case IllustrationType.stepDateTime:
        return Icons.access_time_rounded;
      case IllustrationType.stepOptions:
        return Icons.tune_rounded;
      case IllustrationType.stepSummary:
        return Icons.checklist_rounded;
      case IllustrationType.success:
        return Icons.check_circle_rounded;
      case IllustrationType.error:
        return Icons.error_outline_rounded;
      case IllustrationType.noConnection:
        return Icons.wifi_off_rounded;
      case IllustrationType.loading:
        return Icons.hourglass_empty_rounded;
      case IllustrationType.weather:
        return Icons.cloud_rounded;
      case IllustrationType.earnings:
        return Icons.attach_money_rounded;
      case IllustrationType.worker:
        return Icons.engineering_rounded;
    }
  }
}

/// Widget pour afficher un état vide avec illustration
class EmptyStateWidget extends StatelessWidget {
  final IllustrationType illustrationType;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double illustrationSize;

  const EmptyStateWidget({
    super.key,
    required this.illustrationType,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.illustrationSize = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIllustration(
              type: illustrationType,
              width: illustrationSize,
              height: illustrationSize,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher une erreur avec illustration
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final bool isNetworkError;

  const ErrorStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.isNetworkError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIllustration(
              type: isNetworkError
                  ? IllustrationType.noConnection
                  : IllustrationType.error,
              width: 150,
              height: 150,
              fallbackIconColor: AppTheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget pour l'en-tête d'une étape du wizard
class StepHeaderWidget extends StatelessWidget {
  final IllustrationType illustrationType;
  final String title;
  final String? subtitle;
  final double illustrationSize;

  const StepHeaderWidget({
    super.key,
    required this.illustrationType,
    required this.title,
    this.subtitle,
    this.illustrationSize = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppIllustration(
          type: illustrationType,
          width: illustrationSize,
          height: illustrationSize,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: AppTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Widget de succès avec illustration animée
class SuccessWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool showConfetti;

  const SuccessWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.showConfetti = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIllustration(
              type: IllustrationType.success,
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTheme.headlineLarge.copyWith(
                color: AppTheme.success,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                ),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
