import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
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
        throw const ServerException(
            message: 'Erreur lors du chargement des notifications');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement des notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get('/notifications/unread-count');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['count'] as int;
      } else {
        throw const ServerException(
            message: 'Erreur lors du comptage des notifications non lues');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du comptage des notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await dio.patch('/notifications/$notificationId/read');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw const ServerException(
            message: 'Erreur lors du marquage de la notification');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du marquage de la notification: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await dio.patch('/notifications/mark-all-read');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw const ServerException(
            message: 'Erreur lors du marquage des notifications');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du marquage des notifications: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await dio.delete('/notifications/$notificationId');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw const ServerException(
            message: 'Erreur lors de la suppression de la notification');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de la suppression de la notification: $e');
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    try {
      final response = await dio.delete('/notifications/clear-all');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw const ServerException(
            message: 'Erreur lors de la suppression des notifications');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de la suppression des notifications: $e');
    }
  }

  AppException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String?;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Delai de connexion depasse. Verifiez votre connexion.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Impossible de se connecter au serveur.',
        );
      default:
        return ServerException(
          message: message ?? 'Une erreur serveur est survenue.',
          statusCode: statusCode,
        );
    }
  }
}
