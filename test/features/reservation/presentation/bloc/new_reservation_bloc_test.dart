import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/reservation/domain/entities/parking_spot.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:deneige_auto/features/reservation/domain/entities/reservation.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/create_reservation_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_parking_spots_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_vehicules_usecase.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_bloc.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_event.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_state.dart';

import '../../../../mocks/mock_usecases.dart';
import '../../../../fixtures/reservation_fixtures.dart';

void main() {
  late NewReservationBloc bloc;
  late MockGetVehiclesUseCase mockGetVehicles;
  late MockGetParkingSpotsUseCase mockGetParkingSpots;
  late MockCreateReservationUseCase mockCreateReservation;

  setUpAll(() {
    registerFallbackValue(CreateReservationParams(
      vehicleId: 'v1',
      parkingSpotId: 'p1',
      departureTime: DateTime.now(),
      deadlineTime: DateTime.now(),
      serviceOptions: const [],
      totalPrice: 25.0,
      paymentMethod: 'card',
    ));
  });

  setUp(() {
    mockGetVehicles = MockGetVehiclesUseCase();
    mockGetParkingSpots = MockGetParkingSpotsUseCase();
    mockCreateReservation = MockCreateReservationUseCase();
    bloc = NewReservationBloc(
      getVehicles: mockGetVehicles,
      getParkingSpots: mockGetParkingSpots,
      createReservation: mockCreateReservation,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('NewReservationBloc', () {
    test('initial state should be NewReservationState with defaults', () {
      expect(bloc.state, const NewReservationState());
      expect(bloc.state.currentStep, 0);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.availableVehicles, isEmpty);
    });

    group('LoadInitialData', () {
      final tVehicles = ReservationFixtures.createVehicleList(2);
      final tParkingSpots = ReservationFixtures.createParkingSpotList(3);

      blocTest<NewReservationBloc, NewReservationState>(
        'emits [loading, loaded] when LoadInitialData succeeds',
        build: () {
          when(() => mockGetVehicles())
              .thenAnswer((_) async => Right(tVehicles));
          when(() => mockGetParkingSpots(availableOnly: true))
              .thenAnswer((_) async => Right(tParkingSpots));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadInitialData()),
        expect: () => [
          const NewReservationState(isLoadingData: true),
          NewReservationState(
            isLoadingData: false,
            availableVehicles: tVehicles,
            availableParkingSpots: tParkingSpots,
          ),
        ],
      );

      blocTest<NewReservationBloc, NewReservationState>(
        'emits empty lists when LoadInitialData fails',
        build: () {
          when(() => mockGetVehicles()).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Error')));
          when(() => mockGetParkingSpots(availableOnly: true)).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Error')));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadInitialData()),
        expect: () => [
          const NewReservationState(isLoadingData: true),
          const NewReservationState(
            isLoadingData: false,
            availableVehicles: [],
            availableParkingSpots: [],
          ),
        ],
      );
    });

    group('SelectVehicle', () {
      final tVehicle = ReservationFixtures.createVehicle();

      blocTest<NewReservationBloc, NewReservationState>(
        'emits state with selected vehicle',
        build: () => bloc,
        act: (bloc) => bloc.add(SelectVehicle(tVehicle)),
        expect: () => [
          NewReservationState(selectedVehicle: tVehicle),
        ],
      );
    });

    group('SelectParkingSpot', () {
      final tParkingSpot = ReservationFixtures.createParkingSpot();

      blocTest<NewReservationBloc, NewReservationState>(
        'emits state with selected parking spot',
        build: () => bloc,
        act: (bloc) => bloc.add(SelectParkingSpot(tParkingSpot)),
        expect: () => [
          NewReservationState(selectedParkingSpot: tParkingSpot),
        ],
      );
    });

    group('UpdateParkingSpotNumber', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'emits state with parking spot number',
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateParkingSpotNumber('A-15')),
        verify: (bloc) {
          expect(bloc.state.parkingSpotNumber, 'A-15');
        },
      );
    });

    group('UpdateCustomLocation', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'emits state with custom location',
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateCustomLocation('123 Rue Main')),
        verify: (bloc) {
          expect(bloc.state.customLocation, '123 Rue Main');
        },
      );
    });

    group('SelectDateTime', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'emits state with selected datetime and calculated deadline',
        build: () => bloc,
        act: (bloc) {
          final departureTime = DateTime.now().add(const Duration(hours: 2));
          bloc.add(SelectDateTime(departureTime));
        },
        verify: (bloc) {
          expect(bloc.state.departureDateTime, isNotNull);
          expect(bloc.state.deadlineTime, isNotNull);
          expect(
            bloc.state.deadlineTime!.isBefore(bloc.state.departureDateTime!),
            true,
          );
        },
      );
    });

    group('ToggleServiceOption', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'adds option when not present',
        build: () {
          // Need to mock for CalculatePrice that gets triggered
          when(() => mockGetVehicles())
              .thenAnswer((_) async => const Right([]));
          when(() => mockGetParkingSpots(availableOnly: true))
              .thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const ToggleServiceOption(ServiceOption.windowScraping)),
        verify: (bloc) {
          expect(bloc.state.selectedOptions,
              contains(ServiceOption.windowScraping));
        },
      );

      blocTest<NewReservationBloc, NewReservationState>(
        'removes option when already present',
        build: () => bloc,
        seed: () => const NewReservationState(
          selectedOptions: [ServiceOption.windowScraping],
        ),
        act: (bloc) =>
            bloc.add(const ToggleServiceOption(ServiceOption.windowScraping)),
        verify: (bloc) {
          expect(bloc.state.selectedOptions, isEmpty);
        },
      );
    });

    group('UpdateSnowDepth', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'emits state with updated snow depth',
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateSnowDepth(15)),
        verify: (bloc) {
          expect(bloc.state.snowDepthCm, 15);
        },
      );
    });

    group('GoToNextStep', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'increments current step when not at last step',
        build: () => bloc,
        seed: () => const NewReservationState(currentStep: 0),
        act: (bloc) => bloc.add(GoToNextStep()),
        expect: () => [
          const NewReservationState(currentStep: 1),
        ],
      );

      blocTest<NewReservationBloc, NewReservationState>(
        'does not increment when at last step (4)',
        build: () => bloc,
        seed: () => const NewReservationState(currentStep: 4),
        act: (bloc) => bloc.add(GoToNextStep()),
        expect: () => [],
      );
    });

    group('GoToPreviousStep', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'decrements current step when not at first step',
        build: () => bloc,
        seed: () => const NewReservationState(currentStep: 2),
        act: (bloc) => bloc.add(GoToPreviousStep()),
        expect: () => [
          const NewReservationState(currentStep: 1),
        ],
      );

      blocTest<NewReservationBloc, NewReservationState>(
        'does not decrement when at first step',
        build: () => bloc,
        seed: () => const NewReservationState(currentStep: 0),
        act: (bloc) => bloc.add(GoToPreviousStep()),
        expect: () => [],
      );
    });

    group('ResetReservation', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'resets state to initial values',
        build: () => bloc,
        seed: () => NewReservationState(
          currentStep: 3,
          selectedVehicle: ReservationFixtures.createVehicle(),
          snowDepthCm: 20,
          isLoading: true,
        ),
        act: (bloc) => bloc.add(ResetReservation()),
        expect: () => [
          const NewReservationState(),
        ],
      );
    });

    group('ClearLocationError', () {
      blocTest<NewReservationBloc, NewReservationState>(
        'clears location error',
        build: () => bloc,
        seed: () => const NewReservationState(
          locationError: 'Some error message',
        ),
        act: (bloc) => bloc.add(ClearLocationError()),
        expect: () => [
          const NewReservationState(locationError: null),
        ],
      );
    });
  });
}
