import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// États du BLoC d'authentification
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial
class AuthInitial extends AuthState {}

/// État de chargement (connexion, inscription, etc.)
class AuthLoading extends AuthState {}

/// État authentifié avec les informations de l'utilisateur
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// État non authentifié
class AuthUnauthenticated extends AuthState {}

/// État d'erreur
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// État de succès (pour des actions comme réinitialisation de mot de passe)
class AuthSuccess extends AuthState {
  final String message;

  const AuthSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

//  État de Succès du mot de passe oublié

class ForgotPasswordSuccess extends AuthState {
  const ForgotPasswordSuccess();

  @override
  List<Object> get props => [];
}

//  état pour le succès de la réinitialisation
class ResetPasswordSuccess extends AuthState {
  const ResetPasswordSuccess();

  @override
  List<Object> get props => [];
}
