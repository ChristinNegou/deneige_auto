import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../ai_features/presentation/bloc/ai_features_bloc.dart';
import '../../../../ai_features/presentation/bloc/ai_features_event.dart';
// ai_features_state imported via bloc
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../widgets/service_option_tile.dart';
import '../../widgets/snow_depth_input.dart';
import '../../widgets/price_summary_card.dart';
import '../../widgets/ai_price_estimation_widget.dart';

class Step4OptionsScreen extends StatefulWidget {
  const Step4OptionsScreen({super.key});

  @override
  State<Step4OptionsScreen> createState() => _Step4OptionsScreenState();
}

class _Step4OptionsScreenState extends State<Step4OptionsScreen> {
  late AIFeaturesBloc _aiFeaturesBloc;

  @override
  void initState() {
    super.initState();
    _aiFeaturesBloc = sl<AIFeaturesBloc>();
    // Declencher l'estimation IA au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAIEstimation();
    });
  }

  @override
  void dispose() {
    _aiFeaturesBloc.close();
    super.dispose();
  }

  void _triggerAIEstimation() {
    final reservationState = context.read<NewReservationBloc>().state;

    // Convertir les options en liste de strings
    final serviceOptions =
        reservationState.selectedOptions.map((opt) => opt.name).toList();

    // Calculer le temps avant depart
    int timeUntilDeparture = 120; // Default 2h
    if (reservationState.departureDateTime != null) {
      final now = DateTime.now();
      timeUntilDeparture =
          reservationState.departureDateTime!.difference(now).inMinutes;
      if (timeUntilDeparture < 0) timeUntilDeparture = 120;
    }

    _aiFeaturesBloc.add(EstimatePriceEvent(
      serviceOptions: serviceOptions,
      snowDepthCm: reservationState.snowDepthCm ?? 0,
      timeUntilDepartureMinutes: timeUntilDeparture,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _aiFeaturesBloc,
      child: BlocBuilder<NewReservationBloc, NewReservationState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Options
                _buildSectionHeader('Options supplementaires',
                    Icons.add_circle_outline_rounded),
                const SizedBox(height: 12),

                ServiceOptionTile(
                  option: ServiceOption.windowScraping,
                  isSelected: state.selectedOptions
                      .contains(ServiceOption.windowScraping),
                  price: 5.0,
                  onToggle: () {
                    context.read<NewReservationBloc>().add(
                          const ToggleServiceOption(
                              ServiceOption.windowScraping),
                        );
                    Future.delayed(const Duration(milliseconds: 300),
                        _triggerAIEstimation);
                  },
                ),
                const SizedBox(height: 8),

                ServiceOptionTile(
                  option: ServiceOption.doorDeicing,
                  isSelected:
                      state.selectedOptions.contains(ServiceOption.doorDeicing),
                  price: AppConfig.doorDeicingSurcharge,
                  onToggle: () {
                    context.read<NewReservationBloc>().add(
                          const ToggleServiceOption(ServiceOption.doorDeicing),
                        );
                    Future.delayed(const Duration(milliseconds: 300),
                        _triggerAIEstimation);
                  },
                ),
                const SizedBox(height: 8),

                ServiceOptionTile(
                  option: ServiceOption.wheelClearance,
                  isSelected: state.selectedOptions
                      .contains(ServiceOption.wheelClearance),
                  price: AppConfig.wheelClearanceSurcharge,
                  onToggle: () {
                    context.read<NewReservationBloc>().add(
                          const ToggleServiceOption(
                              ServiceOption.wheelClearance),
                        );
                    Future.delayed(const Duration(milliseconds: 300),
                        _triggerAIEstimation);
                  },
                ),

                const SizedBox(height: 28),

                // Section Neige
                _buildSectionHeader(
                    'Profondeur de neige', Icons.ac_unit_rounded),
                const SizedBox(height: 12),

                SnowDepthInput(
                  initialValue: state.snowDepthCm,
                  onChanged: (value) {
                    context.read<NewReservationBloc>().add(
                          UpdateSnowDepth(value),
                        );
                    Future.delayed(const Duration(milliseconds: 500),
                        _triggerAIEstimation);
                  },
                ),

                const SizedBox(height: 28),

                // Estimation IA
                _buildSectionHeader('Estimation IA', Icons.smart_toy),
                const SizedBox(height: 12),
                const AIPriceEstimationWidget(),

                const SizedBox(height: 28),

                // Recapitulatif prix
                _buildSectionHeader(
                    'Recapitulatif', Icons.receipt_long_rounded),
                const SizedBox(height: 12),

                const PriceSummaryCard(showBreakdown: true),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
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
