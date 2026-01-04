import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/add_vehicle_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late AddVehicleUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = AddVehicleUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(VehicleType.car);
  });

  group('AddVehicleUseCase', () {
    final tVehicle = ReservationFixtures.createVehicle();

    AddVehicleParams createValidParams() {
      return AddVehicleParams(
        make: 'Honda',
        model: 'Civic',
        year: 2022,
        color: 'Noir',
        licensePlate: 'ABC 123',
        type: VehicleType.car,
        isDefault: true,
      );
    }

    test('should add vehicle successfully', () async {
      // Arrange
      final params = createValidParams();
      when(() => mockRepository.addVehicle(
            make: any(named: 'make'),
            model: any(named: 'model'),
            year: any(named: 'year'),
            color: any(named: 'color'),
            licensePlate: any(named: 'licensePlate'),
            type: any(named: 'type'),
            photoUrl: any(named: 'photoUrl'),
            isDefault: any(named: 'isDefault'),
          )).thenAnswer((_) async => Right(tVehicle));

      // Act
      final result = await usecase(params);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.addVehicle(
            make: 'Honda',
            model: 'Civic',
            year: 2022,
            color: 'Noir',
            licensePlate: 'ABC 123',
            type: VehicleType.car,
            photoUrl: null,
            isDefault: true,
          )).called(1);
    });

    test('should add vehicle with photo URL', () async {
      // Arrange
      final params = AddVehicleParams(
        make: 'Toyota',
        model: 'Corolla',
        year: 2021,
        color: 'Blanc',
        licensePlate: 'XYZ 789',
        type: VehicleType.suv,
        photoUrl: 'https://example.com/car.jpg',
        isDefault: false,
      );
      when(() => mockRepository.addVehicle(
            make: any(named: 'make'),
            model: any(named: 'model'),
            year: any(named: 'year'),
            color: any(named: 'color'),
            licensePlate: any(named: 'licensePlate'),
            type: any(named: 'type'),
            photoUrl: any(named: 'photoUrl'),
            isDefault: any(named: 'isDefault'),
          )).thenAnswer((_) async => Right(tVehicle));

      // Act
      final result = await usecase(params);

      // Assert
      expect(result.isRight(), true);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      final params = createValidParams();
      when(() => mockRepository.addVehicle(
            make: any(named: 'make'),
            model: any(named: 'model'),
            year: any(named: 'year'),
            color: any(named: 'color'),
            licensePlate: any(named: 'licensePlate'),
            type: any(named: 'type'),
            photoUrl: any(named: 'photoUrl'),
            isDefault: any(named: 'isDefault'),
          )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(params);

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return ValidationFailure for duplicate license plate',
        () async {
      // Arrange
      final params = createValidParams();
      when(() => mockRepository.addVehicle(
            make: any(named: 'make'),
            model: any(named: 'model'),
            year: any(named: 'year'),
            color: any(named: 'color'),
            licensePlate: any(named: 'licensePlate'),
            type: any(named: 'type'),
            photoUrl: any(named: 'photoUrl'),
            isDefault: any(named: 'isDefault'),
          )).thenAnswer((_) async => const Left(validationFailure));

      // Act
      final result = await usecase(params);

      // Assert
      expect(result, const Left(validationFailure));
    });
  });
}
