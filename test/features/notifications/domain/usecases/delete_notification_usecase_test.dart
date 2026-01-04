import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/notifications/domain/usecases/delete_notification_usecase.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late DeleteNotificationUseCase usecase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    usecase = DeleteNotificationUseCase(mockRepository);
  });

  group('DeleteNotificationUseCase', () {
    const tNotificationId = 'notif-123';

    test('should delete notification successfully', () async {
      // Arrange
      when(() => mockRepository.deleteNotification(tNotificationId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await usecase(tNotificationId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.deleteNotification(tNotificationId)).called(1);
    });

    test('should return ServerFailure when notification not found', () async {
      // Arrange
      when(() => mockRepository.deleteNotification('invalid-notif'))
          .thenAnswer((_) async => const Left(serverFailure));

      // Act
      final result = await usecase('invalid-notif');

      // Assert
      expect(result, const Left(serverFailure));
    });

    test('should return NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockRepository.deleteNotification(tNotificationId))
          .thenAnswer((_) async => const Left(networkFailure));

      // Act
      final result = await usecase(tNotificationId);

      // Assert
      expect(result, const Left(networkFailure));
    });

    test('should return AuthFailure when not authenticated', () async {
      // Arrange
      when(() => mockRepository.deleteNotification(tNotificationId))
          .thenAnswer((_) async => const Left(authFailure));

      // Act
      final result = await usecase(tNotificationId);

      // Assert
      expect(result, const Left(authFailure));
    });
  });
}
