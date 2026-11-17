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

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String? reservationId;

  const PaymentScreen({
    super.key,
    required this.amount,
    this.reservationId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  late PaymentService _paymentService;
  PaymentMethod? _selectedPaymentMethod;
  bool _useNewCard = false;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(dio: sl<DioClient>().dio);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => sl<PaymentMethodsBloc>()..add(LoadPaymentMethods()),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(l10n.payment_title, style: AppTheme.labelMedium),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: BlocConsumer<PaymentMethodsBloc, PaymentMethodsState>(
          listener: (context, state) {
            if (state.methods.isNotEmpty &&
                _selectedPaymentMethod == null &&
                !_useNewCard) {
              setState(() {
                _selectedPaymentMethod =
                    state.defaultMethod ?? state.methods.first;
              });
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.methods.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Montant
                  _buildAmountCard(),
                  const SizedBox(height: 32),

                  // Méthodes de paiement
                  _buildSectionTitle(l10n.reservation_paymentMethod),
                  const SizedBox(height: 12),

                  if (state.methods.isNotEmpty) ...[
                    ...state.methods
                        .map((method) => _buildPaymentMethodTile(method)),
                  ],

                  _buildNewCardTile(),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
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
                _buildSecureLine(l10n.payment_securePaymentDetails),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTheme.headlineSmall);
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
        ],
      ),
    );
  }

  /// Ligne de choix (carte enregistree ou nouvelle carte).
  Widget _buildChoiceTile({
    required bool isSelected,
    required VoidCallback onTap,
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
          onTap: onTap,
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

    return _buildChoiceTile(
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _useNewCard = false;
          _selectedPaymentMethod = method;
        });
      },
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
            l10n.payment_expires(
                '${method.expMonth.toString().padLeft(2, '0')}/${method.expYear}'),
            style: AppTheme.bodySmall.copyWith(
              color: method.isExpired ? AppTheme.error : AppTheme.textTertiary,
            ),
          ),
        ],
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

  Widget _buildSecureLine(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline_rounded,
            size: 14, color: AppTheme.textTertiary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTheme.labelSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    final l10n = AppLocalizations.of(context)!;
    final canPay =
        (_selectedPaymentMethod != null || _useNewCard) && !_isLoading;

    return FilledButton(
      onPressed: canPay ? _handlePayment : null,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.onPrimary),
            )
          : Text(
              l10n.payment_payAmount('${widget.amount.toStringAsFixed(2)} \$'),
            ),
    );
  }

  Future<void> _handlePayment() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final paymentData = await _paymentService.createPaymentIntent(
        amount: widget.amount,
        reservationId: widget.reservationId,
      );

      bool success = false;

      if (_useNewCard) {
        await _paymentService.initPaymentSheet(
          clientSecret: paymentData['clientSecret'],
          merchantDisplayName: l10n.appTitle,
        );
        success = await _paymentService.confirmPayment(
          clientSecret: paymentData['clientSecret'],
        );
      } else if (_selectedPaymentMethod != null) {
        success = await _paymentService.confirmPaymentWithSavedCard(
          clientSecret: paymentData['clientSecret'],
          paymentMethodId: _selectedPaymentMethod!.stripePaymentMethodId!,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                l10n.payment_success,
                style: TextStyle(color: AppTheme.onPrimary),
              ),
              backgroundColor: AppTheme.success),
        );
        Navigator.of(context).pop({
          'success': true,
          'paymentIntentId': paymentData['paymentIntentId'],
        });
      } else if (mounted) {
        _showError(l10n.payment_cancelled);
      }
    } catch (e) {
      if (mounted) {
        _showError(l10n.payment_failedRetry);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AppTheme.onPrimary),
        ),
        backgroundColor: AppTheme.error,
      ),
    );
  }
}
