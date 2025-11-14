import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../bloc/new_reservation_bloc.dart';
import '../bloc/new_reservation_state.dart';
import 'package:intl/intl.dart';
// Widget pour le résumé final (Step 4)
class ReservationSummaryCard extends StatelessWidget {
  const ReservationSummaryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Résumé de la réservation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SummaryRow(
                      icon: Icons.directions_car,
                      label: 'Véhicule',
                      value: state.selectedVehicle?.displayWithColor ?? '-',
                    ),

                    const Divider(height: 24),

                    _SummaryRow(
                      icon: Icons.local_parking,
                      label: 'Place',
                      value: state.selectedParkingSpot?.fullDisplayName ?? '-',
                    ),

                    const Divider(height: 24),

                    _SummaryRow(
                      icon: Icons.access_time,
                      label: 'Départ',
                      value: state.departureDateTime != null
                          ? DateFormat('d MMM yyyy, HH:mm', 'fr_CA')
                          .format(state.departureDateTime!)
                          : '-',
                    ),

                    if (state.selectedOptions.isNotEmpty) ...[
                      const Divider(height: 24),

                      _SummaryRow(
                        icon: Icons.tune,
                        label: 'Options',
                        value: state.selectedOptions
                            .map((o) => _getOptionShortName(o))
                            .join(', '),
                      ),
                    ],

                    if (state.snowDepthCm != null) ...[
                      const Divider(height: 24),

                      _SummaryRow(
                        icon: Icons.ac_unit,
                        label: 'Neige',
                        value: '${state.snowDepthCm} cm',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getOptionShortName(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return 'Vitres';
      case ServiceOption.doorDeicing:
        return 'Portes';
      case ServiceOption.wheelClearance:
        return 'Roues';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}