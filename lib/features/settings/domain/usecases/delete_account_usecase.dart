import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/settings_repository.dart';

class DeleteAccountUseCase {
  final SettingsRepository repository;

  DeleteAccountUseCase(this.repository);

  Future<Either<Failure, void>> call(String password) async {
    return await repository.deleteAccount(password);
  }
}
