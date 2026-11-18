import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  final Dio dio;

  PaymentService({required this.dio});

  /// Créer un Payment Intent côté backend
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String? reservationId,
  }) async {
    try {
      final response = await dio.post(
        '/payments/create-intent',
        data: {
          'amount': amount,
          'reservationId': reservationId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'clientSecret': response.data['clientSecret'],
          'paymentIntentId': response.data['paymentIntentId'],
        };
      } else {
        throw Exception('Erreur lors de la création du Payment Intent');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Confirmer le paiement avec Payment Sheet (nouvelle carte).
  /// Retourne false si le client ferme la feuille ; leve
  /// [PaymentDeclinedException] si la banque refuse.
  Future<bool> confirmPayment({
    required String clientSecret,
  }) async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      throw PaymentDeclinedException.fromStripe(e);
    }
  }

  /// Confirmer le paiement avec une carte sauvegardée
  Future<bool> confirmPaymentWithSavedCard({
    required String clientSecret,
    required String paymentMethodId,
  }) async {
    try {
      // Confirm payment intent with saved payment method
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethodId,
          ),
        ),
      );
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      throw PaymentDeclinedException.fromStripe(e);
    }
  }

  /// Initialiser le Payment Sheet
  Future<void> initPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName,
        style: ThemeMode.light,
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF2196F3),
          ),
        ),
      ),
    );
  }
}

/// Paiement refuse par la banque ou Stripe, avec la raison a montrer au client
/// (ex. "Votre carte a été refusée."), deja traduite par Stripe.
class PaymentDeclinedException implements Exception {
  final String? reason;
  const PaymentDeclinedException(this.reason);

  factory PaymentDeclinedException.fromStripe(StripeException e) {
    debugPrint('Paiement refuse: ${e.error.code} ${e.error.declineCode}');
    return PaymentDeclinedException(
        e.error.localizedMessage ?? e.error.message);
  }

  @override
  String toString() => 'PaymentDeclinedException($reason)';
}
