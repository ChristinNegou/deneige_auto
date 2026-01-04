import 'package:dartz/dartz.dart';
import 'package:deneige_auto/core/errors/failures.dart';

/// Helper pour creer des resultats Either de succes
Either<Failure, T> success<T>(T value) => Right(value);

/// Helper pour creer des resultats Either d'echec
Either<Failure, T> failure<T>(Failure f) => Left(f);

/// Failures communes pour les tests
const serverFailure = ServerFailure(message: 'Erreur serveur');
const networkFailure = NetworkFailure(message: 'Pas de connexion');
const authFailure = AuthFailure(message: 'Non authentifie');
const validationFailure = ValidationFailure(message: 'Donnees invalides');
const unauthorizedFailure = UnauthorizedFailure(message: 'Non autorise');

/// SuspendedFailure pour les tests
SuspendedFailure createSuspendedFailure({
  String message = 'Votre compte est suspendu',
  String? reason,
  DateTime? suspendedUntil,
}) {
  return SuspendedFailure(
    message: message,
    reason: reason,
    suspendedUntil: suspendedUntil ?? DateTime.now().add(const Duration(days: 7)),
  );
}
