import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:deneige_auto/features/auth/presentation/bloc/auth_event.dart';
import 'package:deneige_auto/features/auth/presentation/bloc/auth_state.dart';
import 'package:deneige_auto/features/auth/domain/entities/user.dart';
import 'package:deneige_auto/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/service/secure_storage_service.dart';

import '../../../../mocks/mock_usecases.dart';
import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/user_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase mockLogin;
  late MockRegisterUseCase mockRegister;
  late MockLogoutUseCase mockLogout;
  late MockGetCurrentUserUseCase mockGetCurrentUser;
  late MockForgotPasswordUseCase mockForgotPassword;
  late MockResetPasswordUseCase mockResetPassword;
  late MockUpdateProfileUseCase mockUpdateProfile;
  late MockAuthRepository mockAuthRepository;
  late MockSecureStorageService mockSecureStorage;

  final sl = GetIt.instance;

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockRegister = MockRegisterUseCase();
    mockLogout = MockLogoutUseCase();
    mockGetCurrentUser = MockGetCurrentUserUseCase();
    mockForgotPassword = MockForgotPasswordUseCase();
    mockResetPassword = MockResetPasswordUseCase();
    mockUpdateProfile = MockUpdateProfileUseCase();
    mockAuthRepository = MockAuthRepository();
    mockSecureStorage = MockSecureStorageService();

    // Register mock SecureStorageService in GetIt
    if (sl.isRegistered<SecureStorageService>()) {
      sl.unregister<SecureStorageService>();
    }
    sl.registerSingleton<SecureStorageService>(mockSecureStorage);

    bloc = AuthBloc(
      login: mockLogin,
      register: mockRegister,
      logout: mockLogout,
      getCurrentUser: mockGetCurrentUser,
      forgotPassword: mockForgotPassword,
      resetPassword: mockResetPassword,
      updateProfile: mockUpdateProfile,
      authRepository: mockAuthRepository,
    );
  });

  setUpAll(() {
    registerFallbackValue(UpdateProfileParams());
    registerFallbackValue(UserRole.client);
  });

  tearDown(() {
    bloc.close();
    if (sl.isRegistered<SecureStorageService>()) {
      sl.unregister<SecureStorageService>();
    }
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(bloc.state, isA<AuthInitial>());
    });

    group('LoginRequested', () {
      final tUser = UserFixtures.createClient();
      const tEmail = 'test@example.com';
      const tPassword = 'password123';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds',
        build: () {
          when(() => mockLogin(tEmail, tPassword))
              .thenAnswer((_) async => Right(tUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoginRequested(
          email: tEmail,
          password: tPassword,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>().having(
            (state) => state.user.email,
            'user email',
            tUser.email,
          ),
        ],
        verify: (_) {
          verify(() => mockLogin(tEmail, tPassword)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails',
        build: () {
          when(() => mockLogin(tEmail, tPassword))
              .thenAnswer((_) async => const Left(
                    AuthFailure(message: 'Email ou mot de passe incorrect'),
                  ));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoginRequested(
          email: tEmail,
          password: tPassword,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (state) => state.message,
            'error message',
            'Email ou mot de passe incorrect',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, UserSuspended] when account is suspended',
        build: () {
          when(() => mockLogin(tEmail, tPassword))
              .thenAnswer((_) async => Left(SuspendedFailure(
                    message: 'Compte suspendu',
                    reason: 'Violation des regles',
                    suspendedUntil: DateTime(2024, 2, 1),
                  )));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoginRequested(
          email: tEmail,
          password: tPassword,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<UserSuspended>().having(
            (state) => state.reason,
            'suspension reason',
            'Violation des regles',
          ),
        ],
      );
    });

    group('RegisterRequested', () {
      final tUser = UserFixtures.createClient();
      const tEmail = 'newuser@example.com';
      const tPassword = 'password123';
      const tFirstName = 'Jean';
      const tLastName = 'Dupont';
      const tPhone = '+1234567890';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when registration succeeds',
        build: () {
          when(() => mockRegister(
                email: tEmail,
                password: tPassword,
                firstName: tFirstName,
                lastName: tLastName,
                phone: tPhone,
                role: UserRole.client,
              )).thenAnswer((_) async => Right(tUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const RegisterRequested(
          email: tEmail,
          password: tPassword,
          firstName: tFirstName,
          lastName: tLastName,
          phone: tPhone,
          role: UserRole.client,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when registration fails',
        build: () {
          when(() => mockRegister(
                email: tEmail,
                password: tPassword,
                firstName: tFirstName,
                lastName: tLastName,
                phone: tPhone,
                role: UserRole.client,
              )).thenAnswer((_) async => const Left(
                ValidationFailure(message: 'Email deja utilise'),
              ));
          return bloc;
        },
        act: (bloc) => bloc.add(const RegisterRequested(
          email: tEmail,
          password: tPassword,
          firstName: tFirstName,
          lastName: tLastName,
          phone: tPhone,
          role: UserRole.client,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (state) => state.message,
            'error message',
            'Email deja utilise',
          ),
        ],
      );
    });

    group('CheckAuthStatus', () {
      final tUser = UserFixtures.createClient();

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is logged in',
        build: () {
          // Mock hasToken to return true (token exists)
          when(() => mockSecureStorage.hasToken())
              .thenAnswer((_) async => true);
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          return bloc;
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no user',
        build: () {
          // Mock hasToken to return false (no token)
          when(() => mockSecureStorage.hasToken())
              .thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when token exists but server rejects',
        build: () {
          // Mock hasToken to return true (token exists)
          when(() => mockSecureStorage.hasToken())
              .thenAnswer((_) async => true);
          // But server returns failure (invalid token)
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => const Left(authFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when logout succeeds',
        build: () {
          when(() => mockLogout()).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(LogoutRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when logout fails',
        build: () {
          when(() => mockLogout())
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(LogoutRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('ForgotPasswordEvent', () {
      const tEmail = 'test@example.com';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, ForgotPasswordSuccess] when email is sent',
        build: () {
          when(() => mockForgotPassword(tEmail))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const ForgotPasswordEvent(tEmail)),
        expect: () => [
          isA<AuthLoading>(),
          isA<ForgotPasswordSuccess>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when forgot password fails',
        build: () {
          when(() => mockForgotPassword(tEmail))
              .thenAnswer((_) async => const Left(
                    ValidationFailure(message: 'Email non trouve'),
                  ));
          return bloc;
        },
        act: (bloc) => bloc.add(const ForgotPasswordEvent(tEmail)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('ResetPasswordEvent', () {
      const tToken = 'reset-token';
      const tNewPassword = 'newPassword123';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, ResetPasswordSuccess] when password is reset',
        build: () {
          when(() => mockResetPassword(
                token: tToken,
                newPassword: tNewPassword,
              )).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const ResetPasswordEvent(
          token: tToken,
          newPassword: tNewPassword,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<ResetPasswordSuccess>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when token is invalid',
        build: () {
          when(() => mockResetPassword(
                token: tToken,
                newPassword: tNewPassword,
              )).thenAnswer((_) async => const Left(
                ValidationFailure(message: 'Token invalide'),
              ));
          return bloc;
        },
        act: (bloc) => bloc.add(const ResetPasswordEvent(
          token: tToken,
          newPassword: tNewPassword,
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('UpdateProfile', () {
      final tUser = UserFixtures.createClient();

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when profile is updated',
        build: () {
          when(() => mockUpdateProfile(any()))
              .thenAnswer((_) async => Right(tUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateProfile(
          firstName: 'Jean-Pierre',
          lastName: 'Martin',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when update fails',
        build: () {
          when(() => mockUpdateProfile(any()))
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateProfile(
          firstName: 'Jean-Pierre',
        )),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('ForcedLogout', () {
      blocTest<AuthBloc, AuthState>(
        'emits [UserSuspended] when forced logout due to suspension',
        build: () => bloc,
        act: (bloc) => bloc.add(ForcedLogout(
          reason: 'Compte suspendu par admin',
          suspensionReason: 'Comportement inapproprie',
          suspendedUntil: DateTime(2024, 3, 1),
        )),
        expect: () => [
          isA<UserSuspended>()
              .having(
                (state) => state.message,
                'message',
                'Compte suspendu par admin',
              )
              .having(
                (state) => state.reason,
                'reason',
                'Comportement inapproprie',
              ),
        ],
      );
    });
  });
}
