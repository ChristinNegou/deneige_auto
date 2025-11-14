import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../widgets/service_option_tile.dart';
import '../../widgets/snow_depth_input.dart';
import '../../widgets/price_summary_card.dart';

class Step3OptionsScreen extends StatelessWidget {
  const Step3OptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Options de service',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personnalisez votre service de déneigement',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Options de service
              ServiceOptionTile(
                option: ServiceOption.windowScraping,
                isSelected: state.selectedOptions.contains(
                  ServiceOption.windowScraping,
                ),
                price: 5.0,
                onToggle: () {
                  context.read<NewReservationBloc>().add(
                    const ToggleServiceOption(
                      ServiceOption.windowScraping,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              ServiceOptionTile(
                option: ServiceOption.doorDeicing,
                isSelected: state.selectedOptions.contains(
                  ServiceOption.doorDeicing,
                ),
                price: AppConfig.doorDeicingSurcharge,
                onToggle: () {
                  context.read<NewReservationBloc>().add(
                    const ToggleServiceOption(
                      ServiceOption.doorDeicing,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              ServiceOptionTile(
                option: ServiceOption.wheelClearance,
                isSelected: state.selectedOptions.contains(
                  ServiceOption.wheelClearance,
                ),
                price: AppConfig.wheelClearanceSurcharge,
                onToggle: () {
                  context.read<NewReservationBloc>().add(
                    const ToggleServiceOption(
                      ServiceOption.wheelClearance,
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Snow depth input
              SnowDepthInput(
                initialValue: state.snowDepthCm,
                onChanged: (value) {
                  context.read<NewReservationBloc>().add(
                    UpdateSnowDepth(value),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Price summary
              const PriceSummaryCard(showBreakdown: true),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}