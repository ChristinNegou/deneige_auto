import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase login;
  final RegisterUseCase register;
  final LogoutUseCase logout;
  final GetCurrentUserUseCase getCurrentUser;
  final ForgotPasswordUseCase forgotPassword;
  final ResetPasswordUseCase resetPassword;

  AuthBloc({
    required this.login,
    required this.register,
    required this.logout,
    required this.getCurrentUser,
    required this.forgotPassword,
    required this.resetPassword,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<ResetPasswordEvent>(_onResetPassword);
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    print('[DEBUG] AuthBloc - Login demandé pour: ${event.email}');
    emit(AuthLoading());

    final result = await login(event.email, event.password);

    result.fold(
          (failure) {
        print('[DEBUG] AuthBloc - Échec de la connexion: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
          (user) {
        print('[DEBUG] AuthBloc - Connexion réussie');
        print('[DEBUG] AuthBloc - User ID: ${user.id}');
        print('[DEBUG] AuthBloc - User Email: ${user.email}');
        print('[DEBUG] AuthBloc - User Role: ${user.role}');
        print('[DEBUG] AuthBloc - User Role toString: ${user.role.toString()}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event,
      Emitter<AuthState> emit,
      ) async {
    print('[DEBUG] AuthBloc - Inscription demandée pour: ${event.email}');
    print('[DEBUG] AuthBloc - Rôle demandé: ${event.role}');
    emit(AuthLoading());

    final result = await register(
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      phone: event.phone,
      role: event.role,
    );

    result.fold(
          (failure) {
        print('[DEBUG] AuthBloc - Échec de l\'inscription: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
          (user) {
        print('[DEBUG] AuthBloc - Inscription réussie');
        print('[DEBUG] AuthBloc - User ID: ${user.id}');
        print('[DEBUG] AuthBloc - User Email: ${user.email}');
        print('[DEBUG] AuthBloc - User Role: ${user.role}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await logout();

    result.fold(
          (failure) => emit(AuthError(message: failure.message)),
          (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onForgotPassword(
      ForgotPasswordEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await forgotPassword(event.email);

    result.fold(
          (failure) => emit(AuthError(message: failure.message)),
          (_) => emit(const ForgotPasswordSuccess()),
    );
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event,
      Emitter<AuthState> emit,
      ) async {
    print('[DEBUG] AuthBloc - Vérification du statut d\'authentification');
    emit(AuthLoading());

    final result = await getCurrentUser();

    result.fold(
          (failure) {
        print('[DEBUG] AuthBloc - Utilisateur non authentifié');
        emit(AuthUnauthenticated());
      },
          (user) {
        print('[DEBUG] AuthBloc - Utilisateur déjà authentifié');
        print('[DEBUG] AuthBloc - User Role: ${user.role}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onResetPassword(
      ResetPasswordEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await resetPassword(
      token: event.token,
      newPassword: event.newPassword,
    );

    result.fold(
          (failure) => emit(AuthError(message: failure.message)),
          (_) => emit(const ResetPasswordSuccess()),
    );
  }
}