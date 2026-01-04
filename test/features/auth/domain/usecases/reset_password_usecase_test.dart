import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:deneige_auto/core/errors/failures.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late ResetPasswordUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = ResetPasswordUseCase(mockRepository);
  });

  group('ResetPasswordUseCase', () {
    const tToken = 'reset-token-123';
    const tNewPassword = 'newPassword456';

    test('should return void when password is reset successfully', () async {
      // Arrange
      when(() => mockRepository.resetPassword(tToken, tNewPassword))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(token: tToken, newPassword: tNewPassword);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.resetPassword(tToken, tNewPassword))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ValidationFailure when token is invalid', () async {
      // Arrange
      const failure = ValidationFailure(message: 'Token invalide ou expire');
      when(() => mockRepository.resetPassword(tToken, tNewPassword))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(token: tToken, newPassword: tNewPassword);

      // Assert
      expect(result, const Left(failure));
    });

    test('should return ValidationFailure when password is weak', () async {
      // Arrange
      const weakPassword = '123';
      const failure = ValidationFailure(message: 'Mot de passe trop faible');
      when(() => mockRepository.resetPassword(tToken, weakPassword))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(token: tToken, newPassword: weakPassword);

      // Assert
      expect(result, const Left(failure));
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.resetPassword(tToken, tNewPassword))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(token: tToken, newPassword: tNewPassword);

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
