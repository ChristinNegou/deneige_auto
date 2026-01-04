import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
  final UserRole role;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
  });

  @override
  List<Object?> get props =>
      [email, password, firstName, lastName, phone, role];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent(this.email);

  @override
  List<Object> get props => [email];
}

class ResetPasswordEvent extends AuthEvent {
  final String token;
  final String newPassword;

  const ResetPasswordEvent({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [token, newPassword];
}

class UpdateProfile extends AuthEvent {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? photoUrl;

  const UpdateProfile({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [firstName, lastName, phoneNumber, photoUrl];
}

/// Envoie un code de vérification SMS au numéro de téléphone
class SendPhoneVerificationCode extends AuthEvent {
  final String phoneNumber;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String role;

  const SendPhoneVerificationCode({
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  @override
  List<Object?> get props =>
      [phoneNumber, email, password, firstName, lastName, role];
}

/// Vérifie le code SMS entré par l'utilisateur
class VerifyPhoneCode extends AuthEvent {
  final String phoneNumber;
  final String code;

  const VerifyPhoneCode({
    required this.phoneNumber,
    required this.code,
  });

  @override
  List<Object?> get props => [phoneNumber, code];
}

/// Renvoie un nouveau code de vérification
class ResendPhoneVerificationCode extends AuthEvent {
  final String phoneNumber;

  const ResendPhoneVerificationCode({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// Déconnexion forcée (ex: suspension détectée en cours de session)
class ForcedLogout extends AuthEvent {
  final String reason;
  final String? suspensionReason;
  final DateTime? suspendedUntil;
  final String? suspendedUntilDisplay;

  const ForcedLogout({
    required this.reason,
    this.suspensionReason,
    this.suspendedUntil,
    this.suspendedUntilDisplay,
  });

  @override
  List<Object?> get props =>
      [reason, suspensionReason, suspendedUntil, suspendedUntilDisplay];
}
