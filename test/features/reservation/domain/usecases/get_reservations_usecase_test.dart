import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_reservations_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetReservationsUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = GetReservationsUseCase(mockRepository);
  });

  group('GetReservationsUseCase', () {
    final tReservations = ReservationFixtures.createList(5);

    test('should return list of reservations when successful', () async {
      // Arrange
      when(() => mockRepository.getReservations(upcoming: true))
          .thenAnswer((_) async => Right(tReservations));

      // Act
      final result = await usecase(upcoming: true);

      // Assert
      expect(result, Right(tReservations));
      verify(() => mockRepository.getReservations(upcoming: true)).called(1);
    });

    test('should return upcoming reservations only', () async {
      // Arrange
      when(() => mockRepository.getReservations(upcoming: true))
          .thenAnswer((_) async => Right(tReservations));

      // Act
      final result = await usecase(upcoming: true);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (reservations) => expect(reservations.length, 5),
      );
    });

    test('should return all reservations when upcoming is false', () async {
      // Arrange
      when(() => mockRepository.getReservations(upcoming: false))
          .thenAnswer((_) async => Right(tReservations));

      // Act
      final result = await usecase(upcoming: false);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.getReservations(upcoming: false)).called(1);
    });

    test('should return empty list when no reservations', () async {
      // Arrange
      when(() => mockRepository.getReservations(upcoming: true))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase(upcoming: true);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (reservations) => expect(reservations, isEmpty),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getReservations(upcoming: any(named: 'upcoming')))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(upcoming: true);

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
