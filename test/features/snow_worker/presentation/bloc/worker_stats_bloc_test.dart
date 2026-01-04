import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/snow_worker/presentation/bloc/worker_stats_bloc.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_worker_stats_usecase.dart';

import '../../../../mocks/mock_usecases.dart';
import '../../../../fixtures/worker_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

class MockGetEarningsUseCase extends Mock implements GetEarningsUseCase {}

void main() {
  late WorkerStatsBloc bloc;
  late MockGetWorkerStatsUseCase mockGetWorkerStats;
  late MockGetEarningsUseCase mockGetEarnings;

  setUp(() {
    mockGetWorkerStats = MockGetWorkerStatsUseCase();
    mockGetEarnings = MockGetEarningsUseCase();
    bloc = WorkerStatsBloc(
      getWorkerStatsUseCase: mockGetWorkerStats,
      getEarningsUseCase: mockGetEarnings,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('WorkerStatsBloc', () {
    final tStats = WorkerFixtures.createWorkerStats();

    group('LoadStats', () {
      blocTest<WorkerStatsBloc, WorkerStatsState>(
        'emits [loading, loaded] when LoadStats succeeds',
        build: () {
          when(() => mockGetWorkerStats())
              .thenAnswer((_) async => Right(tStats));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadStats()),
        expect: () => [
          isA<WorkerStatsLoading>(),
          isA<WorkerStatsLoaded>().having((s) => s.stats, 'stats', tStats),
        ],
        verify: (_) {
          verify(() => mockGetWorkerStats()).called(1);
        },
      );

      blocTest<WorkerStatsBloc, WorkerStatsState>(
        'emits [loading, error] when LoadStats fails',
        build: () {
          when(() => mockGetWorkerStats())
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadStats()),
        expect: () => [
          isA<WorkerStatsLoading>(),
          isA<WorkerStatsError>()
              .having((s) => s.message, 'message', serverFailure.message),
        ],
      );
    });

    group('RefreshStats', () {
      blocTest<WorkerStatsBloc, WorkerStatsState>(
        'emits updated stats when RefreshStats succeeds',
        build: () {
          when(() => mockGetWorkerStats())
              .thenAnswer((_) async => Right(tStats));
          return bloc;
        },
        seed: () => WorkerStatsLoaded(stats: tStats),
        act: (bloc) => bloc.add(const RefreshStats()),
        expect: () => [
          isA<WorkerStatsLoaded>()
              .having((s) => s.isRefreshing, 'isRefreshing', true),
          isA<WorkerStatsLoaded>()
              .having((s) => s.isRefreshing, 'isRefreshing', false)
              .having((s) => s.stats, 'stats', tStats),
        ],
      );

      blocTest<WorkerStatsBloc, WorkerStatsState>(
        'emits error when RefreshStats fails',
        build: () {
          when(() => mockGetWorkerStats())
              .thenAnswer((_) async => const Left(networkFailure));
          return bloc;
        },
        seed: () => WorkerStatsLoaded(stats: tStats),
        act: (bloc) => bloc.add(const RefreshStats()),
        expect: () => [
          isA<WorkerStatsLoaded>()
              .having((s) => s.isRefreshing, 'isRefreshing', true),
          isA<WorkerStatsLoaded>()
              .having((s) => s.isRefreshing, 'isRefreshing', false),
          isA<WorkerStatsError>(),
        ],
      );
    });

    group('State values', () {
      test('WorkerStatsLoaded copyWith works correctly', () {
        final loaded = WorkerStatsLoaded(stats: tStats);
        final updated = loaded.copyWith(isRefreshing: true);

        expect(updated.isRefreshing, true);
        expect(updated.stats, tStats);
      });

      test('WorkerStatsInitial is initial state', () {
        expect(bloc.state, isA<WorkerStatsInitial>());
      });
    });
  });
}
