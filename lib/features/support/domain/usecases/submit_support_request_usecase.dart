import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/support_request.dart';
import '../repositories/support_repository.dart';

class SubmitSupportRequestUseCase {
  final SupportRepository repository;

  SubmitSupportRequestUseCase(this.repository);

  Future<Either<Failure, void>> call(SupportRequest request) async {
    return await repository.submitSupportRequest(request);
  }
}
