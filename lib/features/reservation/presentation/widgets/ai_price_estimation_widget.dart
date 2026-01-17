import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../ai_features/presentation/bloc/ai_features_bloc.dart';
import '../../../ai_features/presentation/bloc/ai_features_state.dart';

/// Widget pour afficher l'estimation de prix IA dans le flow de reservation
class AIPriceEstimationWidget extends StatelessWidget {
  const AIPriceEstimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIFeaturesBloc, AIFeaturesState>(
      builder: (context, state) {
        // Loading state
        if (state.isEstimatingPrice) {
          return _buildLoadingCard();
        }

        // Error state
        if (state.priceEstimationError != null) {
          return _buildErrorCard(state.priceEstimationError!);
        }

        // No estimation yet
        if (state.priceEstimation == null) {
          return const SizedBox.shrink();
        }

        final estimation = state.priceEstimation!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.08),
                AppTheme.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimation IA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Prix suggere base sur la demande',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Prix suggere
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${estimation.suggestedPrice.toStringAsFixed(2)}\$',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          '${estimation.priceRange.min.toStringAsFixed(0)}\$ - ${estimation.priceRange.max.toStringAsFixed(0)}\$',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Multiplicateurs actifs
              if (estimation.multipliers.hasActiveMultipliers) ...[
                Divider(
                    height: 1, color: AppTheme.primary.withValues(alpha: 0.1)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Facteurs de prix',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (estimation.multipliers.urgency > 1)
                            _buildMultiplierChip(
                              'Urgence',
                              estimation.multipliers.urgency,
                              Icons.bolt,
                              AppTheme.warning,
                            ),
                          if (estimation.multipliers.weather > 1)
                            _buildMultiplierChip(
                              'Meteo',
                              estimation.multipliers.weather,
                              Icons.cloud,
                              AppTheme.info,
                            ),
                          if (estimation.multipliers.demand > 1)
                            _buildMultiplierChip(
                              'Demande',
                              estimation.multipliers.demand,
                              Icons.trending_up,
                              AppTheme.error,
                            ),
                          if (estimation.multipliers.location > 1)
                            _buildMultiplierChip(
                              'Zone',
                              estimation.multipliers.location,
                              Icons.location_on,
                              AppTheme.secondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Raisonnement IA
              if (estimation.reasoning != null &&
                  estimation.reasoning!.isNotEmpty) ...[
                Divider(
                    height: 1, color: AppTheme.primary.withValues(alpha: 0.1)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          estimation.reasoning!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
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
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Estimation IA en cours...',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppTheme.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Estimation IA non disponible',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierChip(
    String label,
    double multiplier,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label x${multiplier.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
