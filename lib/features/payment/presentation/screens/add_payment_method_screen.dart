import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/payment_methods_bloc.dart';

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
        title: const Text('Ajouter une carte'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
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
                _buildSecurityBanner(),
                const SizedBox(height: 24),
                _buildCardSection(),
                const SizedBox(height: 16),
                _buildDefaultOption(),
                const SizedBox(height: 24),
                _buildSecurityInfo(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 24),
                _buildAcceptedCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement sécurisé',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vos informations sont protégées par Stripe',
                  style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations de la carte',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: CardField(
            onCardChanged: (card) {
              setState(() {
                _cardComplete = card?.complete ?? false;
              });
            },
            style: const TextStyle(fontSize: 15),
            enablePostalCode: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Numéro de carte',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultOption() {
    return GestureDetector(
      onTap: () => setState(() => _setAsDefault = !_setAsDefault),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _setAsDefault ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _setAsDefault ? AppTheme.primary : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: _setAsDefault
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Définir comme méthode par défaut',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Utilisée pour vos futurs paiements',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Row(
      children: [
        Icon(Icons.verified_user_outlined, size: 16, color: Colors.green[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Données cryptées et sécurisées. Numéro de carte jamais stocké.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _cardComplete && !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? _handleAddCard : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Ajouter la carte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildAcceptedCards() {
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600]),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleAddCard() async {
    if (!_formKey.currentState!.validate()) return;
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
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    }
  }
}
