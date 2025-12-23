import 'package:dio/dio.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> clearAllNotifications();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await dio.get('/notifications');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> notificationsJson = response.data['notifications'];
        return notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get('/notifications/unread-count');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['count'] as int;
      } else {
        throw Exception('Failed to get unread count');
      }
    } catch (e) {
      throw Exception('Error fetching unread count: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await dio.patch('/notifications/$notificationId/read');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await dio.patch('/notifications/mark-all-read');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Failed to mark all as read');
      }
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await dio.delete('/notifications/$notificationId');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    try {
      final response = await dio.delete('/notifications/clear-all');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Failed to clear notifications');
      }
    } catch (e) {
      throw Exception('Error clearing notifications: $e');
    }
  }
}
