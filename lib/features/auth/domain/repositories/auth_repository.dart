
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register(
      String email,
      String password,
      String name,
      {String? phone, UserRole role = UserRole.client}
      );
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, void>> forgotPassword(String email);
  Future<Either<Failure, void>> resetPassword(String token, String newPassword);

  Future<Either<Failure, User>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoUrl,
  });

  // Phone verification methods
  Future<Either<Failure, Map<String, dynamic>>> sendPhoneVerificationCode({
    required String phoneNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  });

  Future<Either<Failure, User>> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  });

  Future<Either<Failure, Map<String, dynamic>>> resendPhoneVerificationCode(
      String phoneNumber);
}