import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/get_notifications_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/notification_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetNotificationsUseCase usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = GetNotificationsUseCase(mockRepository);
  });

  group('GetNotificationsUseCase', () {
    final tNotifications = NotificationFixtures.createList(5);

    test('should return list of notifications when successful', () async {
      // Arrange
      when(() => mockRepository.getNotifications())
          .thenAnswer((_) async => Right(tNotifications));

      // Act
      final result = await usecase();

      // Assert
      expect(result, Right(tNotifications));
      verify(() => mockRepository.getNotifications()).called(1);
    });

    test('should return empty list when no notifications', () async {
      // Arrange
      when(() => mockRepository.getNotifications())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (notifications) => expect(notifications, isEmpty),
      );
    });

    test('should return mixed notification types', () async {
      // Arrange
      final mixedNotifications = NotificationFixtures.createMixedList();
      when(() => mockRepository.getNotifications())
          .thenAnswer((_) async => Right(mixedNotifications));

      // Act
      final result = await usecase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be Right'),
        (notifications) => expect(notifications.length, 5),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      when(() => mockRepository.getNotifications())
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.getNotifications())
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase();

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
