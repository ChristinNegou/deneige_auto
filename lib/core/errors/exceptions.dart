/// Classe de base pour toutes les exceptions personnalisees de l'application.
/// Chaque sous-classe represente un type d'erreur specifique (serveur, reseau, auth, etc.).
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

/// Exception levee lors d'une erreur serveur (5xx).
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
  });
}

/// Exception levee lors d'une erreur reseau (pas de connexion, timeout).
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
  });
}

/// Exception levee lorsque les donnees du cache sont invalides ou absentes.
class CacheException extends AppException {
  const CacheException({
    required super.message,
  });
}

/// Exception levee lors d'erreurs d'authentification (token invalide, session expiree).
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
  });
}

/// Exception levee lors d'erreurs de validation des donnees saisies.
/// [errors] contient les messages d'erreur par champ.
class ValidationException extends AppException {
  final Map<String, String>? errors;

  const ValidationException({
    required super.message,
    this.errors,
  });
}

/// Exception levee lorsqu'un compte utilisateur est suspendu.
/// Contient la raison et la date de fin de suspension le cas echeant.
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
