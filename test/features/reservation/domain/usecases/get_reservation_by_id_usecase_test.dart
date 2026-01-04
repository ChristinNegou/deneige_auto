import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_reservation_by_id_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetReservationByIdUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = GetReservationByIdUseCase(mockRepository);
  });

  group('GetReservationByIdUseCase', () {
    const tReservationId = 'reservation-123';
    final tReservation = ReservationFixtures.createPending(id: tReservationId);

    test('should return reservation when found', () async {
      // Arrange
      when(() => mockRepository.getReservationById(tReservationId))
          .thenAnswer((_) async => Right(tReservation));

      // Act
      final result = await usecase(tReservationId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (reservation) => expect(reservation.id, tReservationId),
      );
      verify(() => mockRepository.getReservationById(tReservationId)).called(1);
    });

    test('should return ServerFailure when reservation not found', () async {
      // Arrange
      when(() => mockRepository.getReservationById('invalid-id'))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase('invalid-id');

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.getReservationById(tReservationId))
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(tReservationId);

      // Assert
      expect(result, const Left(networkFailure));
    });
  });
}
