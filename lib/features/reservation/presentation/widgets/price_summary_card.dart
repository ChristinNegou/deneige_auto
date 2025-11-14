import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/new_reservation_bloc.dart';
import '../bloc/new_reservation_state.dart';

// ============= PRICE SUMMARY CARD =============
// Widget affichant le prix total en temps réel
class PriceSummaryCard extends StatelessWidget {
  final bool showBreakdown;

  const PriceSummaryCard({
    Key? key,
    this.showBreakdown = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        if (state.calculatedPrice == null) {
          return const SizedBox.shrink();
        }

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(
            begin: state.calculatedPrice! - 1,
            end: state.calculatedPrice!,
          ),
          builder: (context, value, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prix total',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      if (state.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '\$ CAD',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (showBreakdown && state.priceBreakdown != null) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    _buildBreakdown(state.priceBreakdown!),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBreakdown(PriceBreakdown breakdown) {
    return Column(
      children: [
        _PriceBreakdownRow(
          label: 'Prix de base',
          amount: breakdown.basePrice,
        ),

        if (breakdown.vehicleAdjustment != 0)
          _PriceBreakdownRow(
            label: 'Ajustement véhicule',
            amount: breakdown.vehicleAdjustment,
            isAdjustment: true,
          ),

        if (breakdown.parkingAdjustment != 0)
          _PriceBreakdownRow(
            label: 'Ajustement place',
            amount: breakdown.parkingAdjustment,
            isAdjustment: true,
          ),

        if (breakdown.snowSurcharge > 0)
          _PriceBreakdownRow(
            label: 'Supplément neige',
            amount: breakdown.snowSurcharge,
          ),

        if (breakdown.optionsCost > 0)
          _PriceBreakdownRow(
            label: 'Options',
            amount: breakdown.optionsCost,
          ),

        if (breakdown.urgencyFee > 0)
          _PriceBreakdownRow(
            label: 'Frais d\'urgence (+40%)',
            amount: breakdown.urgencyFee,
            highlight: true,
          ),
      ],
    );
  }
}

class _PriceBreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isAdjustment;
  final bool highlight;

  const _PriceBreakdownRow({
    required this.label,
    required this.amount,
    this.isAdjustment = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : '+'} ${amount.abs().toStringAsFixed(2)} \$',
            style: TextStyle(
              color: highlight
                  ? Colors.orange[200]
                  : (isNegative ? Colors.green[200] : Colors.white70),
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}