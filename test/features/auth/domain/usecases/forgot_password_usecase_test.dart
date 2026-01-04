import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:deneige_auto/core/errors/failures.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late ForgotPasswordUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = ForgotPasswordUseCase(mockRepository);
  });

  group('ForgotPasswordUseCase', () {
    const tEmail = 'test@example.com';

    test('should return void when email is sent successfully', () async {
      // Arrange
      when(() => mockRepository.forgotPassword(tEmail))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(tEmail);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.forgotPassword(tEmail)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ValidationFailure when email does not exist', () async {
      // Arrange
      const failure = ValidationFailure(message: 'Aucun compte avec cet email');
      when(() => mockRepository.forgotPassword(tEmail))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(tEmail);

      // Assert
      expect(result, const Left(failure));
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.forgotPassword(tEmail))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(tEmail);

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure when no connection', () async {
      // Arrange
      when(() => mockRepository.forgotPassword(tEmail))
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(tEmail);

      // Assert
      expect(result, const Left(networkFailure));
    });
  });
}
