import 'package:deneige_auto/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../payment/presentation/screens/payment_screen.dart';
import '../bloc/new_reservation_bloc.dart';
import '../bloc/new_reservation_event.dart';
import '../bloc/new_reservation_state.dart';
import 'steps/step1_vehicule_parking.dart';
import 'steps/step2_location.dart';
import 'steps/step3_datetime.dart';
import 'steps/step4_options.dart';
import 'steps/step5_summary.dart';

class NewReservationScreen extends StatelessWidget {
  const NewReservationScreen({super.key});

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
  const NewReservationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewReservationBloc, NewReservationState>(
      listener: (context, state) {
        debugPrint(
            '🔄 [NewReservationView] State changed: isLoading=${state.isLoading}, isSubmitted=${state.isSubmitted}, error=${state.errorMessage}');

        if (state.errorMessage != null) {
          // Fermer le SnackBar de chargement
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          debugPrint('❌ [NewReservationView] Erreur: ${state.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        if (state.isSubmitted && state.reservationId != null) {
          // Fermer le SnackBar de chargement
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          debugPrint(
              '✅ [NewReservationView] Réservation créée: ${state.reservationId}');
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
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(l10n.reservation_new),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: List.generate(5, (index) {
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
    final isActive = index == currentStep;

    final stepIcons = [
      Icons.directions_car, // Step 1: Véhicule/Parking
      Icons.location_on, // Step 2: Localisation
      Icons.access_time, // Step 3: Date/Heure
      Icons.tune, // Step 4: Options
      Icons.receipt_long, // Step 5: Résumé
    ];

    Color getColor() {
      if (isCompleted) return AppTheme.textPrimary;
      if (isActive) return AppTheme.textPrimary;
      return AppTheme.border;
    }

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.textPrimary : Colors.transparent,
            border: Border.all(
              color: getColor(),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: 18, color: AppTheme.textPrimary)
                : Icon(
                    stepIcons[index],
                    size: 18,
                    color:
                        isActive ? AppTheme.background : AppTheme.textTertiary,
                  ),
          ),
        ),
        if (index < 4)
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: isCompleted ? AppTheme.textPrimary : AppTheme.border,
            ),
          ),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context, NewReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoadingData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.common_loading),
          ],
        ),
      );
    }

    switch (state.currentStep) {
      case 0:
        return const Step1VehicleParkingScreen();
      case 1:
        return const Step2LocationScreen();
      case 2:
        return const Step3DateTimeScreen();
      case 3:
        return const Step4OptionsScreen();
      case 4:
        return const Step5SummaryScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    NewReservationState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<NewReservationBloc>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppTheme.shadowMD,
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
                  child: Text(l10n.common_back),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: state.currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _getNextButtonOnPressed(context, state),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.background),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_getNextButtonText(state, l10n)),
                          const SizedBox(width: 8),
                          Icon(
                            state.currentStep == 4
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

  String _getNextButtonText(NewReservationState state, AppLocalizations l10n) {
    switch (state.currentStep) {
      case 3:
        return l10n.reservation_viewSummary;
      case 4:
        return l10n.reservation_confirmAndPay;
      default:
        return l10n.reservation_continue;
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
        return state.canProceedStep3 ? () => bloc.add(GoToNextStep()) : null;
      case 3:
        return () {
          bloc.add(CalculatePrice());
          bloc.add(GoToNextStep());
        };
      case 4:
        return state.canSubmit ? () => _showPaymentDialog(context) : null;
      default:
        return null;
    }
  }

  void _showCancelDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: Text(
          l10n.reservation_cancelNewTitle,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          l10n.reservation_cancelNewWarning,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.reservation_noContinue,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: Text(l10n.reservation_yesCancel),
          ),
        ],
      ),
    );
  }

  // Modifier la méthode _showPaymentDialog

  void _showPaymentDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<NewReservationBloc>();
    final state = bloc.state;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
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
                  color: AppTheme.textPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.reservation_paymentMethod,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _PaymentMethodTile(
              icon: Icons.credit_card,
              title: l10n.reservation_creditCard,
              subtitle: l10n.reservation_creditCardSubtitle,
              onTap: () async {
                Navigator.of(sheetContext).pop();

                // Ouvrir la page de paiement
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      amount: state.calculatedPrice ?? 0,
                      reservationId: null, // Sera mis à jour après création
                    ),
                  ),
                );

                // Si le paiement réussit
                if (result != null && result['success'] == true) {
                  debugPrint(
                      '✅ [NewReservationScreen] Paiement réussi, création réservation...');
                  debugPrint(
                      '✅ [NewReservationScreen] paymentIntentId: ${result['paymentIntentId']}');

                  // Montrer un indicateur de chargement
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.background,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(l10n.reservation_creatingReservation),
                          ],
                        ),
                        backgroundColor: AppTheme.primary,
                        duration: const Duration(seconds: 10),
                      ),
                    );
                  }

                  bloc.add(SubmitReservation(
                    'card',
                    paymentIntentId: result['paymentIntentId'],
                  ));
                } else {
                  debugPrint(
                      '❌ [NewReservationScreen] Paiement annulé ou échoué');
                }
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                l10n.reservation_securePayment,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
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
          color: AppTheme.surfaceContainer,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
