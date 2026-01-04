import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/new_reservation_bloc.dart';
import '../bloc/new_reservation_state.dart';

class PriceSummaryCard extends StatelessWidget {
  final bool showBreakdown;

  const PriceSummaryCard({
    super.key,
    this.showBreakdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        if (state.calculatedPrice == null || state.priceBreakdown == null) {
          return const SizedBox.shrink();
        }

        final breakdown = state.priceBreakdown!;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              // Détails du prix
              if (showBreakdown) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Services de base
                      _buildPriceRow(
                          'Déneigement de base', breakdown.basePrice),

                      if (breakdown.vehicleAdjustment != 0)
                        _buildPriceRow(
                          'Ajustement véhicule',
                          breakdown.vehicleAdjustment,
                          isAdjustment: true,
                        ),

                      if (breakdown.parkingAdjustment != 0)
                        _buildPriceRow(
                          'Ajustement place',
                          breakdown.parkingAdjustment,
                          isAdjustment: true,
                        ),

                      if (breakdown.snowSurcharge > 0)
                        _buildPriceRow(
                            'Supplément neige', breakdown.snowSurcharge),

                      if (breakdown.optionsCost > 0)
                        _buildPriceRow(
                            'Options supplémentaires', breakdown.optionsCost),

                      if (breakdown.urgencyFee > 0)
                        _buildPriceRow(
                          'Frais d\'urgence (40%)',
                          breakdown.urgencyFee,
                          highlight: true,
                          highlightColor: Colors.orange,
                        ),

                      const SizedBox(height: 8),
                      _buildDivider(),
                      const SizedBox(height: 8),

                      // Sous-total
                      _buildPriceRow(
                        'Sous-total',
                        breakdown.subtotal,
                        isBold: true,
                      ),

                      const SizedBox(height: 12),

                      // Frais
                      _buildPriceRow(
                        'Frais de service',
                        breakdown.serviceFee,
                        isSmall: true,
                      ),
                      _buildPriceRow(
                        'Frais d\'assurance',
                        breakdown.insuranceFee,
                        isSmall: true,
                      ),

                      const SizedBox(height: 12),

                      // Taxes dynamiques selon la province
                      if (breakdown.isHST) ...[
                        // HST combinée (Ontario, Maritimes)
                        _buildPriceRow(
                          breakdown.federalTaxLabel,
                          breakdown.federalTax,
                          isSmall: true,
                          isTax: true,
                        ),
                      ] else ...[
                        // TPS/GST + TVQ/PST séparées
                        _buildPriceRow(
                          breakdown.federalTaxLabel,
                          breakdown.federalTax,
                          isSmall: true,
                          isTax: true,
                        ),
                        if (breakdown.provincialTax > 0)
                          _buildPriceRow(
                            breakdown.provincialTaxLabel,
                            breakdown.provincialTax,
                            isSmall: true,
                            isTax: true,
                          ),
                      ],

                      // Indicateur de province
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Taxes calculées pour: ${breakdown.provinceName}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildDivider(),
              ],

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: showBreakdown
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        )
                      : BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total à payer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Taxes incluses',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          breakdown.totalPrice.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '\$ CAD',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badge urgence
              if (state.isUrgent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Réservation urgente - Frais majorés',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isAdjustment = false,
    bool highlight = false,
    Color? highlightColor,
    bool isBold = false,
    bool isSmall = false,
    bool isTax = false,
  }) {
    final isNegative = amount < 0;
    final textColor = highlight
        ? highlightColor ?? AppTheme.primary
        : isNegative
            ? Colors.green[600]
            : isTax
                ? Colors.grey[500]
                : Colors.grey[700];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isTax ? Colors.grey[500] : Colors.grey[700],
            ),
          ),
          Text(
            '${isAdjustment ? (isNegative ? '' : '+') : ''}${amount.toStringAsFixed(2)} \$',
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight:
                  isBold || highlight ? FontWeight.w600 : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], height: 1);
  }
}
