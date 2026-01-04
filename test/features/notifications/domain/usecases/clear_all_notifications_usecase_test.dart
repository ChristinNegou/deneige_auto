import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/clear_all_notifications_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late ClearAllNotificationsUseCase usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = ClearAllNotificationsUseCase(mockRepository);
  });

  group('ClearAllNotificationsUseCase', () {
    test('should clear all notifications successfully', () async {
      // Arrange
      when(() => mockRepository.clearAllNotifications())
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.clearAllNotifications()).called(1);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.clearAllNotifications())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.clearAllNotifications())
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(networkFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.clearAllNotifications())
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
