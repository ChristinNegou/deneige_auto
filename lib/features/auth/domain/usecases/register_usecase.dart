import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone, // Changé en nullable
    required UserRole role,
  }) async {
    return await repository.register(
      email,
      password,
      '$firstName $lastName',
      phone: phone,
      role: role,
    );
  }
}
