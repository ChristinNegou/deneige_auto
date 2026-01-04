import 'package:deneige_auto/features/notifications/domain/entities/notification.dart';

/// Fixtures pour les tests de notification
class NotificationFixtures {
  static final DateTime _now = DateTime(2024, 1, 15, 10, 0);

  /// Cree une notification de reservation assignee
  static AppNotification createReservationAssigned({
    String? id,
    bool isRead = false,
  }) {
    return AppNotification(
      id: id ?? 'notif-assigned-123',
      userId: 'user-123',
      type: NotificationType.reservationAssigned,
      title: 'Deneigeur assigne',
      message: 'Pierre Martin a accepte votre demande de deneigement',
      priority: NotificationPriority.high,
      isRead: isRead,
      createdAt: _now,
      reservationId: 'reservation-123',
      workerId: 'worker-123',
    );
  }

  /// Cree une notification de travail complete
  static AppNotification createWorkCompleted({
    String? id,
    bool isRead = false,
  }) {
    return AppNotification(
      id: id ?? 'notif-completed-123',
      userId: 'user-123',
      type: NotificationType.workCompleted,
      title: 'Travail termine',
      message: 'Votre vehicule a ete deneige avec succes',
      priority: NotificationPriority.normal,
      isRead: isRead,
      createdAt: _now,
      reservationId: 'reservation-123',
    );
  }

  /// Cree une notification de paiement reussi
  static AppNotification createPaymentSuccess({
    String? id,
    bool isRead = false,
  }) {
    return AppNotification(
      id: id ?? 'notif-payment-123',
      userId: 'user-123',
      type: NotificationType.paymentSuccess,
      title: 'Paiement reussi',
      message: 'Votre paiement de 25.00\$ a ete confirme',
      priority: NotificationPriority.normal,
      isRead: isRead,
      createdAt: _now,
      reservationId: 'reservation-123',
    );
  }

  /// Cree une notification d'alerte meteo
  static AppNotification createWeatherAlert({
    String? id,
    bool isRead = false,
  }) {
    return AppNotification(
      id: id ?? 'notif-weather-123',
      userId: 'user-123',
      type: NotificationType.weatherAlert,
      title: 'Alerte neige',
      message: '15cm de neige prevus demain. Planifiez votre deneigement!',
      priority: NotificationPriority.high,
      isRead: isRead,
      createdAt: _now,
    );
  }

  /// Cree une notification systeme
  static AppNotification createSystemNotification({
    String? id,
    bool isRead = false,
  }) {
    return AppNotification(
      id: id ?? 'notif-system-123',
      userId: 'user-123',
      type: NotificationType.systemNotification,
      title: 'Mise a jour',
      message: 'Une nouvelle version de l\'application est disponible',
      priority: NotificationPriority.low,
      isRead: isRead,
      createdAt: _now,
    );
  }

  /// Cree une notification non lue
  static AppNotification createUnread({String? id}) {
    return createReservationAssigned(id: id, isRead: false);
  }

  /// Cree une notification lue
  static AppNotification createRead({String? id}) {
    return createReservationAssigned(id: id, isRead: true);
  }

  /// Cree une liste de notifications
  static List<AppNotification> createList(int count, {bool? isRead}) {
    return List.generate(
      count,
      (index) => AppNotification(
        id: 'notif-$index',
        userId: 'user-123',
        type: NotificationType.workCompleted,
        title: 'Notification $index',
        message: 'Message de la notification $index',
        priority: NotificationPriority.normal,
        isRead: isRead ?? index.isEven,
        createdAt: _now.subtract(Duration(hours: index)),
      ),
    );
  }

  /// Cree une liste mixte de notifications (read, unread, different types)
  static List<AppNotification> createMixedList() {
    return [
      createReservationAssigned(id: 'notif-1', isRead: false),
      createWorkCompleted(id: 'notif-2', isRead: true),
      createPaymentSuccess(id: 'notif-3', isRead: false),
      createWeatherAlert(id: 'notif-4', isRead: false),
      createSystemNotification(id: 'notif-5', isRead: true),
    ];
  }
}
