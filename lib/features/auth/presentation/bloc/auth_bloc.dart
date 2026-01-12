import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../service/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'auth_event.dart';
import 'auth_interceptor.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase login;
  final RegisterUseCase register;
  final LogoutUseCase logout;
  final GetCurrentUserUseCase getCurrentUser;
  final ForgotPasswordUseCase forgotPassword;
  final ResetPasswordUseCase resetPassword;
  final UpdateProfileUseCase updateProfile;
  final AuthRepository authRepository;

  StreamSubscription<Map<String, dynamic>>? _suspensionSubscription;

  // Stocke l'utilisateur courant pour pouvoir réémettre AuthAuthenticated après des erreurs temporaires
  User? _currentUser;

  AuthBloc({
    required this.login,
    required this.register,
    required this.logout,
    required this.getCurrentUser,
    required this.forgotPassword,
    required this.resetPassword,
    required this.updateProfile,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<ResetPasswordEvent>(_onResetPassword);
    on<UpdateProfile>(_onUpdateProfile);
    on<SendPhoneVerificationCode>(_onSendPhoneVerificationCode);
    on<VerifyPhoneCode>(_onVerifyPhoneCode);
    on<ResendPhoneVerificationCode>(_onResendPhoneVerificationCode);
    on<ForcedLogout>(_onForcedLogout);
    on<UploadProfilePhoto>(_onUploadProfilePhoto);
    on<DeleteProfilePhoto>(_onDeleteProfilePhoto);
    on<CheckPhoneAvailability>(_onCheckPhoneAvailability);
    on<SendPhoneChangeCode>(_onSendPhoneChangeCode);
    on<VerifyPhoneChangeCode>(_onVerifyPhoneChangeCode);

    // Écouter les événements de suspension de l'intercepteur
    _suspensionSubscription = AuthInterceptor.suspensionStream.listen((data) {
      final details = data['suspensionDetails'] as Map<String, dynamic>?;
      add(ForcedLogout(
        reason: data['message'] ?? 'Votre compte est suspendu',
        suspensionReason: details?['reason'],
        suspendedUntil: details?['suspendedUntil'] != null
            ? DateTime.tryParse(details!['suspendedUntil'].toString())
            : null,
        suspendedUntilDisplay: details?['suspendedUntilDisplay'],
      ));
    });
  }

  @override
  Future<void> close() {
    _suspensionSubscription?.cancel();
    return super.close();
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await updateProfile(
      UpdateProfileParams(
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        photoUrl: event.photoUrl,
      ),
    );

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
        // Réémettre AuthAuthenticated pour ne pas perdre les données utilisateur
        if (_currentUser != null) {
          emit(AuthAuthenticated(user: _currentUser!));
        }
      },
      (user) {
        _currentUser = user;
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await login(event.email, event.password);

    result.fold(
      (failure) {
        // Vérifier si c'est une erreur de suspension
        if (failure is SuspendedFailure) {
          emit(UserSuspended(
            message: failure.message,
            reason: failure.reason,
            suspendedUntil: failure.suspendedUntil,
            suspendedUntilDisplay: failure.suspendedUntilDisplay,
          ));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (user) {
        _currentUser = user;
        // Enregistrer le token FCM et configurer les notifications
        _setupNotificationsForUser(user);
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onForcedLogout(
    ForcedLogout event,
    Emitter<AuthState> emit,
  ) async {
    // Nettoyer toutes les ressources avant la déconnexion forcée
    await _cleanupAllResources();
    _currentUser = null;

    // Émettre l'état UserSuspended pour afficher le dialog
    emit(UserSuspended(
      message: event.reason,
      reason: event.suspensionReason,
      suspendedUntil: event.suspendedUntil,
      suspendedUntilDisplay: event.suspendedUntilDisplay,
    ));
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
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
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        _currentUser = user;
        // Enregistrer le token FCM et configurer les notifications
        _setupNotificationsForUser(user);
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Nettoyer toutes les ressources avant la déconnexion
    await _cleanupAllResources();

    final result = await logout();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) {
        _currentUser = null;
        emit(AuthUnauthenticated());
      },
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
    emit(AuthLoading());

    final result = await getCurrentUser();

    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        _currentUser = user;
        // Configurer les notifications pour l'utilisateur déjà connecté
        _setupNotificationsForUser(user);
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

  // ============ PHONE VERIFICATION HANDLERS ============

  Future<void> _onSendPhoneVerificationCode(
    SendPhoneVerificationCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.sendPhoneVerificationCode(
      phoneNumber: event.phoneNumber,
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      role: event.role,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (data) => emit(PhoneCodeSent(
        phoneNumber: data['phoneNumber'] ?? event.phoneNumber,
        devCode: data['devCode'],
      )),
    );
  }

  Future<void> _onVerifyPhoneCode(
    VerifyPhoneCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.verifyPhoneCode(
      phoneNumber: event.phoneNumber,
      code: event.code,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        _currentUser = user;
        // Configurer les notifications pour le nouvel utilisateur
        _setupNotificationsForUser(user);
        // Émettre PhoneVerificationSuccess pour que l'UI puisse réagir
        emit(PhoneVerificationSuccess(user: user));
        // Puis émettre AuthAuthenticated pour que RoleBasedHomeWrapper affiche le bon dashboard
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onResendPhoneVerificationCode(
    ResendPhoneVerificationCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.resendPhoneVerificationCode(
      event.phoneNumber,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (data) => emit(PhoneCodeResent(devCode: data['devCode'])),
    );
  }

  // ============ PROFILE PHOTO HANDLERS ============

  Future<void> _onUploadProfilePhoto(
    UploadProfilePhoto event,
    Emitter<AuthState> emit,
  ) async {
    emit(ProfilePhotoUploading());

    final result =
        await authRepository.uploadProfilePhoto(File(event.filePath));

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
        // Réémettre AuthAuthenticated pour ne pas perdre les données utilisateur
        if (_currentUser != null) {
          emit(AuthAuthenticated(user: _currentUser!));
        }
      },
      (user) {
        _currentUser = user;
        emit(ProfilePhotoUploaded(user: user));
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onDeleteProfilePhoto(
    DeleteProfilePhoto event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.deleteProfilePhoto();

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
        if (_currentUser != null) {
          emit(AuthAuthenticated(user: _currentUser!));
        }
      },
      (user) {
        _currentUser = user;
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onCheckPhoneAvailability(
    CheckPhoneAvailability event,
    Emitter<AuthState> emit,
  ) async {
    final result =
        await authRepository.checkPhoneAvailability(event.phoneNumber);

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
        if (_currentUser != null) {
          emit(AuthAuthenticated(user: _currentUser!));
        }
      },
      (isAvailable) => emit(PhoneAvailabilityChecked(
        isAvailable: isAvailable,
        phoneNumber: event.phoneNumber,
      )),
    );
  }

  // ============ PHONE CHANGE VERIFICATION HANDLERS ============

  Future<void> _onSendPhoneChangeCode(
    SendPhoneChangeCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.sendPhoneChangeCode(event.phoneNumber);

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
        // Réémettre AuthAuthenticated pour ne pas perdre les données utilisateur
        if (_currentUser != null) {
          emit(AuthAuthenticated(user: _currentUser!));
        }
      },
      (data) {
        emit(PhoneChangeCodeSent(
          phoneNumber: data['phoneNumber'] ?? event.phoneNumber,
          devCode: data['devCode'],
        ));
      },
    );
  }

  Future<void> _onVerifyPhoneChangeCode(
    VerifyPhoneChangeCode event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.verifyPhoneChangeCode(
      phoneNumber: event.phoneNumber,
      code: event.code,
    );

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
        // Réémettre AuthAuthenticated pour ne pas perdre les données utilisateur
        if (_currentUser != null) {
          emit(AuthAuthenticated(user: _currentUser!));
        }
      },
      (user) {
        _currentUser = user;
        emit(PhoneChangeSuccess(user: user));
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  // ============ NOTIFICATION HELPERS ============

  /// Configure les notifications push et le socket pour l'utilisateur connecté
  Future<void> _setupNotificationsForUser(User user) async {
    try {
      // Connecter le socket pour les communications en temps réel
      await _connectSocket();

      final pushService = sl<PushNotificationService>();

      // Enregistrer le token FCM sur le serveur
      await pushService.registerTokenOnServer();
      debugPrint('FCM token registered for user ${user.id}');

      // S'abonner aux topics selon le rôle
      await _subscribeToTopicsForRole(user.role, pushService);

      // Configurer Analytics avec l'utilisateur
      final analytics = sl<AnalyticsService>();
      await analytics.setUserId(user.id);
      await analytics.setUserRole(user.role.name);
      await analytics.logLogin();

      debugPrint('Notifications configured for ${user.role.name}');
    } catch (e) {
      debugPrint('Error setting up notifications: $e');
    }
  }

  /// S'abonne aux topics FCM selon le rôle de l'utilisateur
  Future<void> _subscribeToTopicsForRole(
      UserRole role, PushNotificationService pushService) async {
    // Topic général pour tous les utilisateurs
    await pushService.subscribeToTopic('all_users');

    switch (role) {
      case UserRole.client:
        await pushService.subscribeToTopic('clients');
        // Se désabonner des topics des autres rôles
        await pushService.unsubscribeFromTopic('workers');
        await pushService.unsubscribeFromTopic('admins');
        break;

      case UserRole.snowWorker:
        await pushService.subscribeToTopic('workers');
        // Se désabonner des topics des autres rôles
        await pushService.unsubscribeFromTopic('clients');
        await pushService.unsubscribeFromTopic('admins');
        break;

      case UserRole.admin:
        await pushService.subscribeToTopic('admins');
        // Les admins peuvent aussi recevoir les notifs workers/clients
        await pushService.subscribeToTopic('workers');
        await pushService.subscribeToTopic('clients');
        break;
    }

    debugPrint('Subscribed to topics for role: ${role.name}');
  }

  /// Nettoie toutes les ressources lors de la déconnexion
  /// (notifications, socket, analytics)
  Future<void> _cleanupAllResources() async {
    try {
      // 1. Déconnecter le socket en temps réel
      await _disconnectSocket();

      // 2. Nettoyer les notifications
      await _cleanupNotifications();

      // 3. Logger la déconnexion dans Analytics
      final analytics = sl<AnalyticsService>();
      await analytics.logLogout();

      debugPrint('All resources cleaned up successfully');
    } catch (e) {
      debugPrint('Error cleaning up resources: $e');
    }
  }

  /// Déconnecte le service Socket.IO
  Future<void> _disconnectSocket() async {
    try {
      final socketService = SocketService();
      await socketService.disconnect();
      debugPrint('Socket disconnected');
    } catch (e) {
      debugPrint('Error disconnecting socket: $e');
    }
  }

  /// Connecte le service Socket.IO avec le token d'authentification
  Future<void> _connectSocket() async {
    try {
      final secureStorage = sl<SecureStorageService>();
      final token = await secureStorage.getToken();

      if (token != null && token.isNotEmpty) {
        final socketService = SocketService();
        await socketService.connect(token);
        debugPrint('Socket connected with auth token');
      } else {
        debugPrint('No auth token available for socket connection');
      }
    } catch (e) {
      debugPrint('Error connecting socket: $e');
    }
  }

  /// Nettoie les notifications lors de la déconnexion
  Future<void> _cleanupNotifications() async {
    try {
      final pushService = sl<PushNotificationService>();

      // Désinscrire le token du serveur
      await pushService.unregisterTokenFromServer();

      // Se désabonner de tous les topics
      await pushService.unsubscribeFromTopic('all_users');
      await pushService.unsubscribeFromTopic('clients');
      await pushService.unsubscribeFromTopic('workers');
      await pushService.unsubscribeFromTopic('admins');

      debugPrint('Notifications cleaned up');
    } catch (e) {
      debugPrint('Error cleaning up notifications: $e');
    }
  }
}
