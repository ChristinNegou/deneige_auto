import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSM,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Résumé de la réservation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
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
                      value: state.selectedVehicle?.displayName ?? '-',
                    ),

                    Divider(height: 24, color: AppTheme.border),

                    // ✅ Logique corrigée pour afficher la place de parking
                    _SummaryRow(
                      icon: Icons.local_parking,
                      label: 'Place',
                      value: _getParkingSpotDisplay(state),
                    ),

                    Divider(height: 24, color: AppTheme.border),

                    _SummaryRow(
                      icon: Icons.access_time,
                      label: 'Départ',
                      value: state.departureDateTime != null
                          ? DateFormat('d MMM yyyy, HH:mm', 'fr_CA')
                              .format(state.departureDateTime!)
                          : '-',
                    ),

                    if (state.selectedOptions.isNotEmpty) ...[
                      Divider(height: 24, color: AppTheme.border),
                      _SummaryRow(
                        icon: Icons.tune,
                        label: 'Options',
                        value: state.selectedOptions
                            .map((o) => _getOptionShortName(o))
                            .join(', '),
                      ),
                    ],

                    if (state.snowDepthCm != null) ...[
                      Divider(height: 24, color: AppTheme.border),
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

  // ✅ Nouvelle méthode pour déterminer l'affichage de la place
  String _getParkingSpotDisplay(NewReservationState state) {
    // 1. Si une place de parking complète est sélectionnée
    if (state.selectedParkingSpot != null) {
      return state.selectedParkingSpot!.fullDisplayName;
    }

    // 2. Si un numéro de place manuel est entré
    if (state.parkingSpotNumber != null &&
        state.parkingSpotNumber!.isNotEmpty) {
      return 'Place ${state.parkingSpotNumber}';
    }

    // 3. Si un emplacement personnalisé est entré
    if (state.customLocation != null && state.customLocation!.isNotEmpty) {
      return state.customLocation!;
    }

    // 4. Sinon, afficher un tiret
    return '-';
  }

  String _getOptionShortName(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return 'Vitres';
      case ServiceOption.doorDeicing:
        return 'Roues';
      case ServiceOption.wheelClearance:
        return 'Portes';
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
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
