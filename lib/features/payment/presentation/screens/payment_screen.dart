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
          title: Text(
            l10n.payment_title,
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
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
                  const SizedBox(height: 28),

                  // Méthodes de paiement
                  _buildSectionTitle(l10n.reservation_paymentMethod),
                  const SizedBox(height: 12),

                  if (state.methods.isNotEmpty) ...[
                    ...state.methods
                        .map((method) => _buildPaymentMethodTile(method)),
                  ],

                  _buildNewCardTile(),

                  const SizedBox(height: 28),

                  // Info sécurité
                  _buildSecurityInfo(),

                  const SizedBox(height: 28),

                  // Bouton payer
                  _buildPaymentButton(),

                  const SizedBox(height: 16),

                  // Logos
                  _buildCardLogos(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildAmountCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            l10n.payment_amountToPay,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.background.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.amount.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.background,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '\$ CAD',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.background.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = !_useNewCard &&
        _selectedPaymentMethod?.stripePaymentMethodId ==
            method.stripePaymentMethodId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _useNewCard = false;
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.05)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: AppTheme.background)
                  : null,
            ),
            const SizedBox(width: 12),

            // Icône carte
            Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(Icons.credit_card,
                    size: 18, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.displayNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.common_default,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.payment_expires(
                        '${method.expMonth.toString().padLeft(2, '0')}/${method.expYear}'),
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCardTile() {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _useNewCard;

    return GestureDetector(
      onTap: () async {
        final result =
            await Navigator.pushNamed(context, AppRoutes.addPaymentMethod);
        if (result == true && mounted) {
          context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.05)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: AppTheme.background)
                  : null,
            ),
            const SizedBox(width: 12),

            // Icône
            Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.add, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),

            // Texte
            Text(
              l10n.payment_useNewCard,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: AppTheme.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.payment_securePayment,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.payment_securePaymentDetails,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.info.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    final l10n = AppLocalizations.of(context)!;
    final canPay =
        (_selectedPaymentMethod != null || _useNewCard) && !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canPay ? _handlePayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.background,
          disabledBackgroundColor: AppTheme.surfaceContainer,
          disabledForegroundColor: AppTheme.textTertiary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.background),
              )
            : Text(
                l10n.payment_payAmount(
                    '${widget.amount.toStringAsFixed(2)} \$'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildCardLogos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCardLogo('Visa'),
        const SizedBox(width: 8),
        _buildCardLogo('Mastercard'),
        const SizedBox(width: 8),
        _buildCardLogo('Amex'),
      ],
    );
  }

  Widget _buildCardLogo(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary),
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
                style: TextStyle(color: AppTheme.textPrimary),
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
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.error,
      ),
    );
  }
}
