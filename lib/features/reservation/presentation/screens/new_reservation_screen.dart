import 'package:deneige_auto/features/reservation/presentation/screens/steps/step1_vehicule_parking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/new_reservation_bloc.dart';
import '../bloc/new_reservation_event.dart';
import '../bloc/new_reservation_state.dart';
import 'steps/step2_datetime.dart';
import 'steps/step3_options.dart';
import 'steps/step4_summary.dart';

class NewReservationScreen extends StatelessWidget {
  const NewReservationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NewReservationBloc(
        getVehicles: sl(),
        getParkingSpots: sl(),
        createReservation: sl(),
      )..add(LoadInitialData()),
      child: const NewReservationView(),
    );
  }
}

class NewReservationView extends StatelessWidget {
  const NewReservationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewReservationBloc, NewReservationState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state.isSubmitted && state.reservationId != null) {
          Navigator.of(context).pushReplacementNamed(
            '/reservation/success',
            arguments: state.reservationId,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: SafeArea(
            child: Column(
              children: [
                _buildStepper(context, state),
                const Divider(height: 1),
                Expanded(
                  child: _buildStepContent(context, state),
                ),
                _buildNavigationButtons(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      NewReservationState state,
      ) {
    return AppBar(
      title: const Text('Nouvelle réservation'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _showCancelDialog(context),
      ),
      actions: [
        if (state.isLoadingData)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepper(BuildContext context, NewReservationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: _buildStepIndicator(
              context: context,
              index: index,
              currentStep: state.currentStep,
              isCompleted: index < state.currentStep,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepIndicator({
    required BuildContext context,
    required int index,
    required int currentStep,
    required bool isCompleted,
  }) {
    final theme = Theme.of(context);
    final isActive = index == currentStep;

    final stepIcons = [
      Icons.directions_car,
      Icons.access_time,
      Icons.tune,
      Icons.receipt_long,
    ];

    Color getColor() {
      if (isCompleted) return theme.primaryColor;
      if (isActive) return theme.primaryColor;
      return Colors.grey[300]!;
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? theme.primaryColor : Colors.transparent,
            border: Border.all(
              color: getColor(),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 20, color: theme.primaryColor)
                : Icon(
              stepIcons[index],
              size: 20,
              color: isActive ? Colors.white : Colors.grey[400],
            ),
          ),
        ),
        if (index < 3)
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isCompleted ? theme.primaryColor : Colors.grey[300],
            ),
          ),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context, NewReservationState state) {
    if (state.isLoadingData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des données...'),
          ],
        ),
      );
    }

    switch (state.currentStep) {
      case 0:
        return const Step1VehicleParkingScreen();
      case 1:
        return const Step2DateTimeScreen();
      case 2:
        return const Step3OptionsScreen();
      case 3:
        return const Step4SummaryScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons(
      BuildContext context,
      NewReservationState state,
      ) {
    final bloc = context.read<NewReservationBloc>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => bloc.add(GoToPreviousStep()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retour'),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: state.currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _getNextButtonOnPressed(context, state),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_getNextButtonText(state)),
                    const SizedBox(width: 8),
                    Icon(
                      state.currentStep == 3
                          ? Icons.check
                          : Icons.arrow_forward,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNextButtonText(NewReservationState state) {
    switch (state.currentStep) {
      case 0:
        return 'Continuer';
      case 1:
        return 'Continuer';
      case 2:
        return 'Voir le résumé';
      case 3:
        return 'Confirmer et payer';
      default:
        return 'Continuer';
    }
  }

  VoidCallback? _getNextButtonOnPressed(
      BuildContext context,
      NewReservationState state,
      ) {
    if (state.isLoading) return null;

    final bloc = context.read<NewReservationBloc>();

    switch (state.currentStep) {
      case 0:
        return state.canProceedStep1 ? () => bloc.add(GoToNextStep()) : null;
      case 1:
        return state.canProceedStep2 ? () => bloc.add(GoToNextStep()) : null;
      case 2:
        return () {
          bloc.add(CalculatePrice());
          bloc.add(GoToNextStep());
        };
      case 3:
        return state.canSubmit ? () => _showPaymentDialog(context) : null;
      default:
        return null;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler la réservation?'),
        content: const Text(
          'Êtes-vous sûr de vouloir quitter? Les informations saisies seront perdues.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Non, continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final bloc = context.read<NewReservationBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Méthode de paiement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _PaymentMethodTile(
              icon: Icons.credit_card,
              title: 'Carte de crédit',
              subtitle: 'Visa, Mastercard, Amex',
              onTap: () {
                Navigator.of(sheetContext).pop();
                bloc.add(const SubmitReservation('card'));
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Paiement sécurisé par Stripe',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}