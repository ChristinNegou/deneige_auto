import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/refund.dart';
import '../repositories/payment_repository.dart';

class ProcessRefundUseCase {
  final PaymentRepository repository;

  ProcessRefundUseCase(this.repository);

  Future<Either<Failure, Refund>> call({
    required String reservationId,
    double? amount,
    required RefundReason reason,
    String? note,
  }) async {
    // Validation
    if (reservationId.isEmpty) {
      return const Left(ValidationFailure(
        message: 'ID de réservation requis',
      ));
    }

    if (amount != null && amount <= 0) {
      return const Left(ValidationFailure(
        message: 'Le montant du remboursement doit être positif',
      ));
    }

    return await repository.processRefund(
      reservationId: reservationId,
      amount: amount,
      reason: reason,
      note: note,
    );
  }
}
