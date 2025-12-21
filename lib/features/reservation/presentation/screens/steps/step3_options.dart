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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50.withOpacity(0.3),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec illustration
                _buildHeader(context),

                const SizedBox(height: 28),

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
        ),
      );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tune,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Étape 3 sur 4',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Options de service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personnalisez votre déneigement',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}