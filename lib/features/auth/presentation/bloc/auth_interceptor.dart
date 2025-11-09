import 'package:dio/dio.dart';
import '../../../../service/secure_storage_service.dart';
/// Intercepteur pour ajouter le token d'authentification aux requêtes
class AuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;

  AuthInterceptor({required this.secureStorage});

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // Récupérer le token
    final token = await secureStorage.getToken();

    // Ajouter le token dans les headers si disponible
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Gestion de l'expiration du token (401 Unauthorized)
    if (err.response?.statusCode == 401) {
      try {
        // Tentative de rafraîchissement du token
        final refreshToken = await secureStorage.getRefreshToken();

        if (refreshToken != null) {
          final newToken = await _refreshToken(refreshToken, err.requestOptions.baseUrl);

          if (newToken != null) {
            // Sauvegarder le nouveau token
            await secureStorage.saveToken(newToken);

            // Réessayer la requête originale avec le nouveau token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            final response = await Dio().fetch(options);
            return handler.resolve(response);
          }
        }
      } catch (e) {
        // Si le rafraîchissement échoue, supprimer tous les tokens
        await secureStorage.deleteAll();
      }
    }

    return handler.next(err);
  }

  /// Rafraîchit le token d'authentification
  Future<String?> _refreshToken(String refreshToken, String baseUrl) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '$baseUrl/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        return response.data['token'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Intercepteur pour logger les requêtes et réponses
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
    print('📤 Headers: ${options.headers}');
    print('📦 Data: ${options.data}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    print('📥 Data: ${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    print('🔥 Message: ${err.message}');
    print('📛 Response: ${err.response?.data}');
    return super.onError(err, handler);
  }
}