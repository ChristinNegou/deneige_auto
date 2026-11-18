import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide CardBrand;
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/payment_method.dart' show CardBrand;
import '../bloc/payment_methods_bloc.dart';
import '../widgets/card_brand_mark.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _cardComplete = false;
  bool _setAsDefault = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.addCard_title,
          style: AppTheme.labelMedium,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
        listener: (context, state) {
          if (state.isLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          if (state.errorMessage != null) {
            _showSnackBar(state.errorMessage!, isError: true);
          }

          if (state.successMessage != null) {
            _showSnackBar(state.successMessage!, isError: false);
            Navigator.pop(context, true);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardSection(),
                const SizedBox(height: 12),
                _buildAcceptedCards(),
                const SizedBox(height: 28),
                _buildDefaultOption(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubmitButton(),
              const SizedBox(height: 10),
              _buildSecurityInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.addCard_cardInfo,
          style: AppTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: CardField(
            onCardChanged: (card) {
              setState(() {
                _cardComplete = card?.complete ?? false;
              });
            },
            style: TextStyle(fontSize: 15, color: AppTheme.textPrimary),
            enablePostalCode: true,
            countryCode: 'CA',
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primary),
              ),
              filled: true,
              fillColor: AppTheme.surface,
              hintText: AppLocalizations.of(context)!.addCard_cardNumber,
              hintStyle: TextStyle(color: AppTheme.textTertiary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultOption() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        value: _setAsDefault,
        onChanged: (value) => setState(() => _setAsDefault = value),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          AppLocalizations.of(context)!.addCard_setDefault,
          style: AppTheme.labelLarge,
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.addCard_usedForFuture,
          style: AppTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSecureLine(
        '${l10n.addCard_encryptedSecure} ${l10n.addCard_protectedByStripe}');
  }

  Widget _buildSecureLine(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded,
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

  Widget _buildSubmitButton() {
    final canSubmit = _cardComplete && !_isLoading;

    return ElevatedButton(
      onPressed: canSubmit ? _handleAddCard : null,
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.onPrimary),
            )
          : Text(AppLocalizations.of(context)!.addCard_addBtn),
    );
  }

  /// Reseaux acceptes, affiches sous le champ de carte.
  Widget _buildAcceptedCards() {
    return const Row(
      children: [
        CardBrandMark(brand: CardBrand.visa, width: 36),
        SizedBox(width: 6),
        CardBrandMark(brand: CardBrand.mastercard, width: 36),
        SizedBox(width: 6),
        CardBrandMark(brand: CardBrand.amex, width: 36),
      ],
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AppTheme.onPrimary),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  Future<void> _handleAddCard() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (!_cardComplete) return;

    setState(() => _isLoading = true);

    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (mounted) {
        context.read<PaymentMethodsBloc>().add(
              SavePaymentMethod(
                paymentMethod.id,
                setAsDefault: _setAsDefault,
              ),
            );
      }
    } on StripeException catch (e) {
      // Erreur renvoyee par Stripe (carte refusee, cle invalide, mauvais mode...) :
      // on affiche son message, plus utile que le message generique.
      debugPrint('[AddCard] StripeException: ${e.error.code} - '
          '${e.error.message} (${e.error.stripeErrorCode})');
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar(
          e.error.localizedMessage ??
              e.error.message ??
              AppLocalizations.of(context)!.addCard_errorAdding,
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('[AddCard] Erreur: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.addCard_errorAdding,
            isError: true);
      }
    }
  }
}
