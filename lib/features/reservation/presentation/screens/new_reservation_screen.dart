import 'package:deneige_auto/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_routes.dart';
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
import 'reservation_success_screen.dart';

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
        // Pendant le paiement, l'ecran de paiement affiche lui-meme l'issue
        final isOnTop = ModalRoute.of(context)?.isCurrent ?? true;
        if (state.errorMessage != null && isOnTop) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
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
        ? SizedBox(
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
      decoration: BoxDecoration(
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
        return state.canSubmit ? () => _openPayment(context) : null;
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

  /// Paiement puis creation de la reservation, sur l'ecran de paiement.
  /// En cas de succes, la confirmation remplace tout le parcours.
  Future<void> _openPayment(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<NewReservationBloc>();
    final state = bloc.state;
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en_CA'
        : 'fr_CA';
    final departure = state.departureDateTime;

    final outcome = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          amount: state.calculatedPrice ?? 0,
          description: departure == null
              ? null
              : l10n.payment_forReservation(
                  '${DateFormat('EEE d MMM', locale).format(departure)}, '
                  '${DateFormat.Hm(locale).format(departure)}'),
          onPaid: (paymentIntentId) =>
              _createReservation(bloc, paymentIntentId),
        ),
      ),
    );

    if (outcome is PaidOutcome && outcome.isSuccess && context.mounted) {
      final done = bloc.state;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.reservationSuccess,
        (route) => route.isFirst,
        arguments: ReservationSuccessArgs(
          reservationId: outcome.reservationId!,
          amount: done.calculatedPrice,
          departure: done.departureDateTime,
          readyBy: done.deadlineTime,
          address: done.locationAddress,
        ),
      );
    }
  }

  /// Envoie la reservation payee et attend la reponse du serveur.
  Future<PaidOutcome> _createReservation(
    NewReservationBloc bloc,
    String paymentIntentId,
  ) async {
    final result = bloc.stream.firstWhere(
      (s) => !s.isLoading && (s.isSubmitted || s.errorMessage != null),
    );
    bloc.add(SubmitReservation('card', paymentIntentId: paymentIntentId));
    final s = await result;
    return s.isSubmitted && s.reservationId != null
        ? PaidOutcome.success(s.reservationId!)
        : PaidOutcome.failure(s.errorMessage ?? '');
  }
}
