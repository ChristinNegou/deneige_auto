import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Contrat du repository d'authentification (couche domaine).
/// Définit les opérations disponibles pour l'auth, le profil,
/// la vérification téléphonique et la gestion de la photo de profil.
/// Retourne [Either<Failure, T>] pour une gestion fonctionnelle des erreurs.
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register(
      String email, String password, String name,
      {String? phone, UserRole role = UserRole.client});
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

  // --- Vérification téléphonique ---
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

  // --- Photo de profil ---
  Future<Either<Failure, User>> uploadProfilePhoto(File photoFile);
  Future<Either<Failure, User>> deleteProfilePhoto();
  Future<Either<Failure, bool>> checkPhoneAvailability(String phoneNumber);

  // --- Changement de numéro de téléphone ---
  Future<Either<Failure, Map<String, dynamic>>> sendPhoneChangeCode(
      String phoneNumber);
  Future<Either<Failure, User>> verifyPhoneChangeCode({
    required String phoneNumber,
    required String code,
  });
}
