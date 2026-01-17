import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/price_estimation.dart';

/// Widget pour afficher l'estimation de prix IA
class PriceEstimationCard extends StatelessWidget {
  final PriceEstimation estimation;
  final VoidCallback? onAccept;
  final bool showDetails;

  const PriceEstimationCard({
    super.key,
    required this.estimation,
    this.onAccept,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowMD,
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec prix suggéré
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLG),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimation IA',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${estimation.suggestedPrice.toStringAsFixed(2)}\$',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'taxes incluses',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Fourchette de prix
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Fourchette',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    Text(
                      '${estimation.priceRange.min.toStringAsFixed(0)}\$ - ${estimation.priceRange.max.toStringAsFixed(0)}\$',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (showDetails) ...[
            // Détails des ajustements
            if (estimation.hasAdjustments) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Majorations appliquées',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              ...estimation.adjustments.map(
                (adj) => _buildAdjustmentRow(adj),
              ),
            ],

            // Détail des taxes
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Prix de base',
                    '${estimation.basePrice.toStringAsFixed(2)}\$',
                  ),
                  if (estimation.multipliers.total > 1)
                    _buildDetailRow(
                      'Multiplicateur',
                      'x${estimation.multipliers.total.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                  _buildDetailRow(
                    'Sous-total',
                    '${estimation.priceBeforeTax.toStringAsFixed(2)}\$',
                  ),
                  _buildDetailRow(
                    'TPS (5%)',
                    '${estimation.taxes.tps.toStringAsFixed(2)}\$',
                    isSmall: true,
                  ),
                  _buildDetailRow(
                    'TVQ (9.975%)',
                    '${estimation.taxes.tvq.toStringAsFixed(2)}\$',
                    isSmall: true,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Total',
                    '${estimation.suggestedPrice.toStringAsFixed(2)}\$',
                    isBold: true,
                  ),
                ],
              ),
            ),

            // Raisonnement IA
            if (estimation.reasoning != null &&
                estimation.reasoning!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.smart_toy,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        estimation.reasoning!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAdjustmentRow(PriceAdjustment adjustment) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Text(
            adjustment.icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              adjustment.reason,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            '+${adjustment.amount.toStringAsFixed(2)}\$',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isSmall = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isSmall ? AppTheme.textTertiary : AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isHighlight
                  ? AppTheme.warning
                  : (isBold ? AppTheme.textPrimary : AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
