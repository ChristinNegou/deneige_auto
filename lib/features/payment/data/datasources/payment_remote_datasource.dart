import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/refund.dart';
import '../models/payment_model.dart';
import '../models/payment_method_model.dart';
import '../models/refund_model.dart';

abstract class PaymentRemoteDataSource {
  /// Fetches payment history by getting reservations with payment data
  Future<List<PaymentModel>> getPaymentHistory();

  Future<List<PaymentMethodModel>> getPaymentMethods();
  Future<void> savePaymentMethod({
    required String paymentMethodId,
    bool setAsDefault = false,
  });
  Future<void> deletePaymentMethod(String paymentMethodId);
  Future<void> setDefaultPaymentMethod(String paymentMethodId);

  Future<RefundModel> processRefund({
    required String reservationId,
    double? amount,
    required RefundReason reason,
    String? note,
  });
  Future<RefundModel> getRefundStatus(String refundId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio dio;

  PaymentRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<PaymentModel>> getPaymentHistory() async {
    try {
      // Use existing reservations endpoint
      final response = await dio.get('/reservations');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> reservations;

        // Handle different response structures
        if (data is Map<String, dynamic>) {
          // L'API renvoie { success: true, reservations: [...] }
          if (data['reservations'] != null) {
            reservations = data['reservations'] as List;
          } else if (data['data'] != null) {
            reservations = data['data'] as List;
          } else {
            reservations = [];
          }
        } else if (data is List) {
          reservations = data;
        } else {
          reservations = [];
        }

        // Convert reservations to payments (only paid ones)
        final payments = <PaymentModel>[];
        for (final reservation in reservations) {
          if (reservation is Map<String, dynamic>) {
            final status = reservation['paymentStatus'];
            if (status == 'paid' ||
                status == 'refunded' ||
                status == 'partially_refunded') {
              payments.add(PaymentModel.fromReservation(reservation));
            }
          }
        }

        return payments;
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération de l\'historique',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(message: 'Délai de connexion dépassé');
      }
      throw NetworkException(message: e.message ?? 'Erreur réseau');
    }
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final response = await dio.get('/payments/payment-methods');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final methods = (response.data['paymentMethods'] as List)
            .map((json) => PaymentMethodModel.fromStripeJson(json))
            .toList();
        return methods;
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération des méthodes de paiement',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Erreur réseau');
    }
  }

  @override
  Future<void> savePaymentMethod({
    required String paymentMethodId,
    bool setAsDefault = false,
  }) async {
    try {
      final response = await dio.post(
        '/payments/payment-methods',
        data: {
          'paymentMethodId': paymentMethodId,
          'setAsDefault': setAsDefault,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de l\'ajout',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Erreur réseau');
    }
  }

  @override
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      final response =
          await dio.delete('/payments/payment-methods/$paymentMethodId');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de la suppression',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Erreur réseau');
    }
  }

  @override
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final response =
          await dio.patch('/payments/payment-methods/$paymentMethodId/default');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de la mise à jour',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Erreur réseau');
    }
  }

  @override
  Future<RefundModel> processRefund({
    required String reservationId,
    double? amount,
    required RefundReason reason,
    String? note,
  }) async {
    try {
      final response = await dio.post(
        '/payments/refunds',
        data: {
          'reservationId': reservationId,
          'amount': amount,
          'reason': _refundReasonToString(reason),
          'note': note,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return RefundModel.fromStripeJson(response.data['refund']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors du remboursement',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Erreur réseau');
    }
  }

  @override
  Future<RefundModel> getRefundStatus(String refundId) async {
    try {
      final response = await dio.get('/payments/refunds/$refundId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return RefundModel.fromStripeJson(response.data['refund']);
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération du statut',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Erreur réseau');
    }
  }

  String _refundReasonToString(RefundReason reason) {
    switch (reason) {
      case RefundReason.requestedByCustomer:
        return 'requested_by_customer';
      case RefundReason.duplicate:
        return 'duplicate';
      case RefundReason.fraudulent:
        return 'fraudulent';
      case RefundReason.serviceCanceled:
        return 'requested_by_customer';
      case RefundReason.other:
        return 'requested_by_customer';
    }
  }
}
