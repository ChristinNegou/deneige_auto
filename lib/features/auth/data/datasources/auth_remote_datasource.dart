import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../service/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import '../models/login_response_model.dart';

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

  // Phone verification methods
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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final SecureStorageService secureStorage;

  AuthRemoteDataSourceImpl({
    required this.dio,
    required this.secureStorage,
  });

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
        await secureStorage.saveUserRole(loginResponse.user.role
            .toString()
            .split('.')
            .last);

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
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<UserModel> register(String email,
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
          'role': role
              .toString()
              .split('.')
              .last,
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
        await secureStorage.saveUserRole(loginResponse.user.role
            .toString()
            .split('.')
            .last);

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

  //  Méthode forgotPassword ajoutée
  @override
  Future<void> forgotPassword(String email) async {
    try {
      final response = await dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ??
              'Erreur lors de l\'envoi de l\'email',
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

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await dio.put(
        '/auth/reset-password/$token',
        data: {'password': newPassword},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ??
              'Erreur lors de la réinitialisation',
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

  // méthode mise à jour du profil
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

  // ============ PHONE VERIFICATION METHODS ============

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
          message: response.data['message'] ?? 'Erreur lors de l\'envoi du code',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AuthException(
          message: e.response?.data['message'] ?? 'Ce numéro ou email est déjà utilisé',
          statusCode: 409,
        );
      }
      if (e.response?.statusCode == 429) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Veuillez patienter avant de renvoyer',
          statusCode: 429,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

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

  @override
  Future<Map<String, dynamic>> resendPhoneVerificationCode(String phoneNumber) async {
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
          message: e.response?.data['message'] ?? 'Veuillez patienter avant de renvoyer',
          statusCode: 429,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }
}