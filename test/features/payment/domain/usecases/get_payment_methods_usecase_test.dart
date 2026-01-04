import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/payment/domain/usecases/get_payment_methods_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/payment_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetPaymentMethodsUseCase usecase;
  late MockPaymentRepository mockRepository;

  setUp(() {
    mockRepository = MockPaymentRepository();
    usecase = GetPaymentMethodsUseCase(mockRepository);
  });

  group('GetPaymentMethodsUseCase', () {
    final tPaymentMethods = PaymentFixtures.createPaymentMethodList(3);

    test('should return list of payment methods when successful', () async {
      // Arrange
      when(() => mockRepository.getPaymentMethods())
          .thenAnswer((_) async => Right(tPaymentMethods));

      // Act
      final result = await usecase();

      // Assert
      expect(result, Right(tPaymentMethods));
      verify(() => mockRepository.getPaymentMethods()).called(1);
    });

    test('should return empty list when no payment methods', () async {
      // Arrange
      when(() => mockRepository.getPaymentMethods())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (methods) => expect(methods, isEmpty),
      );
    });

    test('should return methods with default marked', () async {
      // Arrange
      final methodsWithDefault = PaymentFixtures.createPaymentMethodList(3, withDefault: true);
      when(() => mockRepository.getPaymentMethods())
          .thenAnswer((_) async => Right(methodsWithDefault));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (methods) {
          final defaultMethod = methods.firstWhere((m) => m.isDefault);
          expect(defaultMethod.id, 'pm-0');
        },
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getPaymentMethods())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
