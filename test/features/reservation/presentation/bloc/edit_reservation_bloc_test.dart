import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/update_reservation_usecase.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/edit_reservation_bloc.dart';

import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../mocks/mock_usecases.dart';

void main() {
  late MockGetVehiclesUseCase getVehicles;
  late MockGetParkingSpotsUseCase getParkingSpots;
  late MockUpdateReservationUseCase updateReservation;

  final paid = ReservationFixtures.createPending(
    serviceOptions: [ServiceOption.windowScraping],
    totalPrice: 29.03,
  );

  setUpAll(() {
    registerFallbackValue(UpdateReservationParams(
      reservationId: 'r',
      vehicleId: 'v',
      parkingSpotId: 'p',
      departureTime: DateTime.now(),
      deadlineTime: DateTime.now(),
      serviceOptions: const [],
      totalPrice: 0,
    ));
  });

  setUp(() {
    getVehicles = MockGetVehiclesUseCase();
    getParkingSpots = MockGetParkingSpotsUseCase();
    updateReservation = MockUpdateReservationUseCase();
    when(() => getVehicles()).thenAnswer((_) async => Right([paid.vehicle]));
    when(() => getParkingSpots(availableOnly: any(named: 'availableOnly')))
        .thenAnswer((_) async => Right([paid.parkingSpot]));
    when(() => updateReservation(any())).thenAnswer((_) async => Right(paid));
  });

  EditReservationBloc build() => EditReservationBloc(
        getVehicles: getVehicles,
        getParkingSpots: getParkingSpots,
        updateReservation: updateReservation,
      );

  blocTest<EditReservationBloc, EditReservationState>(
    'keeps the paid price when an option is added',
    build: build,
    act: (bloc) async {
      bloc.add(LoadEditReservationData(paid));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ToggleServiceOptionEdit(ServiceOption.roofClearing));
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.calculatedPrice, 29.03);
      expect(bloc.state.changesPrice, true);
    },
  );

  blocTest<EditReservationBloc, EditReservationState>(
    'does not send a change that would alter the price',
    build: build,
    act: (bloc) async {
      bloc.add(LoadEditReservationData(paid));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ToggleServiceOptionEdit(ServiceOption.roofClearing));
      await Future<void>.delayed(Duration.zero);
      bloc.add(SubmitReservationUpdate());
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) => verifyNever(() => updateReservation(any())),
  );

  blocTest<EditReservationBloc, EditReservationState>(
    'saves a new departure time at the same price',
    build: build,
    act: (bloc) async {
      bloc.add(LoadEditReservationData(paid));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
          UpdateDepartureTime(DateTime.now().add(const Duration(hours: 5))));
      await Future<void>.delayed(Duration.zero);
      bloc.add(SubmitReservationUpdate());
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.changesPrice, false);
      final params = verify(() => updateReservation(captureAny()))
          .captured
          .single as UpdateReservationParams;
      expect(params.totalPrice, 29.03);
    },
  );

  blocTest<EditReservationBloc, EditReservationState>(
    'blocks saving while a typed address has not been picked from the list',
    build: build,
    act: (bloc) async {
      bloc.add(LoadEditReservationData(paid));
      await Future<void>.delayed(Duration.zero);
      bloc.add(AddressEdited());
      await Future<void>.delayed(Duration.zero);
      bloc.add(SubmitReservationUpdate());
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.canSubmit, false);
      verifyNever(() => updateReservation(any()));
    },
  );

  blocTest<EditReservationBloc, EditReservationState>(
    'saves the picked address with its coordinates',
    build: build,
    act: (bloc) async {
      bloc.add(LoadEditReservationData(paid));
      await Future<void>.delayed(Duration.zero);
      bloc.add(AddressEdited());
      bloc.add(const UpdateLocationAddress(
          address: '12 Rue des Forges, Trois-Rivières',
          latitude: 46.34,
          longitude: -72.54));
      await Future<void>.delayed(Duration.zero);
      bloc.add(SubmitReservationUpdate());
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) {
      final params = verify(() => updateReservation(captureAny()))
          .captured
          .single as UpdateReservationParams;
      expect(params.address, '12 Rue des Forges, Trois-Rivières');
      expect(params.latitude, 46.34);
    },
  );
}
