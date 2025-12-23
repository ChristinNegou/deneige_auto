import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification.dart';

abstract class NotificationRepository {
  /// Get all notifications for current user
  Future<Either<Failure, List<AppNotification>>> getNotifications();

  /// Get unread notifications count
  Future<Either<Failure, int>> getUnreadCount();

  /// Mark notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead();

  /// Delete notification
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Clear all notifications
  Future<Either<Failure, void>> clearAllNotifications();
}
