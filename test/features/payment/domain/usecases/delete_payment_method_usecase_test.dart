import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/payment/domain/usecases/delete_payment_method_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late DeletePaymentMethodUseCase usecase;
  late MockPaymentRepository mockRepository;

  setUp(() {
    mockRepository = MockPaymentRepository();
    usecase = DeletePaymentMethodUseCase(mockRepository);
  });

  group('DeletePaymentMethodUseCase', () {
    const tPaymentMethodId = 'pm-123';

    test('should delete payment method successfully', () async {
      // Arrange
      when(() => mockRepository.deletePaymentMethod(tPaymentMethodId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(tPaymentMethodId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.deletePaymentMethod(tPaymentMethodId))
          .called(1);
    });

    test('should return ServerFailure when payment method not found', () async {
      // Arrange
      when(() => mockRepository.deletePaymentMethod('invalid-pm'))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase('invalid-pm');

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.deletePaymentMethod(tPaymentMethodId))
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(tPaymentMethodId);

      // Assert
      expect(result, const Left(networkFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.deletePaymentMethod(tPaymentMethodId))
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase(tPaymentMethodId);

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
