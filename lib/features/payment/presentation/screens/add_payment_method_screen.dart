import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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
      appBar: AppBar(
        title: const Text('Ajouter une carte'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
        listener: (context, state) {
          if (state.isLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
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
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vos informations de paiement sont sécurisées par Stripe',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Card Input Label
                Text(
                  'Informations de la carte',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),

                // Stripe Card Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: CardField(
                    onCardChanged: (card) {
                      setState(() {
                        _cardComplete = card?.complete ?? false;
                      });
                    },
                    style: const TextStyle(fontSize: 16),
                    enablePostalCode: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Numéro de carte',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Set as default checkbox
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: CheckboxListTile(
                    value: _setAsDefault,
                    onChanged: (value) {
                      setState(() {
                        _setAsDefault = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF8B5CF6),
                    title: const Text('Définir comme méthode par défaut'),
                    subtitle: const Text(
                      'Cette carte sera utilisée pour vos futurs paiements',
                      style: TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                const SizedBox(height: 32),

                // Security Info
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vos données sont cryptées et sécurisées. Nous ne stockons jamais votre numéro de carte complet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_cardComplete && !_isLoading)
                        ? _handleAddCard
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Ajouter la carte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Accepted Cards
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Cartes acceptées',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCardBrand(Icons.credit_card, 'Visa'),
                          const SizedBox(width: 12),
                          _buildCardBrand(Icons.credit_card, 'Mastercard'),
                          const SizedBox(width: 12),
                          _buildCardBrand(Icons.credit_card, 'Amex'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBrand(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddCard() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_cardComplete) return;

    setState(() => _isLoading = true);

    try {
      // Create payment method with Stripe
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Save payment method via BLoC
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
