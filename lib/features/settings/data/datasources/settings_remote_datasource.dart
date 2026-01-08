import 'package:dio/dio.dart';
import '../models/user_preferences_model.dart';

abstract class SettingsRemoteDataSource {
  Future<UserPreferencesModel> getPreferences();
  Future<UserPreferencesModel> updatePreferences(UserPreferencesModel preferences);
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
        throw Exception('Failed to load preferences');
      }
    } catch (e) {
      throw Exception('Error fetching preferences: $e');
    }
  }

  @override
  Future<UserPreferencesModel> updatePreferences(UserPreferencesModel preferences) async {
    try {
      final response = await dio.put(
        '/auth/preferences',
        data: preferences.toJson(),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserPreferencesModel.fromJson(response.data['preferences']);
      } else {
        throw Exception('Failed to update preferences');
      }
    } catch (e) {
      throw Exception('Error updating preferences: $e');
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
        final message = response.data['message'] ?? 'Failed to delete account';
        throw Exception(message);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Mot de passe incorrect');
      }
      throw Exception('Error deleting account: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }
}
