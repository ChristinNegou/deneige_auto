import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/payment_repository.dart';

class SavePaymentMethodUseCase {
  final PaymentRepository repository;

  SavePaymentMethodUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String paymentMethodId,
    bool setAsDefault = false,
  }) async {
    // Validation
    if (paymentMethodId.isEmpty) {
      return const Left(ValidationFailure(
        message: 'ID de méthode de paiement requis',
      ));
    }

    return await repository.savePaymentMethod(
      paymentMethodId: paymentMethodId,
      setAsDefault: setAsDefault,
    );
  }
}
