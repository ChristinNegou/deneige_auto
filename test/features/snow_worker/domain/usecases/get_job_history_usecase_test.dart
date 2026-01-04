import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_job_history_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/entities/worker_job.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/worker_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetJobHistoryUseCase usecase;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
    usecase = GetJobHistoryUseCase(mockRepository);
  });

  group('GetJobHistoryUseCase', () {
    final tCompletedJobs = WorkerFixtures.createJobList(10, status: JobStatus.completed);

    test('should return job history when successful', () async {
      // Arrange
      when(() => mockRepository.getJobHistory(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => Right(tCompletedJobs));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (jobs) => expect(jobs.length, 10),
      );
    });

    test('should return empty list when no job history', () async {
      // Arrange
      when(() => mockRepository.getJobHistory(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (jobs) => expect(jobs, isEmpty),
      );
    });

    test('should pass pagination parameters correctly', () async {
      // Arrange
      when(() => mockRepository.getJobHistory(
        page: 2,
        limit: 50,
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => Right(tCompletedJobs));

      // Act
      final result = await usecase(page: 2, limit: 50);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.getJobHistory(
        page: 2,
        limit: 50,
        startDate: null,
        endDate: null,
      )).called(1);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getJobHistory(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.getJobHistory(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
