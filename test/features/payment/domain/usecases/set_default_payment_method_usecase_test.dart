import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/payment/domain/usecases/set_default_payment_method_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late SetDefaultPaymentMethodUseCase usecase;
  late MockPaymentRepository mockRepository;

  setUp(() {
    mockRepository = MockPaymentRepository();
    usecase = SetDefaultPaymentMethodUseCase(mockRepository);
  });

  group('SetDefaultPaymentMethodUseCase', () {
    const tPaymentMethodId = 'pm-123';

    test('should set default payment method successfully', () async {
      // Arrange
      when(() => mockRepository.setDefaultPaymentMethod(tPaymentMethodId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(tPaymentMethodId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.setDefaultPaymentMethod(tPaymentMethodId)).called(1);
    });

    test('should return ServerFailure when payment method not found', () async {
      // Arrange
      when(() => mockRepository.setDefaultPaymentMethod('invalid-pm'))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase('invalid-pm');

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.setDefaultPaymentMethod(tPaymentMethodId))
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(tPaymentMethodId);

      // Assert
      expect(result, const Left(networkFailure));
    });
  });
}
