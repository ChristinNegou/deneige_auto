import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/domain/usecases/login_usecase.dart';
import 'package:deneige_auto/core/errors/failures.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/user_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late LoginUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    final tUser = UserFixtures.createClient(email: tEmail);

    test('should return User when login is successful', () async {
      // Arrange
      when(() => mockRepository.login(tEmail, tPassword))
          .thenAnswer((_) async => Right(tUser));

      // Act
      final result = await usecase(tEmail, tPassword);

      // Assert
      expect(result, Right(tUser));
      verify(() => mockRepository.login(tEmail, tPassword)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return AuthFailure when credentials are invalid', () async {
      // Arrange
      const failure = AuthFailure(message: 'Email ou mot de passe incorrect');
      when(() => mockRepository.login(tEmail, tPassword))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(tEmail, tPassword);

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.login(tEmail, tPassword)).called(1);
    });

    test('should return SuspendedFailure when account is suspended', () async {
      // Arrange
      final failure = createSuspendedFailure(
        message: 'Votre compte est suspendu',
        reason: 'Violation des conditions',
      );
      when(() => mockRepository.login(tEmail, tPassword))
          .thenAnswer((_) async => Left(failure));

      // Act
      final result = await usecase(tEmail, tPassword);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<SuspendedFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      // Arrange
      when(() => mockRepository.login(tEmail, tPassword))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(tEmail, tPassword);

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure when no connection', () async {
      // Arrange
      when(() => mockRepository.login(tEmail, tPassword))
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(tEmail, tPassword);

      // Assert
      expect(result, const Left(networkFailure));
    });
  });
}
