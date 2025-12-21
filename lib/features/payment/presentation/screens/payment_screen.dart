import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
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
    return BlocProvider(
      create: (_) => sl<PaymentMethodsBloc>()..add(LoadPaymentMethods()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paiement'),
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: BlocConsumer<PaymentMethodsBloc, PaymentMethodsState>(
          listener: (context, state) {
            // Auto-select default payment method when loaded
            if (state.methods.isNotEmpty && _selectedPaymentMethod == null && !_useNewCard) {
              setState(() {
                _selectedPaymentMethod = state.defaultMethod ?? state.methods.first;
              });
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.methods.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Montant à payer
                  _buildAmountCard(),
                  const SizedBox(height: 32),

                  // Payment Method Selection
                  Text(
                    'Méthode de paiement',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Saved payment methods
                  if (state.methods.isNotEmpty) ...[
                    ...state.methods.map((method) => _buildPaymentMethodTile(method)),
                    const SizedBox(height: 12),
                  ],

                  // New card option
                  _buildNewCardTile(),

                  const SizedBox(height: 32),

                  // Security Info
                  _buildSecurityInfo(),

                  const SizedBox(height: 32),

                  // Payment Button
                  _buildPaymentButton(),

                  const SizedBox(height: 16),

                  // Card Logos
                  _buildCardLogos(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF7C3AED),
            Color(0xFF6D28D9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Montant total',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.amount.toStringAsFixed(2)} \$',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'CAD',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = !_useNewCard && _selectedPaymentMethod?.stripePaymentMethodId == method.stripePaymentMethodId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: RadioListTile<String>(
        value: method.stripePaymentMethodId ?? '',
        groupValue: _useNewCard ? '' : (_selectedPaymentMethod?.stripePaymentMethodId ?? ''),
        onChanged: (value) {
          setState(() {
            _useNewCard = false;
            _selectedPaymentMethod = method;
          });
        },
        activeColor: const Color(0xFF8B5CF6),
        title: Row(
          children: [
            Icon(
              Icons.credit_card,
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.black87,
                    ),
                  ),
                  if (method.isDefault)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Par défaut',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Expire ${method.expMonth.toString().padLeft(2, '0')}/${method.expYear}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildNewCardTile() {
    final isSelected = _useNewCard;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: RadioListTile<bool>(
        value: true,
        groupValue: _useNewCard,
        onChanged: (value) {
          setState(() {
            _useNewCard = true;
            _selectedPaymentMethod = null;
          });
        },
        activeColor: const Color(0xFF8B5CF6),
        title: Row(
          children: [
            Icon(
              Icons.add_card,
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              'Utiliser une nouvelle carte',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Paiement sécurisé',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('✓ Cryptage SSL 256-bit'),
          _buildInfoRow('✓ Conforme PCI DSS'),
          _buildInfoRow('✓ Propulsé par Stripe'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.blue[900],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    final canPay = (_selectedPaymentMethod != null || _useNewCard) && !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canPay ? _handlePayment : null,
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
            : Text(
                'Payer ${widget.amount.toStringAsFixed(2)} \$',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildCardLogos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCardLogo('Visa'),
        const SizedBox(width: 12),
        _buildCardLogo('Mastercard'),
        const SizedBox(width: 12),
        _buildCardLogo('Amex'),
      ],
    );
  }

  Widget _buildCardLogo(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Début du processus de paiement...');

      // 1. Create Payment Intent
      final paymentData = await _paymentService.createPaymentIntent(
        amount: widget.amount,
        reservationId: widget.reservationId,
      );

      print('✅ Payment Intent créé: ${paymentData['paymentIntentId']}');

      bool success = false;

      if (_useNewCard) {
        // Use new card - show Stripe Payment Sheet
        await _paymentService.initPaymentSheet(
          clientSecret: paymentData['clientSecret'],
          merchantDisplayName: 'Déneige Auto',
        );

        success = await _paymentService.confirmPayment(
          clientSecret: paymentData['clientSecret'],
        );
      } else if (_selectedPaymentMethod != null) {
        // Use saved card - confirm with payment method ID
        success = await _paymentService.confirmPaymentWithSavedCard(
          clientSecret: paymentData['clientSecret'],
          paymentMethodId: _selectedPaymentMethod!.stripePaymentMethodId!,
        );
      }

      if (success && mounted) {
        print('✅ Paiement réussi !');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement réussi !'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop({
          'success': true,
          'paymentIntentId': paymentData['paymentIntentId'],
        });
      } else if (mounted) {
        _showError('Paiement annulé');
      }
    } catch (e) {
      print('❌ Erreur de paiement: $e');
      if (mounted) {
        _showError('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
