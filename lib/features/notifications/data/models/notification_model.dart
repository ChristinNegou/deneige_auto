import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    super.priority,
    super.isRead,
    required super.createdAt,
    super.reservationId,
    super.workerId,
    super.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      type: _parseNotificationType(json['type']),
      title: json['title'],
      message: json['message'],
      priority: _parseNotificationPriority(json['priority'] ?? 'normal'),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      reservationId: json['reservationId'] is Map
          ? json['reservationId']['_id']
          : json['reservationId'],
      workerId: json['workerId'] is Map
          ? json['workerId']['_id']
          : json['workerId'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': _notificationTypeToString(type),
      'title': title,
      'message': message,
      'priority': _notificationPriorityToString(priority),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'reservationId': reservationId,
      'workerId': workerId,
      'metadata': metadata,
    };
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'reservationAssigned':
        return NotificationType.reservationAssigned;
      case 'workerEnRoute':
        return NotificationType.workerEnRoute;
      case 'workStarted':
        return NotificationType.workStarted;
      case 'workCompleted':
        return NotificationType.workCompleted;
      case 'reservationCancelled':
        return NotificationType.reservationCancelled;
      case 'paymentSuccess':
        return NotificationType.paymentSuccess;
      case 'paymentFailed':
        return NotificationType.paymentFailed;
      case 'refundProcessed':
        return NotificationType.refundProcessed;
      case 'weatherAlert':
        return NotificationType.weatherAlert;
      case 'urgentRequest':
        return NotificationType.urgentRequest;
      case 'workerMessage':
        return NotificationType.workerMessage;
      case 'newMessage':
        return NotificationType.newMessage;
      case 'tipReceived':
        return NotificationType.tipReceived;
      case 'rating':
        return NotificationType.rating;
      case 'systemNotification':
        return NotificationType.systemNotification;
      default:
        return NotificationType.systemNotification;
    }
  }

  static NotificationPriority _parseNotificationPriority(String priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.reservationAssigned:
        return 'reservationAssigned';
      case NotificationType.workerEnRoute:
        return 'workerEnRoute';
      case NotificationType.workStarted:
        return 'workStarted';
      case NotificationType.workCompleted:
        return 'workCompleted';
      case NotificationType.reservationCancelled:
        return 'reservationCancelled';
      case NotificationType.paymentSuccess:
        return 'paymentSuccess';
      case NotificationType.paymentFailed:
        return 'paymentFailed';
      case NotificationType.refundProcessed:
        return 'refundProcessed';
      case NotificationType.weatherAlert:
        return 'weatherAlert';
      case NotificationType.urgentRequest:
        return 'urgentRequest';
      case NotificationType.workerMessage:
        return 'workerMessage';
      case NotificationType.newMessage:
        return 'newMessage';
      case NotificationType.tipReceived:
        return 'tipReceived';
      case NotificationType.rating:
        return 'rating';
      case NotificationType.systemNotification:
        return 'systemNotification';
    }
  }

  static String _notificationPriorityToString(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }
}
