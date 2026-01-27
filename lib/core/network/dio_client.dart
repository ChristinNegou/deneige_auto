import 'package:dio/dio.dart';
import '../../features/auth/presentation/bloc/auth_interceptor.dart';
import '../../service/secure_storage_service.dart';
import '../config/app_config.dart';
import '../services/locale_service.dart';

/// Client Dio configuré pour l'application
class DioClient {
  // URL de base dynamique depuis AppConfig
  static String get _baseUrl => AppConfig.apiBaseUrl;

  late final Dio _dio;

  DioClient({
    required SecureStorageService secureStorage,
    required LocaleService localeService,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Seuls les status 2xx sont considérés comme succès
          // Les 4xx et 5xx lèveront des DioException pour un traitement approprié
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    // Ajout des intercepteurs
    _dio.interceptors.addAll([
      LocaleInterceptor(localeService: localeService),
      AuthInterceptor(secureStorage: secureStorage),
      RetryInterceptor(dio: _dio),
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}

/// Intercepteur pour réessayer les requêtes échouées
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Ne pas réessayer pour certains types d'erreurs
    if (_shouldNotRetry(err)) {
      return handler.next(err);
    }

    // Récupérer le nombre de tentatives actuel
    final extra = err.requestOptions.extra;
    int retryCount = extra['retryCount'] ?? 0;

    if (retryCount < maxRetries) {
      retryCount++;
      err.requestOptions.extra['retryCount'] = retryCount;

      // Attendre avant de réessayer (backoff exponentiel)
      final delay = retryDelay * retryCount;
      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // Continuer avec l'erreur si le retry échoue aussi
        if (e is DioException) {
          return handler.next(e);
        }
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  bool _shouldNotRetry(DioException err) {
    // Ne pas réessayer les erreurs client (4xx)
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return true;
    }

    // Ne pas réessayer les annulations
    if (err.type == DioExceptionType.cancel) {
      return true;
    }

    // Ne pas réessayer les erreurs de certificat
    if (err.type == DioExceptionType.badCertificate) {
      return true;
    }

    return false;
  }
}

/// Intercepteur pour ajouter le header Accept-Language aux requêtes
class LocaleInterceptor extends Interceptor {
  final LocaleService localeService;

  LocaleInterceptor({required this.localeService});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = localeService.locale.languageCode;
    handler.next(options);
  }
}
