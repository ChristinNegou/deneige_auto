import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de stockage pour les données d'authentification
/// Utilise un cache mémoire STATIQUE + SharedPreferences pour garantir la disponibilité immédiate
class SecureStorageService {
  static const String _tokenKey = 'auth_token_b64';
  static const String _refreshTokenKey = 'refresh_token_b64';
  static const String _userIdKey = 'user_id_b64';
  static const String _userRoleKey = 'user_role_b64';

  static SharedPreferences? _prefs;

  // Cache STATIQUE en mémoire pour accès immédiat (partagé entre toutes les instances)
  static String? _tokenCache;

  /// Initialise SharedPreferences si nécessaire
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Encode une valeur en base64
  String _encode(String value) {
    return base64Encode(utf8.encode(value));
  }

  /// Décode une valeur base64
  String? _decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur de décodage base64: $e');
      }
      return null;
    }
  }

  /// Sauvegarde le token d'authentification
  Future<void> saveToken(String token) async {
    // Sauvegarder immédiatement dans le cache mémoire
    _tokenCache = token;

    if (kDebugMode) {
      debugPrint(
          '✅ [SecureStorage] Token mis en cache mémoire (${token.length} chars)');
    }

    try {
      final prefs = await _getPrefs();
      final encoded = _encode(token);
      await prefs.setString(_tokenKey, encoded);

      if (kDebugMode) {
        debugPrint('✅ [SecureStorage] Token persisté dans SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [SecureStorage] Erreur persistance token: $e');
      }
      // Le cache mémoire reste valide même si la persistance échoue
    }
  }

  /// Récupère le token d'authentification
  Future<String?> getToken() async {
    // D'abord vérifier le cache mémoire
    if (_tokenCache != null && _tokenCache!.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '📖 [SecureStorage] Token depuis cache mémoire (${_tokenCache!.length} chars)');
      }
      return _tokenCache;
    }

    // Sinon, lire depuis SharedPreferences
    try {
      final prefs = await _getPrefs();
      final encoded = prefs.getString(_tokenKey);
      final token = _decode(encoded);

      if (token != null) {
        // Mettre en cache pour les prochains appels
        _tokenCache = token;
        if (kDebugMode) {
          debugPrint(
              '📖 [SecureStorage] Token depuis SharedPreferences (${token.length} chars)');
        }
      } else {
        if (kDebugMode) {
          debugPrint('📖 [SecureStorage] Aucun token trouvé');
        }
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [SecureStorage] Erreur lecture token: $e');
      }
      return null;
    }
  }

  /// Sauvegarde le refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_refreshTokenKey, _encode(refreshToken));
      if (kDebugMode) {
        debugPrint('✅ Refresh token sauvegardé');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la sauvegarde du refresh token: $e');
      }
      rethrow;
    }
  }

  /// Récupère le refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await _getPrefs();
      return _decode(prefs.getString(_refreshTokenKey));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la lecture du refresh token: $e');
      }
      return null;
    }
  }

  /// Sauvegarde l'ID de l'utilisateur
  Future<void> saveUserId(String userId) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_userIdKey, _encode(userId));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la sauvegarde du userId: $e');
      }
    }
  }

  /// Récupère l'ID de l'utilisateur
  Future<String?> getUserId() async {
    try {
      final prefs = await _getPrefs();
      return _decode(prefs.getString(_userIdKey));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la lecture du userId: $e');
      }
      return null;
    }
  }

  /// Sauvegarde le rôle de l'utilisateur
  Future<void> saveUserRole(String role) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_userRoleKey, _encode(role));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la sauvegarde du role: $e');
      }
    }
  }

  /// Récupère le rôle de l'utilisateur
  Future<String?> getUserRole() async {
    try {
      final prefs = await _getPrefs();
      return _decode(prefs.getString(_userRoleKey));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la lecture du role: $e');
      }
      return null;
    }
  }

  /// Supprime toutes les données d'authentification
  Future<void> deleteAll() async {
    // Vider le cache mémoire immédiatement
    _tokenCache = null;

    try {
      final prefs = await _getPrefs();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userRoleKey);
      if (kDebugMode) {
        debugPrint(
            '🗑️ [SecureStorage] Toutes les données auth supprimées (cache + storage)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [SecureStorage] Erreur suppression storage: $e');
      }
    }
  }

  /// Vérifie si un token existe
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
