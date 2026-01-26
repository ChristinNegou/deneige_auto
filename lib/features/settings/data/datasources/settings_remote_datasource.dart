import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_preferences_model.dart';

abstract class SettingsRemoteDataSource {
  Future<UserPreferencesModel> getPreferences();
  Future<UserPreferencesModel> updatePreferences(
      UserPreferencesModel preferences);
  Future<void> deleteAccount(String password);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final Dio dio;

  SettingsRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserPreferencesModel> getPreferences() async {
    try {
      final response = await dio.get('/auth/preferences');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserPreferencesModel.fromJson(response.data['preferences']);
      } else {
        throw const ServerException(
            message: 'Erreur lors du chargement des preferences');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement des preferences: $e');
    }
  }

  @override
  Future<UserPreferencesModel> updatePreferences(
      UserPreferencesModel preferences) async {
    try {
      final response = await dio.put(
        '/auth/preferences',
        data: preferences.toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserPreferencesModel.fromJson(response.data['preferences']);
      } else {
        throw const ServerException(
            message: 'Erreur lors de la mise a jour des preferences');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de la mise a jour des preferences: $e');
    }
  }

  @override
  Future<void> deleteAccount(String password) async {
    try {
      final response = await dio.delete(
        '/auth/account',
        data: {'password': password},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        final message = response.data['message'] ??
            'Erreur lors de la suppression du compte';
        throw ServerException(message: message);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de la suppression du compte: $e');
    }
  }

  AppException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String?;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Delai de connexion depasse. Verifiez votre connexion.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Impossible de se connecter au serveur.',
        );
      default:
        if (statusCode == 401) {
          return const ServerException(
            message: 'Mot de passe incorrect',
            statusCode: 401,
          );
        }
        return ServerException(
          message: message ?? 'Une erreur serveur est survenue.',
          statusCode: statusCode,
        );
    }
  }
}
