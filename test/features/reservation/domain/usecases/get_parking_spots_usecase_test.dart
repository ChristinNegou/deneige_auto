import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_parking_spots_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetParkingSpotsUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = GetParkingSpotsUseCase(mockRepository);
  });

  group('GetParkingSpotsUseCase', () {
    final tParkingSpots = ReservationFixtures.createParkingSpotList(5);

    test('should return list of parking spots when successful', () async {
      // Arrange
      when(() => mockRepository.getParkingSpots(availableOnly: false))
          .thenAnswer((_) async => Right(tParkingSpots));

      // Act
      final result = await usecase(availableOnly: false);

      // Assert
      expect(result, Right(tParkingSpots));
      verify(() => mockRepository.getParkingSpots(availableOnly: false)).called(1);
    });

    test('should return only available spots when availableOnly is true', () async {
      // Arrange
      final availableSpots = tParkingSpots.take(3).toList();
      when(() => mockRepository.getParkingSpots(availableOnly: true))
          .thenAnswer((_) async => Right(availableSpots));

      // Act
      final result = await usecase(availableOnly: true);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (spots) => expect(spots.length, 3),
      );
      verify(() => mockRepository.getParkingSpots(availableOnly: true)).called(1);
    });

    test('should return empty list when no parking spots', () async {
      // Arrange
      when(() => mockRepository.getParkingSpots(availableOnly: any(named: 'availableOnly')))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (spots) => expect(spots, isEmpty),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getParkingSpots(availableOnly: any(named: 'availableOnly')))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
