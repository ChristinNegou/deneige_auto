import 'package:equatable/equatable.dart';

enum NotificationType {
  reservationAssigned, // Déneigeur a accepté la tâche
  workerEnRoute, // Déneigeur est en route
  workStarted, // Travail a commencé
  workCompleted, // Travail terminé
  reservationCancelled, // Réservation annulée
  paymentSuccess, // Paiement réussi
  paymentFailed, // Paiement échoué
  refundProcessed, // Remboursement effectué
  weatherAlert, // Alerte météo (neige prévue)
  urgentRequest, // Demande urgente
  workerMessage, // Message du déneigeur
  newMessage, // Nouveau message de chat
  tipReceived, // Pourboire reçu par le déneigeur
  rating, // Évaluation reçue par le déneigeur
  systemNotification, // Notification système
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final String? reservationId;
  final String? workerId;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    required this.createdAt,
    this.reservationId,
    this.workerId,
    this.metadata,
  });

  // Business logic
  bool get isUrgent => priority == NotificationPriority.urgent;

  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return 'Il y a ${difference.inDays ~/ 7} sem';
    }
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    String? reservationId,
    String? workerId,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      reservationId: reservationId ?? this.reservationId,
      workerId: workerId ?? this.workerId,
      metadata: metadata ?? this.metadata,
    );
  }

  AppNotification markAsRead() {
    return copyWith(isRead: true);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        message,
        priority,
        isRead,
        createdAt,
        reservationId,
        workerId,
        metadata,
      ];
}

extension NotificationTypeExtension on NotificationType {
  String get iconName {
    switch (this) {
      case NotificationType.reservationAssigned:
        return 'person_add';
      case NotificationType.workerEnRoute:
        return 'directions_car';
      case NotificationType.workStarted:
        return 'construction';
      case NotificationType.workCompleted:
        return 'check_circle';
      case NotificationType.reservationCancelled:
        return 'cancel';
      case NotificationType.paymentSuccess:
        return 'payment';
      case NotificationType.paymentFailed:
        return 'error';
      case NotificationType.refundProcessed:
        return 'money_off';
      case NotificationType.weatherAlert:
        return 'wb_cloudy';
      case NotificationType.urgentRequest:
        return 'priority_high';
      case NotificationType.workerMessage:
        return 'message';
      case NotificationType.newMessage:
        return 'chat_bubble';
      case NotificationType.tipReceived:
        return 'attach_money';
      case NotificationType.rating:
        return 'star';
      case NotificationType.systemNotification:
        return 'info';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.reservationAssigned:
        return 'Tâche acceptée';
      case NotificationType.workerEnRoute:
        return 'Déneigeur en route';
      case NotificationType.workStarted:
        return 'Travail commencé';
      case NotificationType.workCompleted:
        return 'Travail terminé';
      case NotificationType.reservationCancelled:
        return 'Réservation annulée';
      case NotificationType.paymentSuccess:
        return 'Paiement réussi';
      case NotificationType.paymentFailed:
        return 'Paiement échoué';
      case NotificationType.refundProcessed:
        return 'Remboursement';
      case NotificationType.weatherAlert:
        return 'Alerte météo';
      case NotificationType.urgentRequest:
        return 'Urgent';
      case NotificationType.workerMessage:
        return 'Message';
      case NotificationType.newMessage:
        return 'Nouveau message';
      case NotificationType.tipReceived:
        return 'Pourboire reçu';
      case NotificationType.rating:
        return 'Évaluation';
      case NotificationType.systemNotification:
        return 'Système';
    }
  }
}
