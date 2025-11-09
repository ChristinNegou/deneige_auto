import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de stockage sécurisé pour les données sensibles
/// Utilise le Keychain sur iOS et le KeyStore sur Android
class SecureStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
      const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );

  /// Sauvegarde le token d'authentification
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Récupère le token d'authentification
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Sauvegarde le refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Récupère le refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Sauvegarde l'ID de l'utilisateur
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Récupère l'ID de l'utilisateur
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Sauvegarde le rôle de l'utilisateur
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  /// Récupère le rôle de l'utilisateur
  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  /// Supprime toutes les données d'authentification
  Future<void> deleteAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userRoleKey);
  }

  /// Vérifie si un token existe
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}