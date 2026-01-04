import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/payment/domain/usecases/process_refund_usecase.dart';
import 'package:deneige_auto/features/payment/domain/entities/refund.dart';
import 'package:deneige_auto/core/errors/failures.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/payment_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late ProcessRefundUseCase usecase;
  late MockPaymentRepository mockRepository;

  setUp(() {
    mockRepository = MockPaymentRepository();
    usecase = ProcessRefundUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(RefundReason.requestedByCustomer);
  });

  group('ProcessRefundUseCase', () {
    const tReservationId = 'reservation-123';
    const tReason = RefundReason.requestedByCustomer;
    final tRefund = PaymentFixtures.createRefund();

    test('should process refund successfully', () async {
      // Arrange
      when(() => mockRepository.processRefund(
        reservationId: tReservationId,
        amount: any(named: 'amount'),
        reason: tReason,
        note: any(named: 'note'),
      )).thenAnswer((_) async => Right(tRefund));

      // Act
      final result = await usecase(
        reservationId: tReservationId,
        reason: tReason,
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.processRefund(
        reservationId: tReservationId,
        amount: null,
        reason: tReason,
        note: null,
      )).called(1);
    });

    test('should process partial refund with specific amount', () async {
      // Arrange
      final partialRefund = PaymentFixtures.createRefund(amount: 15.0);
      when(() => mockRepository.processRefund(
        reservationId: tReservationId,
        amount: 15.0,
        reason: tReason,
        note: any(named: 'note'),
      )).thenAnswer((_) async => Right(partialRefund));

      // Act
      final result = await usecase(
        reservationId: tReservationId,
        amount: 15.0,
        reason: tReason,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (refund) => expect(refund.amount, 15.0),
      );
    });

    test('should return ValidationFailure when reservationId is empty', () async {
      // Act
      final result = await usecase(
        reservationId: '',
        reason: tReason,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('réservation'));
        },
        (_) => fail('Should be Left'),
      );
      verifyNever(() => mockRepository.processRefund(
        reservationId: any(named: 'reservationId'),
        amount: any(named: 'amount'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ));
    });

    test('should return ValidationFailure when amount is negative', () async {
      // Act
      final result = await usecase(
        reservationId: tReservationId,
        amount: -10.0,
        reason: tReason,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('positif'));
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ValidationFailure when amount is zero', () async {
      // Act
      final result = await usecase(
        reservationId: tReservationId,
        amount: 0,
        reason: tReason,
      );

      // Assert
      expect(result.isLeft(), true);
    });

    test('should process refund with note', () async {
      // Arrange
      when(() => mockRepository.processRefund(
        reservationId: tReservationId,
        amount: any(named: 'amount'),
        reason: tReason,
        note: 'Client mecontent',
      )).thenAnswer((_) async => Right(tRefund));

      // Act
      final result = await usecase(
        reservationId: tReservationId,
        reason: tReason,
        note: 'Client mecontent',
      );

      // Assert
      expect(result.isRight(), true);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.processRefund(
        reservationId: any(named: 'reservationId'),
        amount: any(named: 'amount'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(
        reservationId: tReservationId,
        reason: tReason,
      );

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
