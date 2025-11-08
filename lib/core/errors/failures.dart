abstract class Failure {
  final String message;

  const Failure({required this.message});
}

class ServerFailure extends Failure {
  const ServerFailure({String message = 'Erreur serveur'}) : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Erreur de connexion'}) : super(message: message);
}

class CacheFailure extends Failure {
  const CacheFailure({String message = 'Erreur de cache'}) : super(message: message);
}

class AuthFailure extends Failure {
  const AuthFailure({String message = 'Erreur d\'authentification'}) : super(message: message);
}

class ValidationFailure extends Failure {
  const ValidationFailure({String message = 'Erreur de validation'}) : super(message: message);
}