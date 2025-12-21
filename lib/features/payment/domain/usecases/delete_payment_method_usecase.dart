import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/payment_repository.dart';

class DeletePaymentMethodUseCase {
  final PaymentRepository repository;

  DeletePaymentMethodUseCase(this.repository);

  Future<Either<Failure, void>> call(String paymentMethodId) async {
    if (paymentMethodId.isEmpty) {
      return const Left(ValidationFailure(
        message: 'ID de méthode de paiement requis',
      ));
    }

    return await repository.deletePaymentMethod(paymentMethodId);
  }
}
