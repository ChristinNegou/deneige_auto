import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/cancel_reservation_usecase.dart';
import 'package:deneige_auto/features/reservation/data/datasources/reservation_remote_datasource.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late CancelReservationUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = CancelReservationUseCase(mockRepository);
  });

  group('CancelReservationUseCase', () {
    const tReservationId = 'reservation-123';
    const tReason = 'Changement de plan';

    final tCancellationResult = CancellationResult(
      success: true,
      message: 'Reservation annulee',
      reservationId: tReservationId,
      previousStatus: 'pending',
      originalPrice: 25.0,
      cancellationFeePercent: 0.0,
      cancellationFeeAmount: 0.0,
      refundAmount: 25.0,
    );

    test('should cancel reservation successfully', () async {
      // Arrange
      when(() =>
              mockRepository.cancelReservation(tReservationId, reason: tReason))
          .thenAnswer((_) async => Right(tCancellationResult));

      // Act
      final result = await usecase(tReservationId, reason: tReason);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (cancellation) {
          expect(cancellation.success, true);
          expect(cancellation.refundAmount, 25.0);
        },
      );
      verify(() =>
              mockRepository.cancelReservation(tReservationId, reason: tReason))
          .called(1);
    });

    test('should cancel reservation without reason', () async {
      // Arrange
      when(() => mockRepository.cancelReservation(tReservationId))
          .thenAnswer((_) async => Right(tCancellationResult));

      // Act
      final result = await usecase(tReservationId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.cancelReservation(tReservationId)).called(1);
    });

    test('should return cancellation with fee when late cancellation',
        () async {
      // Arrange
      final lateCancellationResult = CancellationResult(
        success: true,
        message: 'Annulation avec frais',
        reservationId: tReservationId,
        previousStatus: 'confirmed',
        originalPrice: 25.0,
        cancellationFeePercent: 20.0,
        cancellationFeeAmount: 5.0,
        refundAmount: 20.0,
      );
      when(() => mockRepository.cancelReservation(tReservationId,
              reason: any(named: 'reason')))
          .thenAnswer((_) async => Right(lateCancellationResult));

      // Act
      final result = await usecase(tReservationId, reason: 'Urgence');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (cancellation) {
          expect(cancellation.cancellationFeeAmount, 5.0);
          expect(cancellation.refundAmount, 20.0);
        },
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.cancelReservation(tReservationId,
              reason: any(named: 'reason')))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(tReservationId, reason: tReason);

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return ValidationFailure when reservation not found',
        () async {
      // Arrange
      when(() => mockRepository.cancelReservation('invalid-id',
              reason: any(named: 'reason')))
          .thenAnswer((_) async => const Left(validationFailure));

      // Act
      final result = await usecase('invalid-id', reason: tReason);

      // Assert
      expect(result, const Left(validationFailure));
    });
  });
}
