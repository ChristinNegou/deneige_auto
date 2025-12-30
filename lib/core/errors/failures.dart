abstract class Failure {
  final String message;

  const Failure({required this.message});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Erreur serveur'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Erreur de connexion'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erreur de cache'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Erreur d\'authentification'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Erreur de validation'});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Non autorisé'});
}

class SuspendedFailure extends Failure {
  final String? reason;
  final DateTime? suspendedUntil;
  final String? suspendedUntilDisplay;

  const SuspendedFailure({
    super.message = 'Votre compte est suspendu',
    this.reason,
    this.suspendedUntil,
    this.suspendedUntilDisplay,
  });
}
