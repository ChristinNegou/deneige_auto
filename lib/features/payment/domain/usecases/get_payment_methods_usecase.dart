import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_method.dart';
import '../repositories/payment_repository.dart';

class GetPaymentMethodsUseCase {
  final PaymentRepository repository;

  GetPaymentMethodsUseCase(this.repository);

  Future<Either<Failure, List<PaymentMethod>>> call() async {
    return await repository.getPaymentMethods();
  }
}
