import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_my_jobs_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/entities/worker_job.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/worker_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetMyJobsUseCase usecase;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
    usecase = GetMyJobsUseCase(mockRepository);
  });

  group('GetMyJobsUseCase', () {
    final tAssignedJobs = WorkerFixtures.createJobList(3, status: JobStatus.assigned);

    test('should return list of my jobs when successful', () async {
      // Arrange
      when(() => mockRepository.getMyJobs())
          .thenAnswer((_) async => Right(tAssignedJobs));

      // Act
      final result = await usecase();

      // Assert
      expect(result, Right(tAssignedJobs));
      verify(() => mockRepository.getMyJobs()).called(1);
    });

    test('should return empty list when no assigned jobs', () async {
      // Arrange
      when(() => mockRepository.getMyJobs())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (jobs) => expect(jobs, isEmpty),
      );
    });

    test('should return jobs with different statuses', () async {
      // Arrange
      final mixedJobs = [
        WorkerFixtures.createAssignedJob(id: 'job-1'),
        WorkerFixtures.createInProgressJob(id: 'job-2'),
      ];
      when(() => mockRepository.getMyJobs())
          .thenAnswer((_) async => Right(mixedJobs));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (jobs) {
          expect(jobs.length, 2);
          expect(jobs.any((j) => j.status == JobStatus.assigned), true);
          expect(jobs.any((j) => j.status == JobStatus.inProgress), true);
        },
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getMyJobs())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.getMyJobs())
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
