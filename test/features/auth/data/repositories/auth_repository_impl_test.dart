import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/errors/exceptions.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:deneige_auto/features/auth/domain/entities/user.dart';

import '../../../../mocks/mock_datasources.dart';
import '../../../../fixtures/user_fixtures.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('AuthRepositoryImpl', () {
    final tUser = UserFixtures.createClientModel();
    const tEmail = 'test@example.com';
    const tPassword = 'password123';

    group('login', () {
      test('should return User when login is successful', () async {
        when(() => mockDataSource.login(tEmail, tPassword))
            .thenAnswer((_) async => tUser);

        final result = await repository.login(tEmail, tPassword);

        expect(result, Right(tUser));
        verify(() => mockDataSource.login(tEmail, tPassword)).called(1);
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        when(() => mockDataSource.login(tEmail, tPassword))
            .thenThrow(const AuthException(message: 'Invalid credentials'));

        final result = await repository.login(tEmail, tPassword);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return NetworkFailure when NetworkException is thrown', () async {
        when(() => mockDataSource.login(tEmail, tPassword))
            .thenThrow(const NetworkException(message: 'No connection'));

        final result = await repository.login(tEmail, tPassword);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.login(tEmail, tPassword))
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.login(tEmail, tPassword);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return SuspendedFailure when SuspendedException is thrown', () async {
        when(() => mockDataSource.login(tEmail, tPassword))
            .thenThrow(SuspendedException(
              message: 'Account suspended',
              reason: 'Violation',
              suspendedUntil: DateTime.now().add(const Duration(days: 7)),
            ));

        final result = await repository.login(tEmail, tPassword);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<SuspendedFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('register', () {
      test('should return User when registration is successful', () async {
        // The repository splits 'John Doe' into firstName='John' and lastName='Doe'
        when(() => mockDataSource.register(
          tEmail, tPassword, 'John', 'Doe',
          phone: '+1234567890',
          role: UserRole.client,
        )).thenAnswer((_) async => tUser);

        final result = await repository.register(
          tEmail, tPassword, 'John Doe',
          phone: '+1234567890',
        );

        expect(result, Right(tUser));
      });

      test('should return AuthFailure when AuthException is thrown', () async {
        when(() => mockDataSource.register(
          tEmail, tPassword, 'John', 'Doe',
          phone: null,
          role: UserRole.client,
        )).thenThrow(const AuthException(message: 'Email already exists'));

        final result = await repository.register(tEmail, tPassword, 'John Doe');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return User when successful', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => tUser);

        final result = await repository.getCurrentUser();

        expect(result, Right(tUser));
        verify(() => mockDataSource.getCurrentUser()).called(1);
      });

      test('should return AuthFailure when not authenticated', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenThrow(const AuthException(message: 'Not authenticated'));

        final result = await repository.getCurrentUser();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('logout', () {
      test('should return Right(null) when logout is successful', () async {
        when(() => mockDataSource.logout())
            .thenAnswer((_) async => {});

        final result = await repository.logout();

        expect(result, const Right(null));
        verify(() => mockDataSource.logout()).called(1);
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.logout())
            .thenThrow(const ServerException(message: 'Logout failed'));

        final result = await repository.logout();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('forgotPassword', () {
      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.forgotPassword(tEmail))
            .thenAnswer((_) async => {});

        final result = await repository.forgotPassword(tEmail);

        expect(result, const Right(null));
        verify(() => mockDataSource.forgotPassword(tEmail)).called(1);
      });

      test('should return NetworkFailure when NetworkException is thrown', () async {
        when(() => mockDataSource.forgotPassword(tEmail))
            .thenThrow(const NetworkException(message: 'No connection'));

        final result = await repository.forgotPassword(tEmail);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('resetPassword', () {
      const tToken = 'reset_token_123';
      const tNewPassword = 'newPassword123';

      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.resetPassword(tToken, tNewPassword))
            .thenAnswer((_) async => {});

        final result = await repository.resetPassword(tToken, tNewPassword);

        expect(result, const Right(null));
        verify(() => mockDataSource.resetPassword(tToken, tNewPassword)).called(1);
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.resetPassword(tToken, tNewPassword))
            .thenThrow(const ServerException(message: 'Invalid token'));

        final result = await repository.resetPassword(tToken, tNewPassword);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('isLoggedIn', () {
      test('should return true when user is logged in', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenAnswer((_) async => tUser);

        final result = await repository.isLoggedIn();

        expect(result, const Right(true));
      });

      test('should return false when user is not logged in', () async {
        when(() => mockDataSource.getCurrentUser())
            .thenThrow(const AuthException(message: 'Not authenticated'));

        final result = await repository.isLoggedIn();

        expect(result, const Right(false));
      });
    });

    group('updateProfile', () {
      test('should return User when profile update is successful', () async {
        when(() => mockDataSource.updateProfile(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phoneNumber: any(named: 'phoneNumber'),
          photoUrl: any(named: 'photoUrl'),
        )).thenAnswer((_) async => tUser);

        final result = await repository.updateProfile(
          firstName: 'Jane',
          lastName: 'Smith',
        );

        expect(result, Right(tUser));
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.updateProfile(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phoneNumber: any(named: 'phoneNumber'),
          photoUrl: any(named: 'photoUrl'),
        )).thenThrow(const ServerException(message: 'Update failed'));

        final result = await repository.updateProfile(firstName: 'Jane');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
