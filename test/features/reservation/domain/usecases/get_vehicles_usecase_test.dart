import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_vehicules_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetVehiclesUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = GetVehiclesUseCase(mockRepository);
  });

  group('GetVehiclesUseCase', () {
    final tVehicles = ReservationFixtures.createVehicleList(3);

    test('should return list of vehicles when successful', () async {
      // Arrange
      when(() => mockRepository.getVehicles())
          .thenAnswer((_) async => Right(tVehicles));

      // Act
      final result = await usecase();

      // Assert
      expect(result, Right(tVehicles));
      verify(() => mockRepository.getVehicles()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when no vehicles', () async {
      // Arrange
      when(() => mockRepository.getVehicles())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (vehicles) => expect(vehicles, isEmpty),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getVehicles())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.getVehicles())
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
