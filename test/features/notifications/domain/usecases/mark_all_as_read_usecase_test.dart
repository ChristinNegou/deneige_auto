import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/mark_all_as_read_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late MarkAllAsReadUseCase usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = MarkAllAsReadUseCase(mockRepository);
  });

  group('MarkAllAsReadUseCase', () {
    test('should mark all notifications as read successfully', () async {
      // Arrange
      when(() => mockRepository.markAllAsRead())
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.markAllAsRead()).called(1);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.markAllAsRead())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.markAllAsRead())
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(networkFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.markAllAsRead())
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
