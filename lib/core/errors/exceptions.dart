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
    required super.message,
    super.statusCode,
  });
}

/// Exception levée lorsqu'une erreur réseau se produit
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
  });
}

/// Exception levée lorsque les données du cache sont invalides
class CacheException extends AppException {
  const CacheException({
    required super.message,
  });
}

/// Exception levée lors d'erreurs d'authentification
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
  });
}

/// Exception levée lors d'erreurs de validation
class ValidationException extends AppException {
  final Map<String, String>? errors;

  const ValidationException({
    required super.message,
    this.errors,
  });
}

/// Exception levée lorsqu'un utilisateur est suspendu
class SuspendedException extends AppException {
  final String? reason;
  final DateTime? suspendedUntil;
  final String? suspendedUntilDisplay;

  const SuspendedException({
    required super.message,
    this.reason,
    this.suspendedUntil,
    this.suspendedUntilDisplay,
    super.statusCode = 403,
  });

  factory SuspendedException.fromJson(Map<String, dynamic> json) {
    final details = json['suspensionDetails'] as Map<String, dynamic>?;
    return SuspendedException(
      message: json['message'] ?? 'Votre compte est suspendu',
      reason: details?['reason'],
      suspendedUntil: details?['suspendedUntil'] != null
          ? DateTime.tryParse(details!['suspendedUntil'].toString())
          : null,
      suspendedUntilDisplay: details?['suspendedUntilDisplay'],
    );
  }
}
