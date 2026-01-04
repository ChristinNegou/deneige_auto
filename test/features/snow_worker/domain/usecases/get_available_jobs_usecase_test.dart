import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_available_jobs_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/worker_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetAvailableJobsUseCase usecase;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
    usecase = GetAvailableJobsUseCase(mockRepository);
  });

  group('GetAvailableJobsUseCase', () {
    const tLatitude = 46.3432;
    const tLongitude = -72.5476;
    const tRadiusKm = 10.0;
    final tJobs = WorkerFixtures.createJobList(5);

    test('should return list of available jobs when successful', () async {
      // Arrange
      when(() => mockRepository.getAvailableJobs(
        latitude: tLatitude,
        longitude: tLongitude,
        radiusKm: tRadiusKm,
      )).thenAnswer((_) async => Right(tJobs));

      // Act
      final result = await usecase(
        latitude: tLatitude,
        longitude: tLongitude,
        radiusKm: tRadiusKm,
      );

      // Assert
      expect(result, Right(tJobs));
      verify(() => mockRepository.getAvailableJobs(
        latitude: tLatitude,
        longitude: tLongitude,
        radiusKm: tRadiusKm,
      )).called(1);
    });

    test('should return empty list when no available jobs', () async {
      // Arrange
      when(() => mockRepository.getAvailableJobs(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radiusKm: any(named: 'radiusKm'),
      )).thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase(
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (jobs) => expect(jobs, isEmpty),
      );
    });

    test('should use default radius when not specified', () async {
      // Arrange
      when(() => mockRepository.getAvailableJobs(
        latitude: tLatitude,
        longitude: tLongitude,
        radiusKm: 10,
      )).thenAnswer((_) async => Right(tJobs));

      // Act
      final result = await usecase(
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // Assert
      expect(result.isRight(), true);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getAvailableJobs(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radiusKm: any(named: 'radiusKm'),
      )).thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.getAvailableJobs(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radiusKm: any(named: 'radiusKm'),
      )).thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(
        latitude: tLatitude,
        longitude: tLongitude,
      );

      // Assert
      expect(result, const Left(networkFailure));
    });
  });
}
