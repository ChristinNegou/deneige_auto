import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/get_worker_stats_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/worker_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetWorkerStatsUseCase usecase;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
    usecase = GetWorkerStatsUseCase(mockRepository);
  });

  group('GetWorkerStatsUseCase', () {
    final tStats = WorkerFixtures.createWorkerStats();

    test('should return worker stats when successful', () async {
      // Arrange
      when(() => mockRepository.getStats())
          .thenAnswer((_) async => Right(tStats));

      // Act
      final result = await usecase();

      // Assert
      expect(result, Right(tStats));
      verify(() => mockRepository.getStats()).called(1);
    });

    test('should return stats with correct today values', () async {
      // Arrange
      final statsWithToday = WorkerFixtures.createWorkerStats(
        today: WorkerFixtures.createTodayStats(completed: 5, earnings: 125.0),
      );
      when(() => mockRepository.getStats())
          .thenAnswer((_) async => Right(statsWithToday));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (stats) {
          expect(stats.today.completed, 5);
          expect(stats.today.earnings, 125.0);
        },
      );
    });

    test('should return stats when worker is unavailable', () async {
      // Arrange
      final unavailableStats =
          WorkerFixtures.createWorkerStats(isAvailable: false);
      when(() => mockRepository.getStats())
          .thenAnswer((_) async => Right(unavailableStats));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (stats) => expect(stats.isAvailable, false),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getStats())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.getStats())
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
