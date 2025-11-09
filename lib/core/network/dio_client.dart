import 'package:dio/dio.dart';
import '../../features/auth/presentation/bloc/auth_interceptor.dart';
import '../../service/secure_storage_service.dart';

/// Client Dio configuré pour l'application
class DioClient {
  // Pour Android Emulator, utilisez 10.0.2.2 au lieu de localhost
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  // Pour iOS Simulator, utilisez localhost
  // static const String _baseUrl = 'http://localhost:3000/api';

  // Pour un appareil physique, utilisez l'IP de votre ordinateur
  // static const String _baseUrl = 'http://192.168.1.XXX:3000/api';

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