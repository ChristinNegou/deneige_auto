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

  /// Confirmer le paiement avec Payment Sheet (nouvelle carte)
  Future<bool> confirmPayment({
    required String clientSecret,
  }) async {
    try {
      // Confirmer le paiement avec Stripe Payment Sheet
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      print('Erreur Stripe: ${e.error.message}');
      return false;
    } catch (e) {
      print('Erreur: $e');
      return false;
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
      print('Erreur Stripe: ${e.error.message}');
      throw Exception(e.error.message ?? 'Erreur de paiement');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur de paiement: $e');
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