import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/update_reservation_usecase.dart';
import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/core/errors/failures.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late UpdateReservationUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = UpdateReservationUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(ServiceOption.windowScraping);
    registerFallbackValue(DateTime.now());
  });

  group('UpdateReservationUseCase', () {
    final tReservation = ReservationFixtures.createPending();

    UpdateReservationParams createValidParams({
      DateTime? departureTime,
      double? totalPrice,
    }) {
      return UpdateReservationParams(
        reservationId: 'reservation-123',
        vehicleId: 'vehicle-123',
        parkingSpotId: 'spot-123',
        departureTime:
            departureTime ?? DateTime.now().add(const Duration(hours: 2)),
        deadlineTime: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
        serviceOptions: [ServiceOption.windowScraping],
        snowDepthCm: 15,
        totalPrice: totalPrice ?? 30.0,
        latitude: 46.3432,
        longitude: -72.5476,
        address: 'Trois-Rivieres, QC',
      );
    }

    test('should update reservation successfully with valid params', () async {
      // Arrange
      final params = createValidParams();
      when(() => mockRepository.updateReservation(
            reservationId: any(named: 'reservationId'),
            vehicleId: any(named: 'vehicleId'),
            parkingSpotId: any(named: 'parkingSpotId'),
            departureTime: any(named: 'departureTime'),
            deadlineTime: any(named: 'deadlineTime'),
            serviceOptions: any(named: 'serviceOptions'),
            snowDepthCm: any(named: 'snowDepthCm'),
            totalPrice: any(named: 'totalPrice'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            address: any(named: 'address'),
          )).thenAnswer((_) async => Right(tReservation));

      // Act
      final result = await usecase(params);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.updateReservation(
            reservationId: 'reservation-123',
            vehicleId: 'vehicle-123',
            parkingSpotId: 'spot-123',
            departureTime: any(named: 'departureTime'),
            deadlineTime: any(named: 'deadlineTime'),
            serviceOptions: ['windowScraping'],
            snowDepthCm: 15,
            totalPrice: 30.0,
            latitude: 46.3432,
            longitude: -72.5476,
            address: 'Trois-Rivieres, QC',
          )).called(1);
    });

    test('should return ValidationFailure when departure time is too soon',
        () async {
      // Arrange
      final params = createValidParams(
        departureTime: DateTime.now().add(const Duration(minutes: 30)),
      );

      // Act
      final result = await usecase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message,
              contains('${AppConfig.minReservationTimeMinutes}'));
        },
        (_) => fail('Should be Left'),
      );
      verifyNever(() => mockRepository.updateReservation(
            reservationId: any(named: 'reservationId'),
            vehicleId: any(named: 'vehicleId'),
            parkingSpotId: any(named: 'parkingSpotId'),
            departureTime: any(named: 'departureTime'),
            deadlineTime: any(named: 'deadlineTime'),
            serviceOptions: any(named: 'serviceOptions'),
            snowDepthCm: any(named: 'snowDepthCm'),
            totalPrice: any(named: 'totalPrice'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            address: any(named: 'address'),
          ));
    });

    test('should return ValidationFailure when price is zero or negative',
        () async {
      // Arrange
      final params = createValidParams(totalPrice: 0);

      // Act
      final result = await usecase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('prix'));
        },
        (_) => fail('Should be Left'),
      );
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      final params = createValidParams();
      when(() => mockRepository.updateReservation(
            reservationId: any(named: 'reservationId'),
            vehicleId: any(named: 'vehicleId'),
            parkingSpotId: any(named: 'parkingSpotId'),
            departureTime: any(named: 'departureTime'),
            deadlineTime: any(named: 'deadlineTime'),
            serviceOptions: any(named: 'serviceOptions'),
            snowDepthCm: any(named: 'snowDepthCm'),
            totalPrice: any(named: 'totalPrice'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            address: any(named: 'address'),
          )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(params);

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
