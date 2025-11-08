
/// Classe de base pour toutes les exceptions personnalisées
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Exception levée lorsqu'une erreur serveur se produit
class ServerException extends AppException {
  const ServerException({
    required String message,
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Exception levée lorsqu'une erreur réseau se produit
class NetworkException extends AppException {
  const NetworkException({
    required String message,
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Exception levée lorsque les données du cache sont invalides
class CacheException extends AppException {
  const CacheException({
    required String message,
  }) : super(message: message);
}

/// Exception levée lors d'erreurs d'authentification
class AuthException extends AppException {
  const AuthException({
    required String message,
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Exception levée lors d'erreurs de validation
class ValidationException extends AppException {
  final Map<String, String>? errors;

  const ValidationException({
    required String message,
    this.errors,
  }) : super(message: message);
}