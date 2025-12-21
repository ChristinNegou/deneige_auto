import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';
import '../entities/payment_method.dart';
import '../entities/refund.dart';

abstract class PaymentRepository {
  /// Fetches payment history from reservations
  Future<Either<Failure, List<Payment>>> getPaymentHistory();

  /// Payment Methods Management
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods();
  Future<Either<Failure, void>> savePaymentMethod({
    required String paymentMethodId,
    bool setAsDefault = false,
  });
  Future<Either<Failure, void>> deletePaymentMethod(String paymentMethodId);
  Future<Either<Failure, void>> setDefaultPaymentMethod(String paymentMethodId);

  /// Refund Management
  Future<Either<Failure, Refund>> processRefund({
    required String reservationId,
    double? amount,
    required RefundReason reason,
    String? note,
  });
  Future<Either<Failure, Refund>> getRefundStatus(String refundId);
}
