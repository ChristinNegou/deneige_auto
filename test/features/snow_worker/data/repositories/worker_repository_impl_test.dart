import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/errors/exceptions.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/snow_worker/data/repositories/worker_repository_impl.dart';
import 'package:deneige_auto/features/snow_worker/data/models/worker_stats_model.dart';
import 'package:deneige_auto/features/snow_worker/data/models/worker_job_model.dart';
import 'package:deneige_auto/features/snow_worker/domain/entities/worker_job.dart';

import '../../../../mocks/mock_datasources.dart';

void main() {
  late WorkerRepositoryImpl repository;
  late MockWorkerRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockWorkerRemoteDataSource();
    repository = WorkerRepositoryImpl(remoteDataSource: mockDataSource);
  });

  // Helper pour creer un WorkerStatsModel
  WorkerStatsModel createStatsModel() {
    return const WorkerStatsModel(
      today: TodayStatsModel(
        completed: 3,
        inProgress: 1,
        assigned: 2,
        earnings: 75.0,
        tips: 15.0,
      ),
      week: PeriodStatsModel(completed: 15, earnings: 375.0, tips: 75.0),
      month: PeriodStatsModel(completed: 45, earnings: 1125.0, tips: 225.0),
      allTime: AllTimeStatsModel(
        completed: 150,
        earnings: 3750.0,
        tips: 750.0,
        averageRating: 4.8,
        totalRatings: 120,
      ),
      isAvailable: true,
    );
  }

  // Helper pour creer un WorkerJobModel
  WorkerJobModel createJobModel({String id = 'job-123'}) {
    return WorkerJobModel(
      id: id,
      client: const ClientInfoModel(
        id: 'client-123',
        firstName: 'Jean',
        lastName: 'Dupont',
        phoneNumber: '514-555-1234',
      ),
      vehicle: const VehicleInfoModel(
        id: 'vehicle-123',
        make: 'Honda',
        model: 'Civic',
        color: 'Noir',
        licensePlate: 'ABC 123',
      ),
      location: const JobLocationModel(
        latitude: 46.3432,
        longitude: -72.5476,
        address: '123 Rue Principale, Trois-Rivieres',
      ),
      parkingSpotNumber: 'A-15',
      distanceKm: 2.5,
      departureTime: DateTime(2024, 1, 15, 12, 0),
      deadlineTime: DateTime(2024, 1, 15, 11, 30),
      serviceOptions: const [ServiceOption.windowScraping],
      totalPrice: 25.0,
      isPriority: false,
      snowDepthCm: 10,
      status: JobStatus.pending,
      createdAt: DateTime(2024, 1, 15, 10, 0),
    );
  }

  group('WorkerRepositoryImpl', () {
    group('getStats', () {
      test('should return worker stats when successful', () async {
        final tStats = createStatsModel();
        when(() => mockDataSource.getStats())
            .thenAnswer((_) async => tStats);

        final result = await repository.getStats();

        expect(result.isRight(), true);
        verify(() => mockDataSource.getStats()).called(1);
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.getStats())
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.getStats();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return ServerFailure when AuthException is thrown', () async {
        // Note: WorkerRepositoryImpl doesn't catch AuthException specifically,
        // it only catches DioException. Other exceptions fall through to ServerFailure.
        when(() => mockDataSource.getStats())
            .thenThrow(const AuthException(message: 'Not authenticated'));

        final result = await repository.getStats();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getAvailableJobs', () {
      test('should return list of available jobs when successful', () async {
        final tJobs = [createJobModel(id: 'job-1'), createJobModel(id: 'job-2')];
        when(() => mockDataSource.getAvailableJobs(
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              radiusKm: any(named: 'radiusKm'),
            )).thenAnswer((_) async => tJobs);

        final result = await repository.getAvailableJobs(
          latitude: 46.34,
          longitude: -72.55,
          radiusKm: 10,
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return jobs'),
          (jobs) => expect(jobs.length, 2),
        );
      });

      test('should return ServerFailure when NetworkException is thrown', () async {
        // Note: WorkerRepositoryImpl doesn't catch NetworkException specifically,
        // it only catches DioException. Other exceptions fall through to ServerFailure.
        when(() => mockDataSource.getAvailableJobs(
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              radiusKm: any(named: 'radiusKm'),
            )).thenThrow(const NetworkException(message: 'No connection'));

        final result = await repository.getAvailableJobs(
          latitude: 46.34,
          longitude: -72.55,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getMyJobs', () {
      test('should return list of my jobs when successful', () async {
        final tJobs = [createJobModel(id: 'job-1'), createJobModel(id: 'job-2')];
        when(() => mockDataSource.getMyJobs())
            .thenAnswer((_) async => tJobs);

        final result = await repository.getMyJobs();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return jobs'),
          (jobs) => expect(jobs.length, 2),
        );
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.getMyJobs())
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.getMyJobs();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('toggleAvailability', () {
      test('should return Right(true) when toggling on', () async {
        when(() => mockDataSource.toggleAvailability(true))
            .thenAnswer((_) async => true);

        final result = await repository.toggleAvailability(true);

        expect(result, const Right(true));
        verify(() => mockDataSource.toggleAvailability(true)).called(1);
      });

      test('should return Right(false) when toggling off', () async {
        when(() => mockDataSource.toggleAvailability(false))
            .thenAnswer((_) async => false);

        final result = await repository.toggleAvailability(false);

        expect(result, const Right(false));
        verify(() => mockDataSource.toggleAvailability(false)).called(1);
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.toggleAvailability(true))
            .thenThrow(const ServerException(message: 'Toggle failed'));

        final result = await repository.toggleAvailability(true);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('acceptJob', () {
      test('should return WorkerJob when successful', () async {
        final tJob = createJobModel();
        when(() => mockDataSource.acceptJob('job-123'))
            .thenAnswer((_) async => tJob);

        final result = await repository.acceptJob('job-123');

        expect(result.isRight(), true);
        verify(() => mockDataSource.acceptJob('job-123')).called(1);
      });

      test('should return ServerFailure when job not found', () async {
        when(() => mockDataSource.acceptJob('job-123'))
            .thenThrow(const ServerException(message: 'Job not found'));

        final result = await repository.acceptJob('job-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('completeJob', () {
      test('should return WorkerJob when successful', () async {
        final tJob = createJobModel();
        when(() => mockDataSource.completeJob(jobId: 'job-123'))
            .thenAnswer((_) async => tJob);

        final result = await repository.completeJob(jobId: 'job-123');

        expect(result.isRight(), true);
        verify(() => mockDataSource.completeJob(jobId: 'job-123')).called(1);
      });

      test('should return ServerFailure when job cannot be completed', () async {
        when(() => mockDataSource.completeJob(jobId: 'job-123'))
            .thenThrow(const ServerException(message: 'Cannot complete job'));

        final result = await repository.completeJob(jobId: 'job-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getJobHistory', () {
      test('should return list of job history when successful', () async {
        final tJobs = [createJobModel(id: 'job-1'), createJobModel(id: 'job-2')];
        when(() => mockDataSource.getJobHistory(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => tJobs);

        final result = await repository.getJobHistory();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return jobs'),
          (jobs) => expect(jobs.length, 2),
        );
      });

      test('should return ServerFailure when not authenticated', () async {
        // Note: WorkerRepositoryImpl doesn't catch AuthException specifically,
        // it only catches DioException. Other exceptions fall through to ServerFailure.
        when(() => mockDataSource.getJobHistory(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenThrow(const AuthException(message: 'Not authenticated'));

        final result = await repository.getJobHistory();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
