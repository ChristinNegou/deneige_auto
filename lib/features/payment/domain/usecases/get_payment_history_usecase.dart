import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentHistoryUseCase {
  final PaymentRepository repository;

  GetPaymentHistoryUseCase(this.repository);

  /// Retrieves payment history from completed/paid reservations
  /// Converts reservation data into Payment entities
  Future<Either<Failure, List<Payment>>> call() async {
    return await repository.getPaymentHistory();
  }
}
