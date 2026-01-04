import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/payment/domain/usecases/get_payment_history_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/payment_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetPaymentHistoryUseCase usecase;
  late MockPaymentRepository mockRepository;

  setUp(() {
    mockRepository = MockPaymentRepository();
    usecase = GetPaymentHistoryUseCase(mockRepository);
  });

  group('GetPaymentHistoryUseCase', () {
    final tPayments = PaymentFixtures.createList(5);

    test('should return list of payments when successful', () async {
      // Arrange
      when(() => mockRepository.getPaymentHistory())
          .thenAnswer((_) async => Right(tPayments));

      // Act
      final result = await usecase();

      // Assert
      expect(result, Right(tPayments));
      verify(() => mockRepository.getPaymentHistory()).called(1);
    });

    test('should return empty list when no payment history', () async {
      // Arrange
      when(() => mockRepository.getPaymentHistory())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (payments) => expect(payments, isEmpty),
      );
    });

    test('should return mixed payment statuses', () async {
      // Arrange
      final mixedPayments = PaymentFixtures.createMixedList();
      when(() => mockRepository.getPaymentHistory())
          .thenAnswer((_) async => Right(mixedPayments));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (payments) => expect(payments.length, 5),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getPaymentHistory())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.getPaymentHistory())
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
