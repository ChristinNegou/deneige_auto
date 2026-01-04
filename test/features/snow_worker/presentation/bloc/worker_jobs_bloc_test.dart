import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_available_jobs_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_my_jobs_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_job_history_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/job_actions_usecase.dart';
import 'package:deneige_auto/features/snow_worker/presentation/bloc/worker_jobs_bloc.dart';

import '../../../../fixtures/worker_fixtures.dart';

class MockGetAvailableJobsUseCase extends Mock implements GetAvailableJobsUseCase {}
class MockGetMyJobsUseCase extends Mock implements GetMyJobsUseCase {}
class MockGetJobHistoryUseCase extends Mock implements GetJobHistoryUseCase {}
class MockAcceptJobUseCase extends Mock implements AcceptJobUseCase {}
class MockMarkEnRouteUseCase extends Mock implements MarkEnRouteUseCase {}
class MockStartJobUseCase extends Mock implements StartJobUseCase {}
class MockCompleteJobUseCase extends Mock implements CompleteJobUseCase {}

void main() {
  late WorkerJobsBloc bloc;
  late MockGetAvailableJobsUseCase mockGetAvailableJobs;
  late MockGetMyJobsUseCase mockGetMyJobs;
  late MockGetJobHistoryUseCase mockGetJobHistory;
  late MockAcceptJobUseCase mockAcceptJob;
  late MockMarkEnRouteUseCase mockMarkEnRoute;
  late MockStartJobUseCase mockStartJob;
  late MockCompleteJobUseCase mockCompleteJob;

  setUp(() {
    mockGetAvailableJobs = MockGetAvailableJobsUseCase();
    mockGetMyJobs = MockGetMyJobsUseCase();
    mockGetJobHistory = MockGetJobHistoryUseCase();
    mockAcceptJob = MockAcceptJobUseCase();
    mockMarkEnRoute = MockMarkEnRouteUseCase();
    mockStartJob = MockStartJobUseCase();
    mockCompleteJob = MockCompleteJobUseCase();

    bloc = WorkerJobsBloc(
      getAvailableJobsUseCase: mockGetAvailableJobs,
      getMyJobsUseCase: mockGetMyJobs,
      getJobHistoryUseCase: mockGetJobHistory,
      acceptJobUseCase: mockAcceptJob,
      markEnRouteUseCase: mockMarkEnRoute,
      startJobUseCase: mockStartJob,
      completeJobUseCase: mockCompleteJob,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('WorkerJobsBloc', () {
    test('initial state should be WorkerJobsInitial', () {
      expect(bloc.state, const WorkerJobsInitial());
    });

    group('LoadAvailableJobs', () {
      final tJobs = WorkerFixtures.createWorkerJobList(3);

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits [loading, loaded] when LoadAvailableJobs succeeds',
        build: () {
          when(() => mockGetAvailableJobs(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
          )).thenAnswer((_) async => Right(tJobs));
          when(() => mockGetMyJobs()).thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAvailableJobs(
          latitude: 46.34,
          longitude: -72.55,
        )),
        expect: () => [
          const WorkerJobsLoading(),
          isA<WorkerJobsLoaded>(),
        ],
      );

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits [loading, error] when LoadAvailableJobs fails',
        build: () {
          when(() => mockGetAvailableJobs(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
          )).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
          // Also stub getMyJobs since it's called after getAvailableJobs
          when(() => mockGetMyJobs()).thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAvailableJobs(
          latitude: 46.34,
          longitude: -72.55,
        )),
        expect: () => [
          const WorkerJobsLoading(),
          isA<WorkerJobsError>(),
        ],
      );
    });

    group('LoadMyJobs', () {
      final tJobs = WorkerFixtures.createWorkerJobList(2);

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits loaded state when LoadMyJobs succeeds',
        build: () {
          when(() => mockGetMyJobs()).thenAnswer((_) async => Right(tJobs));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadMyJobs()),
        expect: () => [
          const WorkerJobsLoading(),
          isA<WorkerJobsLoaded>(),
        ],
      );

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits error when LoadMyJobs fails',
        build: () {
          when(() => mockGetMyJobs()).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadMyJobs()),
        expect: () => [
          const WorkerJobsLoading(),
          isA<WorkerJobsError>(),
        ],
      );
    });

    group('LoadJobHistory', () {
      final tJobs = WorkerFixtures.createWorkerJobList(5);

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits [loading, history loaded] when LoadJobHistory succeeds',
        build: () {
          when(() => mockGetJobHistory(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(tJobs));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadJobHistory()),
        expect: () => [
          const WorkerJobsLoading(),
          isA<JobHistoryLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state as JobHistoryLoaded;
          expect(state.jobs.length, 5);
          expect(state.currentPage, 1);
        },
      );

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits error when LoadJobHistory fails',
        build: () {
          when(() => mockGetJobHistory(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadJobHistory()),
        expect: () => [
          const WorkerJobsLoading(),
          isA<WorkerJobsError>(),
        ],
      );
    });

    group('AcceptJob', () {
      final tJob = WorkerFixtures.createWorkerJob();

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits success states when AcceptJob succeeds',
        build: () {
          when(() => mockAcceptJob('job-123'))
              .thenAnswer((_) async => Right(tJob));
          return bloc;
        },
        act: (bloc) => bloc.add(const AcceptJob('job-123')),
        expect: () => [
          isA<JobActionLoading>(),
          isA<JobActionSuccess>(),
          isA<WorkerJobsLoaded>(),
        ],
      );

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits error when AcceptJob fails',
        build: () {
          when(() => mockAcceptJob('job-123')).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AcceptJob('job-123')),
        expect: () => [
          isA<JobActionLoading>(),
          isA<WorkerJobsError>(),
        ],
      );
    });

    group('StartJob', () {
      final tJob = WorkerFixtures.createWorkerJob();

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits success states when StartJob succeeds',
        build: () {
          when(() => mockStartJob('job-123'))
              .thenAnswer((_) async => Right(tJob));
          return bloc;
        },
        act: (bloc) => bloc.add(const StartJob('job-123')),
        expect: () => [
          isA<JobActionLoading>(),
          isA<JobActionSuccess>(),
          isA<WorkerJobsLoaded>(),
        ],
      );
    });

    group('CompleteJob', () {
      final tJob = WorkerFixtures.createWorkerJob();

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'emits success states when CompleteJob succeeds',
        build: () {
          when(() => mockCompleteJob(
            jobId: any(named: 'jobId'),
            workerNotes: any(named: 'workerNotes'),
          )).thenAnswer((_) async => Right(tJob));
          return bloc;
        },
        act: (bloc) => bloc.add(const CompleteJob('job-123')),
        expect: () => [
          isA<JobActionLoading>(),
          isA<JobActionSuccess>(),
          isA<WorkerJobsLoaded>(),
        ],
      );
    });

    group('SelectActiveJob', () {
      final tJob = WorkerFixtures.createWorkerJob();

      blocTest<WorkerJobsBloc, WorkerJobsState>(
        'updates active job in loaded state',
        build: () => bloc,
        seed: () => const WorkerJobsLoaded(
          availableJobs: [],
          myJobs: [],
        ),
        act: (bloc) => bloc.add(SelectActiveJob(tJob)),
        verify: (bloc) {
          final state = bloc.state as WorkerJobsLoaded;
          expect(state.activeJob, tJob);
        },
      );
    });
  });
}
