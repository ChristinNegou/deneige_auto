import 'package:dio/dio.dart';
import '../../features/auth/presentation/bloc/auth_interceptor.dart';
import '../../service/secure_storage_service.dart';
import '../config/app_config.dart';

/// Client Dio configuré pour l'application
class DioClient {
  // URL de base dynamique depuis AppConfig
  static String get _baseUrl => '${AppConfig.apiBaseUrl}/api';

  late final Dio _dio;

  DioClient({required SecureStorageService secureStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Ajout des intercepteurs
    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage: secureStorage),
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}
