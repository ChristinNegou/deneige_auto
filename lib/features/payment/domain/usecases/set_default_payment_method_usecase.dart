import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/payment_repository.dart';

class SetDefaultPaymentMethodUseCase {
  final PaymentRepository repository;

  SetDefaultPaymentMethodUseCase(this.repository);

  Future<Either<Failure, void>> call(String paymentMethodId) async {
    if (paymentMethodId.isEmpty) {
      return const Left(ValidationFailure(
        message: 'ID de méthode de paiement requis',
      ));
    }

    return await repository.setDefaultPaymentMethod(paymentMethodId);
  }
}
