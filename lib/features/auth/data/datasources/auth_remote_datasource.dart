import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../service/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import '../models/login_response_model.dart';

/// Contrat de la source de données distante pour l'authentification.
/// Définit toutes les opérations réseau liées à l'auth, la vérification
/// téléphonique et la gestion du profil.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(
    String email,
    String password,
    String firstName,
    String lastName, {
    String? phone,
    UserRole role,
  });
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoUrl,
  });

  Future<UserModel> getCurrentUser();
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String newPassword);

  // --- Vérification téléphonique ---
  Future<Map<String, dynamic>> sendPhoneVerificationCode({
    required String phoneNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  });
  Future<UserModel> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  });
  Future<Map<String, dynamic>> resendPhoneVerificationCode(String phoneNumber);

  // --- Photo de profil ---
  Future<UserModel> uploadProfilePhoto(File photoFile);
  Future<UserModel> deleteProfilePhoto();
  Future<bool> checkPhoneAvailability(String phoneNumber);

  // --- Changement de numéro de téléphone ---
  Future<Map<String, dynamic>> sendPhoneChangeCode(String phoneNumber);
  Future<UserModel> verifyPhoneChangeCode({
    required String phoneNumber,
    required String code,
  });
}

/// Implémentation de la source de données distante pour l'authentification.
/// Communique avec l'API backend via Dio pour toutes les opérations d'auth.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final SecureStorageService secureStorage;

  AuthRemoteDataSourceImpl({
    required this.dio,
    required this.secureStorage,
  });

  // --- Connexion ---

  /// Authentifie l'utilisateur avec email/mot de passe.
  /// Sauvegarde les tokens JWT et les infos utilisateur dans le stockage sécurisé.
  /// Lance une [AuthException] si les identifiants sont invalides,
  /// une [SuspendedException] si le compte est suspendu.
  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponseModel.fromJson(response.data);

        // Sauvegarder le token et les infos utilisateur
        await secureStorage.saveToken(loginResponse.token);
        if (loginResponse.refreshToken != null) {
          await secureStorage.saveRefreshToken(loginResponse.refreshToken!);
        }
        await secureStorage.saveUserId(loginResponse.user.id);
        await secureStorage
            .saveUserRole(loginResponse.user.role.toString().split('.').last);

        return loginResponse.user;
      } else {
        throw ServerException(
          message: 'Erreur lors de la connexion',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException(
          message: 'Email ou mot de passe incorrect',
          statusCode: 401,
        );
      }
      // Vérifier si l'utilisateur est suspendu
      if (e.response?.statusCode == 403 &&
          e.response?.data['code'] == 'USER_SUSPENDED') {
        throw SuspendedException.fromJson(e.response!.data);
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  // --- Inscription ---

  /// Inscrit un nouvel utilisateur et sauvegarde ses tokens.
  /// Lance une [AuthException] (409) si l'email est déjà utilisé.
  @override
  Future<UserModel> register(
    String email,
    String password,
    String firstName,
    String lastName, {
    String? phone,
    UserRole role = UserRole.client,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phone,
          'role': role.toString().split('.').last,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final loginResponse = LoginResponseModel.fromJson(response.data);

        // Sauvegarder le token et les infos utilisateur
        await secureStorage.saveToken(loginResponse.token);
        if (loginResponse.refreshToken != null) {
          await secureStorage.saveRefreshToken(loginResponse.refreshToken!);
        }
        await secureStorage.saveUserId(loginResponse.user.id);
        await secureStorage
            .saveUserRole(loginResponse.user.role.toString().split('.').last);

        return loginResponse.user;
      } else {
        throw ServerException(
          message: 'Erreur lors de l\'inscription',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AuthException(
          message: 'Cet email est déjà utilisé',
          statusCode: 409,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  // --- Utilisateur courant ---

  /// Récupère le profil de l'utilisateur connecté depuis le serveur.
  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dio.get('/auth/me');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération de l\'utilisateur',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException(
          message: 'Session expirée',
          statusCode: 401,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  // --- Déconnexion ---

  /// Déconnecte l'utilisateur côté serveur et supprime les tokens locaux.
  /// Les tokens locaux sont supprimés même en cas d'erreur réseau.
  @override
  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
      // Supprimer tous les tokens
      await secureStorage.deleteAll();
    } on DioException catch (e) {
      // Même en cas d'erreur, supprimer les tokens locaux
      await secureStorage.deleteAll();
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  // --- Mot de passe oublié / Réinitialisation ---

  /// Envoie un email de réinitialisation de mot de passe.
  @override
  Future<void> forgotPassword(String email) async {
    try {
      final response = await dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message:
              response.data['message'] ?? 'Erreur lors de l\'envoi de l\'email',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Email invalide',
          statusCode: 400,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  /// Réinitialise le mot de passe avec un token reçu par email.
  @override
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await dio.put(
        '/auth/reset-password/$token',
        data: {'password': newPassword},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message:
              response.data['message'] ?? 'Erreur lors de la réinitialisation',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw ServerException(
          message: e.response?.data['message'] ??
              'le lien de récupération est expiré',
          statusCode: 400,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  // --- Mise à jour du profil ---

  /// Met à jour les informations du profil utilisateur.
  /// Seuls les champs non-null sont envoyés au serveur.
  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      final response = await dio.put(
        '/auth/update-profile',
        data: data,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(
          message: response.data['message'] ??
              'Erreur lors de la mise à jour du profil',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(
        message: e.response?.data['message'] ?? 'Erreur réseau',
      );
    }
  }

  // --- Vérification téléphonique (inscription) ---

  /// Envoie un code de vérification SMS pour valider le numéro lors de l'inscription.
  /// Retourne les détails incluant un devCode en environnement de développement.
  @override
  Future<Map<String, dynamic>> sendPhoneVerificationCode({
    required String phoneNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final response = await dio.post(
        '/phone/send-code',
        data: {
          'phoneNumber': phoneNumber,
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'phoneNumber': response.data['phoneNumber'],
          'devCode': response.data['devCode'],
          'simulated': response.data['simulated'] ?? false,
        };
      } else {
        throw ServerException(
          message:
              response.data['message'] ?? 'Erreur lors de l\'envoi du code',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AuthException(
          message: e.response?.data['message'] ??
              'Ce numéro ou email est déjà utilisé',
          statusCode: 409,
        );
      }
      if (e.response?.statusCode == 429) {
        throw ServerException(
          message: e.response?.data['message'] ??
              'Veuillez patienter avant de renvoyer',
          statusCode: 429,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  /// Vérifie le code SMS et finalise la création du compte.
  /// Sauvegarde les tokens si le compte est créé avec succès.
  @override
  Future<UserModel> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final response = await dio.post(
        '/phone/verify-code',
        data: {
          'phoneNumber': phoneNumber,
          'code': code,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Compte créé avec succès
        if (response.data['accountCreated'] == true) {
          final token = response.data['token'] as String;
          final userData = response.data['user'] as Map<String, dynamic>;

          // Sauvegarder le token et les infos utilisateur
          await secureStorage.saveToken(token);
          await secureStorage.saveUserId(userData['id'] as String);
          await secureStorage.saveUserRole(userData['role'] as String);

          return UserModel.fromJson(userData);
        } else {
          // Juste une vérification sans création de compte
          throw ServerException(
            message: 'Vérification réussie mais aucun compte créé',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de la vérification',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw AuthException(
          message: e.response?.data['message'] ?? 'Code invalide',
          statusCode: 400,
        );
      }
      if (e.response?.statusCode == 409) {
        throw AuthException(
          message: e.response?.data['message'] ?? 'Cet email est déjà utilisé',
          statusCode: 409,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  /// Renvoie le code de vérification SMS (soumis au rate limiting 429).
  @override
  Future<Map<String, dynamic>> resendPhoneVerificationCode(
      String phoneNumber) async {
    try {
      final response = await dio.post(
        '/phone/resend-code',
        data: {'phoneNumber': phoneNumber},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'devCode': response.data['devCode'],
          'simulated': response.data['simulated'] ?? false,
        };
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors du renvoi',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw ServerException(
          message: e.response?.data['message'] ??
              'Veuillez patienter avant de renvoyer',
          statusCode: 429,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  // --- Photo de profil ---

  /// Téléverse une photo de profil en multipart/form-data.
  @override
  Future<UserModel> uploadProfilePhoto(File photoFile) async {
    try {
      final fileName = photoFile.path.split('/').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoFile.path,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '/auth/upload-profile-photo',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de l\'upload',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(
        message: e.response?.data['message'] ?? 'Erreur réseau',
      );
    }
  }

  /// Supprime la photo de profil de l'utilisateur.
  @override
  Future<UserModel> deleteProfilePhoto() async {
    try {
      final response = await dio.delete('/auth/delete-profile-photo');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de la suppression',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(
        message: e.response?.data['message'] ?? 'Erreur réseau',
      );
    }
  }

  /// Vérifie si un numéro de téléphone est disponible (non déjà associé à un compte).
  @override
  Future<bool> checkPhoneAvailability(String phoneNumber) async {
    try {
      final response = await dio.post(
        '/auth/check-phone',
        data: {'phoneNumber': phoneNumber},
      );

      if (response.statusCode == 200) {
        return response.data['available'] as bool;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return false;
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  // --- Changement de numéro de téléphone ---

  /// Envoie un code SMS pour valider un changement de numéro de téléphone.
  @override
  Future<Map<String, dynamic>> sendPhoneChangeCode(String phoneNumber) async {
    try {
      final response = await dio.post(
        '/phone/send-change-code',
        data: {'phoneNumber': phoneNumber},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'phoneNumber': response.data['phoneNumber'],
          'devCode': response.data['devCode'],
          'simulated': response.data['simulated'] ?? false,
        };
      } else {
        throw ServerException(
          message:
              response.data['message'] ?? 'Erreur lors de l\'envoi du code',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AuthException(
          message: e.response?.data['message'] ?? 'Ce numéro est déjà utilisé',
          statusCode: 409,
        );
      }
      if (e.response?.statusCode == 429) {
        throw ServerException(
          message: e.response?.data['message'] ??
              'Veuillez patienter avant de renvoyer',
          statusCode: 429,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  /// Vérifie le code SMS et applique le changement de numéro.
  @override
  Future<UserModel> verifyPhoneChangeCode({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final response = await dio.post(
        '/phone/verify-change-code',
        data: {
          'phoneNumber': phoneNumber,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Erreur lors de la vérification',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw AuthException(
          message: e.response?.data['message'] ?? 'Code invalide',
          statusCode: 400,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }
}
