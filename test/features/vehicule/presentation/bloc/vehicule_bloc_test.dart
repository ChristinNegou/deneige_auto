import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/vehicule/presentation/bloc/vehicule_bloc.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/add_vehicle_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../mocks/mock_usecases.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

// Fake classes for registerFallbackValue
class FakeAddVehicleParams extends Fake implements AddVehicleParams {}

void main() {
  late VehicleBloc bloc;
  late MockGetVehiclesUseCase mockGetVehicles;
  late MockAddVehicleUseCase mockAddVehicle;
  late MockDeleteVehicleUseCase mockDeleteVehicle;
  late MockReservationRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeAddVehicleParams());
    registerFallbackValue(VehicleType.car);
  });

  setUp(() {
    mockGetVehicles = MockGetVehiclesUseCase();
    mockAddVehicle = MockAddVehicleUseCase();
    mockDeleteVehicle = MockDeleteVehicleUseCase();
    mockRepository = MockReservationRepository();
    bloc = VehicleBloc(
      getVehicles: mockGetVehicles,
      addVehicle: mockAddVehicle,
      deleteVehicle: mockDeleteVehicle,
      repository: mockRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('VehicleBloc', () {
    final tVehicles = ReservationFixtures.createVehicleList(3);
    final tVehicle = ReservationFixtures.createVehicle();

    group('LoadVehicles', () {
      blocTest<VehicleBloc, VehicleState>(
        'emits [loading, loaded] when LoadVehicles succeeds',
        build: () {
          when(() => mockGetVehicles())
              .thenAnswer((_) async => Right(tVehicles));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadVehicles()),
        expect: () => [
          isA<VehicleState>().having((s) => s.isLoading, 'isLoading', true),
          isA<VehicleState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.vehicles.length, 'vehicles.length', 3)
              .having((s) => s.errorMessage, 'errorMessage', null),
        ],
        verify: (_) {
          verify(() => mockGetVehicles()).called(1);
        },
      );

      blocTest<VehicleBloc, VehicleState>(
        'emits [loading, error] when LoadVehicles fails',
        build: () {
          when(() => mockGetVehicles())
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadVehicles()),
        expect: () => [
          isA<VehicleState>().having((s) => s.isLoading, 'isLoading', true),
          isA<VehicleState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having(
                  (s) => s.errorMessage, 'errorMessage', serverFailure.message),
        ],
      );

      blocTest<VehicleBloc, VehicleState>(
        'emits empty list when no vehicles',
        build: () {
          when(() => mockGetVehicles())
              .thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadVehicles()),
        expect: () => [
          isA<VehicleState>().having((s) => s.isLoading, 'isLoading', true),
          isA<VehicleState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.vehicles, 'vehicles', isEmpty),
        ],
      );
    });

    group('AddVehicle', () {
      final tParams = AddVehicleParams(
        make: 'Honda',
        model: 'Civic',
        year: 2022,
        color: 'Noir',
        licensePlate: 'ABC 123',
        type: VehicleType.car,
        isDefault: false,
      );

      blocTest<VehicleBloc, VehicleState>(
        'emits success when AddVehicle succeeds',
        build: () {
          when(() => mockAddVehicle(any()))
              .thenAnswer((_) async => Right(tVehicle));
          return bloc;
        },
        act: (bloc) => bloc.add(AddVehicle(tParams)),
        expect: () => [
          isA<VehicleState>()
              .having((s) => s.isSubmitting, 'isSubmitting', true),
          isA<VehicleState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.successMessage, 'successMessage', isNotNull)
              .having((s) => s.vehicles.length, 'vehicles.length', 1),
        ],
      );

      blocTest<VehicleBloc, VehicleState>(
        'emits error when AddVehicle fails',
        build: () {
          when(() => mockAddVehicle(any()))
              .thenAnswer((_) async => const Left(validationFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(AddVehicle(tParams)),
        expect: () => [
          isA<VehicleState>()
              .having((s) => s.isSubmitting, 'isSubmitting', true),
          isA<VehicleState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );
    });

    group('DeleteVehicle', () {
      blocTest<VehicleBloc, VehicleState>(
        'removes vehicle when DeleteVehicle succeeds',
        build: () {
          when(() => mockDeleteVehicle('vehicle-0'))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => VehicleState(vehicles: tVehicles),
        act: (bloc) => bloc.add(const DeleteVehicle('vehicle-0')),
        expect: () => [
          isA<VehicleState>()
              .having((s) => s.isSubmitting, 'isSubmitting', true),
          isA<VehicleState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.successMessage, 'successMessage', isNotNull)
              .having((s) => s.vehicles.length, 'vehicles.length', 2),
        ],
        verify: (_) {
          verify(() => mockDeleteVehicle('vehicle-0')).called(1);
        },
      );

      blocTest<VehicleBloc, VehicleState>(
        'emits error when DeleteVehicle fails',
        build: () {
          when(() => mockDeleteVehicle('vehicle-123'))
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        seed: () => VehicleState(vehicles: tVehicles),
        act: (bloc) => bloc.add(const DeleteVehicle('vehicle-123')),
        expect: () => [
          isA<VehicleState>()
              .having((s) => s.isSubmitting, 'isSubmitting', true),
          isA<VehicleState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having(
                  (s) => s.errorMessage, 'errorMessage', serverFailure.message),
        ],
      );
    });

    group('State', () {
      test('initial state has empty vehicles', () {
        expect(bloc.state.vehicles, isEmpty);
        expect(bloc.state.isLoading, false);
        expect(bloc.state.isSubmitting, false);
      });

      test('copyWith works correctly', () {
        const initial = VehicleState();
        final updated = initial.copyWith(
          isLoading: true,
          errorMessage: 'Error',
        );

        expect(updated.isLoading, true);
        expect(updated.errorMessage, 'Error');
        expect(updated.vehicles, isEmpty);
      });

      test('copyWith clearError works', () {
        const withError = VehicleState(errorMessage: 'Error');
        final cleared = withError.copyWith(clearError: true);

        expect(cleared.errorMessage, null);
      });
    });
  });
}
