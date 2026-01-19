import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../widgets/service_option_tile.dart';
import '../../widgets/snow_depth_input.dart';
import '../../widgets/price_summary_card.dart';

class Step4OptionsScreen extends StatelessWidget {
  const Step4OptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Options
              _buildSectionHeader(
                  'Options supplementaires', Icons.add_circle_outline_rounded),
              const SizedBox(height: 12),

              // Grid of compact options (2 columns)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.0,
                children: [
                  ServiceOptionTile(
                    option: ServiceOption.windowScraping,
                    isSelected: state.selectedOptions
                        .contains(ServiceOption.windowScraping),
                    price: AppConfig.iceRemovalSurcharge,
                    compact: true,
                    onToggle: () {
                      context.read<NewReservationBloc>().add(
                            const ToggleServiceOption(
                                ServiceOption.windowScraping),
                          );
                    },
                  ),
                  ServiceOptionTile(
                    option: ServiceOption.doorDeicing,
                    isSelected: state.selectedOptions
                        .contains(ServiceOption.doorDeicing),
                    price: AppConfig.doorDeicingSurcharge,
                    compact: true,
                    onToggle: () {
                      context.read<NewReservationBloc>().add(
                            const ToggleServiceOption(
                                ServiceOption.doorDeicing),
                          );
                    },
                  ),
                  ServiceOptionTile(
                    option: ServiceOption.wheelClearance,
                    isSelected: state.selectedOptions
                        .contains(ServiceOption.wheelClearance),
                    price: AppConfig.wheelClearanceSurcharge,
                    compact: true,
                    onToggle: () {
                      context.read<NewReservationBloc>().add(
                            const ToggleServiceOption(
                                ServiceOption.wheelClearance),
                          );
                    },
                  ),
                  ServiceOptionTile(
                    option: ServiceOption.roofClearing,
                    isSelected: state.selectedOptions
                        .contains(ServiceOption.roofClearing),
                    price: AppConfig.roofClearingSurcharge,
                    compact: true,
                    onToggle: () {
                      context.read<NewReservationBloc>().add(
                            const ToggleServiceOption(
                                ServiceOption.roofClearing),
                          );
                    },
                  ),
                  ServiceOptionTile(
                    option: ServiceOption.saltSpreading,
                    isSelected: state.selectedOptions
                        .contains(ServiceOption.saltSpreading),
                    price: AppConfig.saltSpreadingSurcharge,
                    compact: true,
                    onToggle: () {
                      context.read<NewReservationBloc>().add(
                            const ToggleServiceOption(
                                ServiceOption.saltSpreading),
                          );
                    },
                  ),
                  ServiceOptionTile(
                    option: ServiceOption.lightsCleaning,
                    isSelected: state.selectedOptions
                        .contains(ServiceOption.lightsCleaning),
                    price: AppConfig.lightsCleaningSurcharge,
                    compact: true,
                    onToggle: () {
                      context.read<NewReservationBloc>().add(
                            const ToggleServiceOption(
                                ServiceOption.lightsCleaning),
                          );
                    },
                  ),
                  ServiceOptionTile(
                    option: ServiceOption.perimeterClearance,
                    isSelected: state.selectedOptions
                        .contains(ServiceOption.perimeterClearance),
                    price: AppConfig.perimeterClearanceSurcharge,
                    compact: true,
                    onToggle: () {
                      context.read<NewReservationBloc>().add(
                            const ToggleServiceOption(
                                ServiceOption.perimeterClearance),
                          );
                    },
                  ),
                  ServiceOptionTile(
                    option: ServiceOption.exhaustCheck,
                    isSelected: state.selectedOptions
                        .contains(ServiceOption.exhaustCheck),
                    price: AppConfig.exhaustCheckSurcharge,
                    compact: true,
                    onToggle: () {
                      context.read<NewReservationBloc>().add(
                            const ToggleServiceOption(
                                ServiceOption.exhaustCheck),
                          );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Section Neige
              _buildSectionHeader('Profondeur de neige', Icons.ac_unit_rounded),
              const SizedBox(height: 12),

              SnowDepthInput(
                initialValue: state.snowDepthCm,
                onChanged: (value) {
                  context.read<NewReservationBloc>().add(
                        UpdateSnowDepth(value),
                      );
                },
              ),

              const SizedBox(height: 28),

              // Recapitulatif prix
              _buildSectionHeader('Recapitulatif', Icons.receipt_long_rounded),
              const SizedBox(height: 12),

              const PriceSummaryCard(showBreakdown: true),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
