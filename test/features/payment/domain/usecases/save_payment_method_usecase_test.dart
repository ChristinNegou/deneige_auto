import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/payment/domain/usecases/save_payment_method_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late SavePaymentMethodUseCase usecase;
  late MockPaymentRepository mockRepository;

  setUp(() {
    mockRepository = MockPaymentRepository();
    usecase = SavePaymentMethodUseCase(mockRepository);
  });

  group('SavePaymentMethodUseCase', () {
    const tPaymentMethodId = 'pm_stripe_123';

    test('should save payment method successfully', () async {
      // Arrange
      when(() => mockRepository.savePaymentMethod(
            paymentMethodId: tPaymentMethodId,
            setAsDefault: false,
          )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(
        paymentMethodId: tPaymentMethodId,
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.savePaymentMethod(
            paymentMethodId: tPaymentMethodId,
            setAsDefault: false,
          )).called(1);
    });

    test('should save payment method and set as default', () async {
      // Arrange
      when(() => mockRepository.savePaymentMethod(
            paymentMethodId: tPaymentMethodId,
            setAsDefault: true,
          )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(
        paymentMethodId: tPaymentMethodId,
        setAsDefault: true,
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.savePaymentMethod(
            paymentMethodId: tPaymentMethodId,
            setAsDefault: true,
          )).called(1);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.savePaymentMethod(
            paymentMethodId: any(named: 'paymentMethodId'),
            setAsDefault: any(named: 'setAsDefault'),
          )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(paymentMethodId: tPaymentMethodId);

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return ValidationFailure for invalid payment method',
        () async {
      // Arrange
      when(() => mockRepository.savePaymentMethod(
            paymentMethodId: any(named: 'paymentMethodId'),
            setAsDefault: any(named: 'setAsDefault'),
          )).thenAnswer((_) async => const Left(validationFailure));

      // Act
      final result = await usecase(paymentMethodId: 'invalid_pm');

      // Assert
      expect(result, const Left(validationFailure));
    });
  });
}
