import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/job_actions_usecase.dart';
import 'package:deneige_auto/features/snow_worker/domain/entities/worker_job.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/worker_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late AcceptJobUseCase acceptJobUsecase;
  late StartJobUseCase startJobUsecase;
  late CompleteJobUseCase completeJobUsecase;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
    acceptJobUsecase = AcceptJobUseCase(mockRepository);
    startJobUsecase = StartJobUseCase(mockRepository);
    completeJobUsecase = CompleteJobUseCase(mockRepository);
  });

  group('AcceptJobUseCase', () {
    const tJobId = 'job-123';
    final tAssignedJob = WorkerFixtures.createAssignedJob(id: tJobId);

    test('should accept job successfully', () async {
      // Arrange
      when(() => mockRepository.acceptJob(tJobId))
          .thenAnswer((_) async => Right(tAssignedJob));

      // Act
      final result = await acceptJobUsecase(tJobId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (job) {
          expect(job.id, tJobId);
          expect(job.status, JobStatus.assigned);
        },
      );
      verify(() => mockRepository.acceptJob(tJobId)).called(1);
    });

    test('should return ServerFailure when job not found', () async {
      // Arrange
      when(() => mockRepository.acceptJob('invalid-job'))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await acceptJobUsecase('invalid-job');

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return ServerFailure when job already assigned', () async {
      // Arrange
      when(() => mockRepository.acceptJob(tJobId))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await acceptJobUsecase(tJobId);

      // Assert
      expect(result, const Left(serverFailure));
    });
  });

  group('StartJobUseCase', () {
    const tJobId = 'job-123';
    final tInProgressJob = WorkerFixtures.createInProgressJob(id: tJobId);

    test('should start job successfully', () async {
      // Arrange
      when(() => mockRepository.startJob(tJobId))
          .thenAnswer((_) async => Right(tInProgressJob));

      // Act
      final result = await startJobUsecase(tJobId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (job) {
          expect(job.id, tJobId);
          expect(job.status, JobStatus.inProgress);
        },
      );
      verify(() => mockRepository.startJob(tJobId)).called(1);
    });

    test('should return ServerFailure when job cannot be started', () async {
      // Arrange
      when(() => mockRepository.startJob(tJobId))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await startJobUsecase(tJobId);

      // Assert
      expect(result, const Left(serverFailure));
    });
  });

  group('CompleteJobUseCase', () {
    const tJobId = 'job-123';
    final tCompletedJob = WorkerFixtures.createCompletedJob(id: tJobId);

    test('should complete job successfully', () async {
      // Arrange
      when(() => mockRepository.completeJob(
        jobId: tJobId,
        workerNotes: any(named: 'workerNotes'),
      )).thenAnswer((_) async => Right(tCompletedJob));

      // Act
      final result = await completeJobUsecase(jobId: tJobId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (job) {
          expect(job.id, tJobId);
          expect(job.status, JobStatus.completed);
        },
      );
    });

    test('should complete job with notes', () async {
      // Arrange
      when(() => mockRepository.completeJob(
        jobId: tJobId,
        workerNotes: 'Travail bien fait',
      )).thenAnswer((_) async => Right(tCompletedJob));

      // Act
      final result = await completeJobUsecase(
        jobId: tJobId,
        workerNotes: 'Travail bien fait',
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.completeJob(
        jobId: tJobId,
        workerNotes: 'Travail bien fait',
      )).called(1);
    });

    test('should return ServerFailure when job cannot be completed', () async {
      // Arrange
      when(() => mockRepository.completeJob(
        jobId: tJobId,
        workerNotes: any(named: 'workerNotes'),
      )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await completeJobUsecase(jobId: tJobId);

      // Assert
      expect(result, const Left(serverFailure));
    });
  });
}
