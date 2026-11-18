import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_methods_bloc.dart';
import '../../data/payment_service.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/card_brand_mark.dart';

/// Resultat de l'etape qui suit le paiement (creation de la reservation).
class PaidOutcome {
  final String? reservationId;
  final String? errorMessage;

  const PaidOutcome.success(String this.reservationId) : errorMessage = null;
  const PaidOutcome.failure(String this.errorMessage) : reservationId = null;

  bool get isSuccess => reservationId != null;
}

enum _Phase { choosing, paying, confirming, failed }

/// Paiement d'une reservation : choix de la carte, paiement, puis creation de
/// la reservation via [onPaid] sans quitter l'ecran. Un refus de la banque est
/// explique sur place ; un echec apres paiement a son propre ecran.
class PaymentScreen extends StatefulWidget {
  final double amount;
  final String? reservationId;

  /// Ce qui est paye, affiche sous le montant (ex. "Déneigement du 20 nov.").
  final String? description;

  /// Appele une fois le paiement accepte. Sans lui, l'ecran se ferme et
  /// renvoie {success, paymentIntentId}.
  final Future<PaidOutcome> Function(String paymentIntentId)? onPaid;

  const PaymentScreen({
    super.key,
    required this.amount,
    this.reservationId,
    this.description,
    this.onPaid,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late PaymentService _paymentService;
  PaymentMethod? _selectedPaymentMethod;
  bool _useNewCard = false;

  _Phase _phase = _Phase.choosing;

  /// Raison du dernier refus de paiement (null : pas de refus).
  String? _declineReason;
  bool _declined = false;

  /// Message du serveur si la reservation n'a pas pu etre creee.
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(dio: sl<DioClient>().dio);
  }

  bool get _busy => _phase == _Phase.paying || _phase == _Phase.confirming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => sl<PaymentMethodsBloc>()..add(LoadPaymentMethods()),
      child: PopScope(
        // On ne quitte pas pendant que la banque ou le serveur repond
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(l10n.payment_title, style: AppTheme.labelMedium),
            centerTitle: true,
            leading: _busy
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context, false),
                  ),
          ),
          body: _phase == _Phase.failed
              ? _buildFailure(context)
              : BlocConsumer<PaymentMethodsBloc, PaymentMethodsState>(
                  listener: (context, state) => _autoSelect(state),
                  builder: (context, state) {
                    if (state.isLoading && state.methods.isEmpty) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.primary),
                      );
                    }
                    return _buildChoice(context, state);
                  },
                ),
          bottomNavigationBar:
              _phase == _Phase.failed ? null : _buildBottomBar(context),
        ),
      ),
    );
  }

  /// Carte par defaut (ou premiere valide) preselectionnee ; jamais une
  /// carte expiree, qui serait refusee a coup sur.
  void _autoSelect(PaymentMethodsState state) {
    if (_selectedPaymentMethod != null || _useNewCard) return;
    final usable = state.methods.where((m) => !m.isExpired).toList();
    if (usable.isEmpty) return;
    final preferred = state.defaultMethod;
    setState(() {
      _selectedPaymentMethod =
          preferred != null && !preferred.isExpired ? preferred : usable.first;
    });
  }

  Widget _buildChoice(BuildContext context, PaymentMethodsState state) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountCard(),
          const SizedBox(height: 28),
          if (_declined) ...[
            _buildDeclinedPanel(l10n),
            const SizedBox(height: 20),
          ],
          Text(l10n.reservation_paymentMethod, style: AppTheme.headlineSmall),
          const SizedBox(height: 12),
          ...state.methods.map(_buildPaymentMethodTile),
          _buildNewCardTile(),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.payment_amountToPay,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.amount.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: AppTheme.onPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '\$ CAD',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          if (widget.description != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.description!,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Refus de la banque : la raison, puis quoi faire. L'ecran reste ouvert.
  Widget _buildDeclinedPanel(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.payment_declinedTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _declineReason ?? l10n.payment_declinedGeneric,
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.payment_declinedHelp,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne de choix (carte enregistree ou nouvelle carte).
  Widget _buildChoiceTile({
    required bool isSelected,
    required VoidCallback? onTap,
    required Widget leading,
    required Widget content,
    bool showRadio = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: _busy ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(child: content),
                if (showRadio)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textTertiary,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: AppTheme.onPrimary)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = !_useNewCard &&
        _selectedPaymentMethod?.stripePaymentMethodId ==
            method.stripePaymentMethodId;
    final expired = method.isExpired;

    return Opacity(
      opacity: expired ? 0.55 : 1,
      child: _buildChoiceTile(
        isSelected: isSelected,
        showRadio: !expired,
        onTap: expired
            ? null
            : () => setState(() {
                  _useNewCard = false;
                  _selectedPaymentMethod = method;
                  _declined = false;
                }),
        leading: CardBrandMark(brand: method.brand),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  method.displayNumber,
                  style: AppTheme.labelLarge.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (method.isDefault) ...[
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: l10n.common_default,
                    color: AppTheme.textSecondary,
                    small: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              expired
                  ? l10n.payment_expiredCard
                  : l10n.payment_expires(
                      '${method.expMonth.toString().padLeft(2, '0')}/${method.expYear}'),
              style: AppTheme.bodySmall.copyWith(
                color: expired ? AppTheme.error : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCardTile() {
    final l10n = AppLocalizations.of(context)!;

    return _buildChoiceTile(
      isSelected: _useNewCard,
      showRadio: false,
      onTap: () async {
        final result =
            await Navigator.pushNamed(context, AppRoutes.addPaymentMethod);
        if (result == true && mounted) {
          // La nouvelle carte devient le choix par defaut au rechargement
          setState(() {
            _selectedPaymentMethod = null;
            _declined = false;
          });
          context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
        }
      },
      leading: Container(
        width: 44,
        height: 29,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Icon(Icons.add_rounded, size: 20, color: AppTheme.primary),
      ),
      content: Text(l10n.payment_useNewCard, style: AppTheme.labelLarge),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentButton(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.payment_securePaymentDetails,
                    textAlign: TextAlign.center,
                    style: AppTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    final l10n = AppLocalizations.of(context)!;
    final canPay = (_selectedPaymentMethod != null || _useNewCard) && !_busy;

    return FilledButton(
      onPressed: canPay ? _handlePayment : null,
      child: _busy
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.onPrimary),
                ),
                const SizedBox(width: 10),
                Text(_phase == _Phase.confirming
                    ? l10n.payment_confirmingReservation
                    : l10n.payment_processing),
              ],
            )
          : Text(
              l10n.payment_payAmount(widget.amount.toStringAsFixed(2)),
            ),
    );
  }

  Future<void> _handlePayment() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _phase = _Phase.paying;
      _declined = false;
    });

    String? paymentIntentId;
    try {
      final paymentData = await _paymentService.createPaymentIntent(
        amount: widget.amount,
        reservationId: widget.reservationId,
      );

      bool paid = false;
      if (_useNewCard) {
        await _paymentService.initPaymentSheet(
          clientSecret: paymentData['clientSecret'],
          merchantDisplayName: l10n.appTitle,
        );
        paid = await _paymentService.confirmPayment(
          clientSecret: paymentData['clientSecret'],
        );
      } else if (_selectedPaymentMethod != null) {
        paid = await _paymentService.confirmPaymentWithSavedCard(
          clientSecret: paymentData['clientSecret'],
          paymentMethodId: _selectedPaymentMethod!.stripePaymentMethodId!,
        );
      }

      // Le client a ferme la fenetre de paiement : rien a signaler
      if (!paid) {
        if (mounted) setState(() => _phase = _Phase.choosing);
        return;
      }
      paymentIntentId = paymentData['paymentIntentId'] as String?;
    } on PaymentDeclinedException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.choosing;
          _declined = true;
          _declineReason = e.reason;
        });
      }
      return;
    } catch (e) {
      // Reseau ou serveur injoignable : aucun montant preleve
      if (mounted) {
        setState(() {
          _phase = _Phase.choosing;
          _declined = true;
          _declineReason = l10n.payment_failedRetry;
        });
      }
      return;
    }

    if (!mounted || paymentIntentId == null) return;

    final onPaid = widget.onPaid;
    if (onPaid == null) {
      Navigator.of(context)
          .pop({'success': true, 'paymentIntentId': paymentIntentId});
      return;
    }

    setState(() => _phase = _Phase.confirming);
    final outcome = await onPaid(paymentIntentId);
    if (!mounted) return;

    if (outcome.isSuccess) {
      Navigator.of(context).pop(outcome);
    } else {
      setState(() {
        _phase = _Phase.failed;
        _failureMessage = outcome.errorMessage;
      });
    }
  }

  /// Paiement accepte mais reservation non creee : on dit ce qui se passe
  /// pour l'argent, et comment obtenir de l'aide.
  Widget _buildFailure(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppTheme.error, size: 30),
            ),
            const SizedBox(height: 20),
            Text(l10n.payment_creationFailedTitle,
                style: AppTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              _failureMessage ?? '',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.payment_creationFailedHelp,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.payment_backToSummary),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.helpSupport),
                child: Text(l10n.payment_contactSupport),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
