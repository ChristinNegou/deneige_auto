/// Classe de base pour les echecs metier (pattern Either).
/// Utilisee comme type Left dans `Either<Failure, T>` pour representer
/// un echec sans lever d'exception.
abstract class Failure {
  final String message;

  const Failure({required this.message});
}

/// Echec lie a une erreur serveur (5xx).
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Erreur serveur'});
}

/// Echec lie a un probleme de connexion reseau.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Erreur de connexion'});
}

/// Echec lie a une erreur de lecture/ecriture du cache local.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erreur de cache'});
}

/// Echec lie a l'authentification (identifiants invalides, session expiree).
class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Erreur d\'authentification'});
}

/// Echec lie a la validation des donnees saisies par l'utilisateur.
class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Erreur de validation'});
}

/// Echec de type 401/403 : acces non autorise.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Non autorisé'});
}

/// Echec indiquant que le compte utilisateur est suspendu.
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

/// Echec indiquant qu'une verification d'identite est requise avant de continuer.
class VerificationRequiredFailure extends Failure {
  final String? verificationStatus;

  const VerificationRequiredFailure({
    super.message = 'Vérification d\'identité requise',
    this.verificationStatus,
  });
}
