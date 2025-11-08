import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage.dart';
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
  Future<UserModel> getCurrentUser();
  Future<void> logout();
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
        await secureStorage.saveUserRole(loginResponse.user.role.toString().split('.').last);

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
        await secureStorage.saveUserRole(loginResponse.user.role.toString().split('.').last);

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
}