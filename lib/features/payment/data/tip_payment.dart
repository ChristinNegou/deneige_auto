import 'package:dio/dio.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/dio_client.dart';
import '../domain/repositories/payment_repository.dart';
import 'payment_service.dart';

/// Issue du paiement d'un pourboire.
sealed class TipPaymentResult {
  const TipPaymentResult();
}

/// Paye et transmis au deneigeur.
class TipPaid extends TipPaymentResult {
  final String? workerName;
  const TipPaid(this.workerName);
}

/// Le client a ferme la fenetre de paiement : rien n'est preleve.
class TipCancelled extends TipPaymentResult {
  const TipCancelled();
}

/// Carte refusee, ou serveur qui refuse le pourboire (raison a afficher).
class TipFailed extends TipPaymentResult {
  final String? message;
  const TipFailed(this.message);
}

/// Fait payer un pourboire au client (carte par defaut enregistree, sinon la
/// fenetre de paiement Stripe), puis l'enregistre : le serveur ne verse au
/// deneigeur qu'un pourboire reellement paye.
class TipPayment {
  final Dio _dio;
  final PaymentService _payments;
  final PaymentRepository _paymentRepository;

  TipPayment(
      {Dio? dio, PaymentService? payments, PaymentRepository? repository})
      : _dio = dio ?? sl<DioClient>().dio,
        _payments = payments ?? PaymentService(dio: sl<DioClient>().dio),
        _paymentRepository = repository ?? sl<PaymentRepository>();

  static String? _serverMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) return data['message'];
    }
    return null;
  }

  Future<TipPaymentResult> pay({
    required String reservationId,
    required double amount,
    required String merchantName,
  }) async {
    final Map<String, dynamic> intent;
    try {
      final response = await _dio.post(
        '/reservations/$reservationId/tip/intent',
        data: {'amount': amount},
      );
      intent = Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      return TipFailed(_serverMessage(e));
    }

    final clientSecret = intent['clientSecret'] as String;
    final paymentIntentId = intent['paymentIntentId'] as String;

    try {
      final methods = await _paymentRepository.getPaymentMethods();
      final defaultCard = methods.fold(
        (_) => null,
        (list) => list
            .where((m) => m.isDefault && m.stripePaymentMethodId != null)
            .firstOrNull,
      );

      final bool paid;
      if (defaultCard != null) {
        paid = await _payments.confirmPaymentWithSavedCard(
          clientSecret: clientSecret,
          paymentMethodId: defaultCard.stripePaymentMethodId!,
        );
      } else {
        await _payments.initPaymentSheet(
          clientSecret: clientSecret,
          merchantDisplayName: merchantName,
        );
        paid = await _payments.confirmPayment(clientSecret: clientSecret);
      }
      if (!paid) return const TipCancelled();
    } on PaymentDeclinedException catch (e) {
      return TipFailed(e.reason);
    } catch (_) {
      return const TipFailed(null);
    }

    try {
      final response = await _dio.post(
        '/reservations/$reservationId/tip',
        data: {'amount': amount, 'paymentIntentId': paymentIntentId},
      );
      return TipPaid(response.data['workerName'] as String?);
    } catch (e) {
      // Paiement fait : le serveur l'enregistre aussi a la reception de la
      // confirmation Stripe (webhook), le pourboire n'est donc pas perdu.
      return TipFailed(_serverMessage(e));
    }
  }
}
