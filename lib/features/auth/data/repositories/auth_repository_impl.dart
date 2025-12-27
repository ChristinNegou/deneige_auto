
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> register(String email,
      String password,
      String name, {
        String? phone,
        UserRole role = UserRole.client,
      }) async {
    try {
      final nameParts = name.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final user = await remoteDataSource.register(
        email,
        password,
        firstName,
        lastName,
        phone: phone,
        role: role,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      // ✅ Utiliser remoteDataSource au lieu de _dioClient
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      await remoteDataSource.getCurrentUser();
      return const Right(true);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String token,
      String newPassword) async {
    try {
      await remoteDataSource.resetPassword(token, newPassword);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    try {
      final user = await remoteDataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Erreur inattendue lors de la mise à jour du profil'));
    }
  }

  // ============ PHONE VERIFICATION ============

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendPhoneVerificationCode({
    required String phoneNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final result = await remoteDataSource.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final user = await remoteDataSource.verifyPhoneCode(
        phoneNumber: phoneNumber,
        code: code,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> resendPhoneVerificationCode(
      String phoneNumber) async {
    try {
      final result =
          await remoteDataSource.resendPhoneVerificationCode(phoneNumber);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }
}