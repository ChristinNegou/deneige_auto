import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/snow_worker/domain/repositories/worker_repository.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/toggle_availability_usecase.dart';
import 'package:deneige_auto/features/snow_worker/presentation/bloc/worker_availability_bloc.dart';

import '../../../../fixtures/worker_fixtures.dart';

class MockToggleAvailabilityUseCase extends Mock
    implements ToggleAvailabilityUseCase {}

class MockUpdateLocationUseCase extends Mock implements UpdateLocationUseCase {}

class MockWorkerRepository extends Mock implements WorkerRepository {}

void main() {
  late WorkerAvailabilityBloc bloc;
  late MockToggleAvailabilityUseCase mockToggleAvailability;
  late MockUpdateLocationUseCase mockUpdateLocation;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockToggleAvailability = MockToggleAvailabilityUseCase();
    mockUpdateLocation = MockUpdateLocationUseCase();
    mockRepository = MockWorkerRepository();

    bloc = WorkerAvailabilityBloc(
      toggleAvailabilityUseCase: mockToggleAvailability,
      updateLocationUseCase: mockUpdateLocation,
      repository: mockRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('WorkerAvailabilityBloc', () {
    test('initial state should be WorkerAvailabilityInitial', () {
      expect(bloc.state, const WorkerAvailabilityInitial());
    });

    group('LoadAvailability', () {
      final tProfile = WorkerFixtures.createWorkerProfile(isAvailable: true);

      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'emits [loading, loaded] when LoadAvailability succeeds',
        build: () {
          when(() => mockRepository.getProfile())
              .thenAnswer((_) async => Right(tProfile));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAvailability()),
        expect: () => [
          const WorkerAvailabilityLoading(),
          isA<WorkerAvailabilityLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state as WorkerAvailabilityLoaded;
          expect(state.isAvailable, true);
          expect(state.profile, tProfile);
        },
      );

      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'emits [loading, error] when LoadAvailability fails',
        build: () {
          when(() => mockRepository.getProfile()).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAvailability()),
        expect: () => [
          const WorkerAvailabilityLoading(),
          isA<WorkerAvailabilityError>(),
        ],
      );
    });

    group('ToggleAvailability', () {
      final tProfile = WorkerFixtures.createWorkerProfile(isAvailable: false);

      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'toggles availability from false to true when successful',
        build: () {
          when(() => mockToggleAvailability(true))
              .thenAnswer((_) async => const Right(true));
          return bloc;
        },
        seed: () => WorkerAvailabilityLoaded(
          isAvailable: false,
          profile: tProfile,
        ),
        act: (bloc) => bloc.add(const ToggleAvailability()),
        verify: (bloc) {
          final state = bloc.state as WorkerAvailabilityLoaded;
          expect(state.isAvailable, true);
        },
      );

      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'emits error when toggle fails',
        build: () {
          when(() => mockToggleAvailability(true)).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Error')),
          );
          return bloc;
        },
        seed: () => WorkerAvailabilityLoaded(
          isAvailable: false,
          profile: tProfile,
        ),
        act: (bloc) => bloc.add(const ToggleAvailability()),
        expect: () => [
          isA<WorkerAvailabilityLoaded>(), // isUpdating: true
          isA<WorkerAvailabilityLoaded>(), // isUpdating: false
          isA<WorkerAvailabilityError>(),
        ],
      );

      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'does nothing when not in loaded state',
        build: () => bloc,
        act: (bloc) => bloc.add(const ToggleAvailability()),
        expect: () => [],
      );
    });

    group('UpdateLocation', () {
      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'silently updates location when successful',
        build: () {
          when(() => mockUpdateLocation(
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
              )).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateLocation(
          latitude: 46.34,
          longitude: -72.55,
        )),
        expect: () => [],
        verify: (_) {
          verify(() => mockUpdateLocation(
                latitude: 46.34,
                longitude: -72.55,
              )).called(1);
        },
      );

      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'silently fails when location update fails',
        build: () {
          when(() => mockUpdateLocation(
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
              )).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const UpdateLocation(
          latitude: 46.34,
          longitude: -72.55,
        )),
        expect: () => [],
      );
    });

    group('LoadProfile', () {
      final tProfile = WorkerFixtures.createWorkerProfile();

      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'emits [loading, loaded] when LoadProfile succeeds',
        build: () {
          when(() => mockRepository.getProfile())
              .thenAnswer((_) async => Right(tProfile));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadProfile()),
        expect: () => [
          const WorkerAvailabilityLoading(),
          isA<WorkerAvailabilityLoaded>(),
        ],
      );
    });

    group('UpdateProfile', () {
      final tProfile = WorkerFixtures.createWorkerProfile();
      final tUpdatedProfile = WorkerFixtures.createWorkerProfile(
        maxActiveJobs: 5,
      );

      blocTest<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        'emits success states when UpdateProfile succeeds',
        build: () {
          when(() => mockRepository.updateProfile(
                preferredZones: any(named: 'preferredZones'),
                equipmentList: any(named: 'equipmentList'),
                vehicleType: any(named: 'vehicleType'),
                maxActiveJobs: any(named: 'maxActiveJobs'),
              )).thenAnswer((_) async => Right(tUpdatedProfile));
          return bloc;
        },
        seed: () => WorkerAvailabilityLoaded(
          isAvailable: true,
          profile: tProfile,
        ),
        act: (bloc) => bloc.add(const UpdateProfile(maxActiveJobs: 5)),
        expect: () => [
          isA<WorkerAvailabilityLoaded>(), // isUpdating: true
          isA<WorkerProfileUpdated>(),
          isA<WorkerAvailabilityLoaded>(), // with updated profile
        ],
      );
    });
  });
}
