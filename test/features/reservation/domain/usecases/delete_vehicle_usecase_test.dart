import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/delete_vehicle_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late DeleteVehicleUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = DeleteVehicleUseCase(mockRepository);
  });

  group('DeleteVehicleUseCase', () {
    const tVehicleId = 'vehicle-123';

    test('should delete vehicle successfully', () async {
      // Arrange
      when(() => mockRepository.deleteVehicle(tVehicleId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(tVehicleId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.deleteVehicle(tVehicleId)).called(1);
    });

    test('should return ServerFailure when vehicle not found', () async {
      // Arrange
      when(() => mockRepository.deleteVehicle('invalid-id'))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase('invalid-id');

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.deleteVehicle(tVehicleId))
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(tVehicleId);

      // Assert
      expect(result, const Left(networkFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.deleteVehicle(tVehicleId))
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase(tVehicleId);

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
