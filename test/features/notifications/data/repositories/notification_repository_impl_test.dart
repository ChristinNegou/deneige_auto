import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/errors/exceptions.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:deneige_auto/features/notifications/data/models/notification_model.dart';
import 'package:deneige_auto/features/notifications/domain/entities/notification.dart';

import '../../../../mocks/mock_datasources.dart';

void main() {
  late NotificationRepositoryImpl repository;
  late MockNotificationRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockNotificationRemoteDataSource();
    repository = NotificationRepositoryImpl(remoteDataSource: mockDataSource);
  });

  // Helper pour creer des NotificationModel
  NotificationModel createNotificationModel({
    String id = 'notif-123',
    bool isRead = false,
  }) {
    return NotificationModel(
      id: id,
      userId: 'user-123',
      type: NotificationType.workCompleted,
      title: 'Test Notification',
      message: 'This is a test notification',
      isRead: isRead,
      createdAt: DateTime(2024, 1, 15, 10, 0),
    );
  }

  group('NotificationRepositoryImpl', () {
    group('getNotifications', () {
      test('should return list of notifications when successful', () async {
        final tNotifications = [
          createNotificationModel(id: 'notif-1'),
          createNotificationModel(id: 'notif-2'),
          createNotificationModel(id: 'notif-3'),
        ];
        when(() => mockDataSource.getNotifications())
            .thenAnswer((_) async => tNotifications);

        final result = await repository.getNotifications();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return notifications'),
          (notifications) => expect(notifications.length, 3),
        );
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.getNotifications())
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.getNotifications();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getUnreadCount', () {
      test('should return unread count when successful', () async {
        when(() => mockDataSource.getUnreadCount())
            .thenAnswer((_) async => 7);

        final result = await repository.getUnreadCount();

        expect(result, const Right(7));
        verify(() => mockDataSource.getUnreadCount()).called(1);
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.getUnreadCount())
            .thenThrow(const ServerException(message: 'Server error'));

        final result = await repository.getUnreadCount();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('markAsRead', () {
      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.markAsRead('notif-123'))
            .thenAnswer((_) async {});

        final result = await repository.markAsRead('notif-123');

        expect(result, const Right(null));
        verify(() => mockDataSource.markAsRead('notif-123')).called(1);
      });

      test('should return ServerFailure when notification not found', () async {
        when(() => mockDataSource.markAsRead('notif-123'))
            .thenThrow(const ServerException(message: 'Notification not found'));

        final result = await repository.markAsRead('notif-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('markAllAsRead', () {
      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.markAllAsRead())
            .thenAnswer((_) async {});

        final result = await repository.markAllAsRead();

        expect(result, const Right(null));
        verify(() => mockDataSource.markAllAsRead()).called(1);
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.markAllAsRead())
            .thenThrow(const ServerException(message: 'Mark all failed'));

        final result = await repository.markAllAsRead();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('deleteNotification', () {
      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.deleteNotification('notif-123'))
            .thenAnswer((_) async {});

        final result = await repository.deleteNotification('notif-123');

        expect(result, const Right(null));
        verify(() => mockDataSource.deleteNotification('notif-123')).called(1);
      });

      test('should return ServerFailure when notification not found', () async {
        when(() => mockDataSource.deleteNotification('notif-123'))
            .thenThrow(const ServerException(message: 'Notification not found'));

        final result = await repository.deleteNotification('notif-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('clearAllNotifications', () {
      test('should return Right(null) when successful', () async {
        when(() => mockDataSource.clearAllNotifications())
            .thenAnswer((_) async {});

        final result = await repository.clearAllNotifications();

        expect(result, const Right(null));
        verify(() => mockDataSource.clearAllNotifications()).called(1);
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        when(() => mockDataSource.clearAllNotifications())
            .thenThrow(const ServerException(message: 'Clear failed'));

        final result = await repository.clearAllNotifications();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
