import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../service/secure_storage_service.dart';

/// Callback pour notifier la suspension d'un utilisateur.
typedef SuspensionCallback = void Function(
    Map<String, dynamic> suspensionDetails);

/// Callback pour notifier la déconnexion forcée.
typedef LogoutCallback = void Function();

/// Intercepteur Dio pour la gestion des tokens JWT.
/// Ajoute automatiquement le Bearer token aux requêtes sortantes,
/// gère le rafraichissement transparent du token expiré (401),
/// la détection de comptes suspendus (403) et le rate limiting (429).
class AuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;

  /// Flag pour éviter les refresh tokens simultanés
  bool _isRefreshing = false;

  /// Completer pour les requêtes en attente pendant le refresh
  Completer<String?>? _refreshCompleter;

  /// Callback appelé quand un utilisateur est détecté comme suspendu
  static SuspensionCallback? onUserSuspended;

  /// Callback appelé quand l'utilisateur doit être déconnecté
  static LogoutCallback? onForceLogout;

  /// Stream controller pour les événements de suspension
  static final StreamController<Map<String, dynamic>> _suspensionController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream controller pour les événements de déconnexion forcée
  static final StreamController<void> _logoutController =
      StreamController<void>.broadcast();

  /// Stream des événements de suspension
  static Stream<Map<String, dynamic>> get suspensionStream =>
      _suspensionController.stream;

  /// Stream des événements de déconnexion forcée
  static Stream<void> get logoutStream => _logoutController.stream;

  AuthInterceptor({required this.secureStorage});

  // --- Injection du token dans les requêtes ---

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Récupérer le token
      final token = await secureStorage.getToken();

      // Ajouter le token dans les headers si disponible
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          debugPrint('🔐 Token ajouté aux headers pour ${options.path}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Aucun token disponible pour ${options.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la récupération du token: $e');
      }
    }

    handler.next(options);
  }

  // --- Gestion des erreurs HTTP ---

  /// Intercepte les erreurs pour gérer : suspension (403), rate limiting (429),
  /// expiration du token (401) avec tentative de refresh transparent,
  /// et les erreurs de connexion réseau.
  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // Gestion de la suspension utilisateur (403 USER_SUSPENDED)
    if (err.response?.statusCode == 403 &&
        err.response?.data['code'] == 'USER_SUSPENDED') {
      // Supprimer les tokens locaux
      await secureStorage.deleteAll();

      // Notifier via le stream et le callback
      final suspensionDetails = err.response?.data as Map<String, dynamic>;
      _suspensionController.add(suspensionDetails);
      onUserSuspended?.call(suspensionDetails);

      return handler.next(err);
    }

    // Gestion du rate limiting (429 Too Many Requests)
    if (err.response?.statusCode == 429) {
      final retryAfter = err.response?.data['retryAfter'] ?? 60;
      err = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: 'Trop de requêtes. Réessayez dans $retryAfter secondes.',
      );
      return handler.next(err);
    }

    // Gestion de l'expiration du token (401 Unauthorized)
    if (err.response?.statusCode == 401) {
      // Ne pas tenter de refresh pour les routes d'auth
      final path = err.requestOptions.path;
      if (path.contains('/auth/login') ||
          path.contains('/auth/refresh-token') ||
          path.contains('/auth/register')) {
        return handler.next(err);
      }

      try {
        final newToken = await _handleTokenRefresh(err.requestOptions.baseUrl);

        if (newToken != null) {
          // Réessayer la requête originale avec le nouveau token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';

          final dio = Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ));
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } else {
          // Token refresh échoué - NE PAS forcer la déconnexion automatique
          // L'utilisateur pourra se reconnecter manuellement si nécessaire
          if (kDebugMode) {
            debugPrint(
                '⚠️ [AuthInterceptor] Refresh token échoué, mais pas de déconnexion forcée');
          }
        }
      } catch (e) {
        // Si le rafraîchissement échoue, NE PAS forcer la déconnexion
        if (kDebugMode) {
          debugPrint('⚠️ [AuthInterceptor] Erreur refresh: $e');
        }
      }
    }

    // Gestion des erreurs réseau
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      err = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error:
            'Connexion au serveur trop lente. Vérifiez votre connexion internet.',
      );
    } else if (err.type == DioExceptionType.connectionError) {
      err = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error:
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      );
    }

    return handler.next(err);
  }

  // --- Rafraîchissement du token ---

  /// Gère le rafraîchissement du token de manière thread-safe.
  /// Si un refresh est déjà en cours, les requêtes suivantes attendent son résultat
  /// via un [Completer] partagé pour éviter les appels multiples simultanés.
  Future<String?> _handleTokenRefresh(String baseUrl) async {
    // Si un refresh est déjà en cours, attendre son résultat
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await secureStorage.getRefreshToken();

      if (refreshToken == null) {
        _refreshCompleter?.complete(null);
        return null;
      }

      final result = await _refreshToken(refreshToken, baseUrl);
      _refreshCompleter?.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter?.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Rafraîchit le token d'authentification
  Future<String?> _refreshToken(String refreshToken, String baseUrl) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.post(
        '$baseUrl/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newToken = response.data['token'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;

        if (newToken != null) {
          await secureStorage.saveToken(newToken);
        }
        if (newRefreshToken != null) {
          await secureStorage.saveRefreshToken(newRefreshToken);
        }

        return newToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Intercepteur de journalisation des requêtes et réponses HTTP.
/// Actif uniquement en mode debug. Filtre automatiquement les données
/// sensibles (mots de passe, tokens, clés API) dans les logs.
class LoggingInterceptor extends Interceptor {
  /// Clés sensibles à masquer dans les logs.
  static const _sensitiveKeys = [
    'password',
    'token',
    'refreshToken',
    'accessToken',
    'authorization',
    'Authorization',
    'secret',
    'apiKey',
    'api_key',
    'creditCard',
    'cardNumber',
  ];

  /// Filtre récursivement les données sensibles d'un objet Map.
  /// Remplace les valeurs des clés sensibles par '***FILTERED***'.
  dynamic _filterSensitiveData(dynamic data) {
    if (data == null) return null;
    if (data is! Map) return '[DATA]';

    final filtered = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.toString();
      if (_sensitiveKeys
          .any((k) => key.toLowerCase().contains(k.toLowerCase()))) {
        filtered[key] = '***FILTERED***';
      } else if (entry.value is Map) {
        filtered[key] = _filterSensitiveData(entry.value);
      } else {
        filtered[key] = entry.value;
      }
    }
    return filtered;
  }

  /// Filtre les headers sensibles
  Map<String, dynamic> _filterHeaders(Map<String, dynamic> headers) {
    final filtered = <String, dynamic>{};
    for (final entry in headers.entries) {
      if (_sensitiveKeys
          .any((k) => entry.key.toLowerCase().contains(k.toLowerCase()))) {
        filtered[entry.key] = '***FILTERED***';
      } else {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
      debugPrint('📤 Headers: ${_filterHeaders(options.headers)}');
      debugPrint('📦 Data: ${_filterSensitiveData(options.data)}');
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      // Ne pas logger les données de réponse (peuvent contenir des tokens)
      debugPrint('📥 Data: [Response received]');
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      debugPrint('🔥 Message: ${err.message}');
      // Ne pas logger les détails de la réponse d'erreur
      debugPrint('📛 Response: [Error response]');
    }
    return super.onError(err, handler);
  }
}
