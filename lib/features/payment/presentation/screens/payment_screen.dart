import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String? reservationId;

  const PaymentScreen({
    Key? key,
    required this.amount,
    this.reservationId,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(dio: sl<DioClient>().dio);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Montant à payer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Montant total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.amount.toStringAsFixed(2)} \$ CAD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Informations
            Container(
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
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Informations de paiement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('✓ Paiement sécurisé via Stripe'),
                  _buildInfoRow('✓ Cartes Visa, Mastercard, Amex acceptées'),
                  _buildInfoRow('✓ Vos informations sont cryptées'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Payer ${widget.amount.toStringAsFixed(2)} \$',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logos des cartes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCardLogo('💳 Visa'),
                const SizedBox(width: 12),
                _buildCardLogo('💳 Mastercard'),
                const SizedBox(width: 12),
                _buildCardLogo('💳 Amex'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.blue[900],
        ),
      ),
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
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Début du processus de paiement...');

      // 1. Créer un Payment Intent
      final paymentData = await _paymentService.createPaymentIntent(
        amount: widget.amount,
        reservationId: widget.reservationId,
      );

      print('✅ Payment Intent créé: ${paymentData['paymentIntentId']}');

      // 2. Initialiser le Payment Sheet
      await _paymentService.initPaymentSheet(
        clientSecret: paymentData['clientSecret'],
        merchantDisplayName: 'Déneige Auto',
      );

      print('✅ Payment Sheet initialisé');

      // 3. Présenter le Payment Sheet et confirmer
      final success = await _paymentService.confirmPayment(
        clientSecret: paymentData['clientSecret'],
      );

      if (success && mounted) {
        print('✅ Paiement réussi !');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement réussi ! ✅'),
            backgroundColor: Colors.green,
          ),
        );

        // Retourner le Payment Intent ID
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