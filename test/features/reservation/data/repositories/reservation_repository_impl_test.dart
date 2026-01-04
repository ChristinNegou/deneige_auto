import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/errors/exceptions.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:deneige_auto/features/reservation/data/models/reservation_model.dart';
import 'package:deneige_auto/features/reservation/data/models/vehicule_model.dart';
import 'package:deneige_auto/features/reservation/data/models/parking_spot_model.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:deneige_auto/core/config/app_config.dart';

import '../../../../mocks/mock_datasources.dart';

void main() {
  late ReservationRepositoryImpl repository;
  late MockReservationRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockReservationRemoteDataSource();
    repository = ReservationRepositoryImpl(remoteDataSource: mockDataSource);
  });

  // Helper pour creer un ParkingSpotModel
  ParkingSpotModel createParkingSpotModel() {
    return ParkingSpotModel(
      id: 'spot-123',
      spotNumber: 'A-15',
      latitude: 46.3432,
      longitude: -72.5476,
      createdAt: DateTime(2024, 1, 15, 10, 0),
      updatedAt: DateTime(2024, 1, 15, 10, 0),
    );
  }

  // Helper pour creer un VehicleModel
  VehicleModel createVehicleModel({String id = 'vehicle-123'}) {
    return VehicleModel(
      id: id,
      userId: 'user-123',
      make: 'Honda',
      model: 'Civic',
      year: 2022,
      color: 'Noir',
      licensePlate: 'ABC 123',
      type: VehicleType.car,
      isDefault: false,
      createdAt: DateTime(2024, 1, 15, 10, 0),
      updatedAt: DateTime(2024, 1, 15, 10, 0),
    );
  }

  // Helper pour creer un ReservationModel
  ReservationModel createReservationModel({String id = 'res-123'}) {
    return ReservationModel(
      id: id,
      userId: 'user-123',
      parkingSpot: createParkingSpotModel(),
      vehicle: createVehicleModel(),
      departureTime: DateTime(2024, 1, 15, 12, 0),
      deadlineTime: DateTime(2024, 1, 15, 11, 30),
      status: ReservationStatus.pending,
      serviceOptions: const [ServiceOption.windowScraping],
      basePrice: 15.0,
      totalPrice: 25.0,
      snowDepthCm: 10,
      createdAt: DateTime(2024, 1, 15, 10, 0),
      isPriority: false,
    );
  }

  // Helper pour creer un CancellationResult
  CancellationResult createCancellationResult() {
    return CancellationResult(
      success: true,
      message: 'Reservation cancelled',
      reservationId: 'res-123',
      previousStatus: 'pending',
      originalPrice: 25.0,
      cancellationFeePercent: 0.0,
      cancellationFeeAmount: 0.0,
      refundAmount: 25.0,
    );
  }

  group('ReservationRepositoryImpl', () {
    group('getReservations', () {
      test('should return list of reservations when successful', () async {
        final tReservations = [
          createReservationModel(id: 'res-1'),
          createReservationModel(id: 'res-2'),
        ];
        when(() => mockDataSource.getReservations())
            .thenAnswer((_) async => tReservations);

        final result = await repository.getReservations();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return reservations'),
          (reservations) => expect(reservations.length, 2),
        );
      });

      test('should return ServerFailure when ServerException is thrown',
          () async {
        when(() => mockDataSource.getReservations())
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.getReservations();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getReservationById', () {
      test('should return reservation when successful', () async {
        final tReservation = createReservationModel();
        when(() => mockDataSource.getReservationById('res-123'))
            .thenAnswer((_) async => tReservation);

        final result = await repository.getReservationById('res-123');

        expect(result.isRight(), true);
        verify(() => mockDataSource.getReservationById('res-123')).called(1);
      });

      test('should return ServerFailure when not found', () async {
        when(() => mockDataSource.getReservationById('res-123'))
            .thenThrow(const ServerException(message: 'Reservation not found'));

        final result = await repository.getReservationById('res-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('cancelReservation', () {
      test('should return CancellationResult when successful', () async {
        final tResult = createCancellationResult();
        when(() => mockDataSource.cancelReservation('res-123'))
            .thenAnswer((_) async => tResult);

        final result = await repository.cancelReservation('res-123');

        expect(result.isRight(), true);
        verify(() => mockDataSource.cancelReservation('res-123')).called(1);
      });

      test('should return ServerFailure when cancellation fails', () async {
        when(() => mockDataSource.cancelReservation('res-123'))
            .thenThrow(const ServerException(message: 'Cannot cancel'));

        final result = await repository.cancelReservation('res-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getVehicles', () {
      test('should return list of vehicles when successful', () async {
        final tVehicles = [
          createVehicleModel(id: 'v-1'),
          createVehicleModel(id: 'v-2'),
        ];
        when(() => mockDataSource.getVehicles())
            .thenAnswer((_) async => tVehicles);

        final result = await repository.getVehicles();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return vehicles'),
          (vehicles) => expect(vehicles.length, 2),
        );
      });

      test('should return ServerFailure when ServerException is thrown',
          () async {
        when(() => mockDataSource.getVehicles())
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.getVehicles();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
