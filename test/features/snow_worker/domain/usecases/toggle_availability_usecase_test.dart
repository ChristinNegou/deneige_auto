import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/snow_worker/domain/usecases/toggle_availability_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late ToggleAvailabilityUseCase usecase;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
    usecase = ToggleAvailabilityUseCase(mockRepository);
  });

  group('ToggleAvailabilityUseCase', () {
    test('should toggle availability to true successfully', () async {
      // Arrange
      when(() => mockRepository.toggleAvailability(true))
          .thenAnswer((_) async => const Right(true));

      // Act
      final result = await usecase(true);

      // Assert
      expect(result, const Right(true));
      verify(() => mockRepository.toggleAvailability(true)).called(1);
    });

    test('should toggle availability to false successfully', () async {
      // Arrange
      when(() => mockRepository.toggleAvailability(false))
          .thenAnswer((_) async => const Right(false));

      // Act
      final result = await usecase(false);

      // Assert
      expect(result, const Right(false));
      verify(() => mockRepository.toggleAvailability(false)).called(1);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.toggleAvailability(any()))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase(true);

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.toggleAvailability(any()))
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(true);

      // Assert
      expect(result, const Left(networkFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.toggleAvailability(any()))
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase(true);

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
