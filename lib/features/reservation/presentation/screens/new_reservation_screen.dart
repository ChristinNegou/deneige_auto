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
      title: Text(l10n.reservation_new, style: AppTheme.labelMedium),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
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

  /// En-tete de progression : numero d'etape, nom de l'etape et barre segmentee.
  Widget _buildStepper(BuildContext context, NewReservationState state) {
    const totalSteps = 5;
    final l10n = AppLocalizations.of(context)!;
    final stepTitles = [
      l10n.reservation_stepVehicle,
      l10n.reservation_stepLocation,
      l10n.reservation_stepSchedule,
      l10n.reservation_stepOptions,
      l10n.reservation_stepSummary,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reservation_stepCounter(state.currentStep + 1, totalSteps),
            style: AppTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          Text(stepTitles[state.currentStep], style: AppTheme.headlineLarge),
          const SizedBox(height: 14),
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: 4,
                  margin:
                      EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: index <= state.currentStep
                        ? AppTheme.primary
                        : AppTheme.border,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
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

    final isLastStep = state.currentStep == 4;
    final buttonContent = state.isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.onPrimary,
            ),
          )
        : Text(_getNextButtonText(state, l10n));
    final onNext = _getNextButtonOnPressed(context, state);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (state.currentStep > 0) ...[
              SizedBox(
                width: AppTheme.buttonHeight,
                height: AppTheme.buttonHeight,
                child: OutlinedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => bloc.add(GoToPreviousStep()),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    semanticLabel: l10n.common_back,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // L'orange est reserve a l'action qui engage le client : payer.
            Expanded(
              child: isLastStep
                  ? FilledButton(onPressed: onNext, child: buttonContent)
                  : ElevatedButton(onPressed: onNext, child: buttonContent),
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
                                color: AppTheme.onPrimary,
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
