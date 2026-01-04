import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/create_reservation_usecase.dart';
import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/core/errors/failures.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late CreateReservationUseCase usecase;
  late MockReservationRepository mockRepository;

  setUp(() {
    mockRepository = MockReservationRepository();
    usecase = CreateReservationUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(ServiceOption.windowScraping);
    registerFallbackValue(DateTime.now());
  });

  group('CreateReservationUseCase', () {
    final tReservation = ReservationFixtures.createPending();

    CreateReservationParams createValidParams({
      DateTime? departureTime,
      double? totalPrice,
    }) {
      return CreateReservationParams(
        vehicleId: 'vehicle-123',
        parkingSpotId: 'spot-123',
        departureTime:
            departureTime ?? DateTime.now().add(const Duration(hours: 2)),
        deadlineTime: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
        serviceOptions: [ServiceOption.windowScraping],
        snowDepthCm: 10,
        totalPrice: totalPrice ?? 25.0,
        paymentMethod: 'pm_card_visa',
        latitude: 46.3432,
        longitude: -72.5476,
        address: 'Trois-Rivieres, QC',
      );
    }

    test('should create reservation successfully with valid params', () async {
      // Arrange
      final params = createValidParams();
      when(() => mockRepository.createReservation(
            vehicleId: any(named: 'vehicleId'),
            parkingSpotId: any(named: 'parkingSpotId'),
            departureTime: any(named: 'departureTime'),
            deadlineTime: any(named: 'deadlineTime'),
            serviceOptions: any(named: 'serviceOptions'),
            snowDepthCm: any(named: 'snowDepthCm'),
            totalPrice: any(named: 'totalPrice'),
            paymentMethod: any(named: 'paymentMethod'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            address: any(named: 'address'),
          )).thenAnswer((_) async => Right(tReservation));

      // Act
      final result = await usecase(params);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createReservation(
            vehicleId: 'vehicle-123',
            parkingSpotId: 'spot-123',
            departureTime: any(named: 'departureTime'),
            deadlineTime: any(named: 'deadlineTime'),
            serviceOptions: ['windowScraping'],
            snowDepthCm: 10,
            totalPrice: 25.0,
            paymentMethod: 'pm_card_visa',
            latitude: 46.3432,
            longitude: -72.5476,
            address: 'Trois-Rivieres, QC',
          )).called(1);
    });

    test('should return ValidationFailure when departure time is too soon',
        () async {
      // Arrange
      final params = createValidParams(
        departureTime:
            DateTime.now().add(const Duration(minutes: 30)), // Too soon
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
      verifyNever(() => mockRepository.createReservation(
            vehicleId: any(named: 'vehicleId'),
            parkingSpotId: any(named: 'parkingSpotId'),
            departureTime: any(named: 'departureTime'),
            deadlineTime: any(named: 'deadlineTime'),
            serviceOptions: any(named: 'serviceOptions'),
            snowDepthCm: any(named: 'snowDepthCm'),
            totalPrice: any(named: 'totalPrice'),
            paymentMethod: any(named: 'paymentMethod'),
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
      when(() => mockRepository.createReservation(
            vehicleId: any(named: 'vehicleId'),
            parkingSpotId: any(named: 'parkingSpotId'),
            departureTime: any(named: 'departureTime'),
            deadlineTime: any(named: 'deadlineTime'),
            serviceOptions: any(named: 'serviceOptions'),
            snowDepthCm: any(named: 'snowDepthCm'),
            totalPrice: any(named: 'totalPrice'),
            paymentMethod: any(named: 'paymentMethod'),
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
