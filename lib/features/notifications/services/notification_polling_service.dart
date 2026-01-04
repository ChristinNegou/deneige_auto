import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/notification.dart';
import '../domain/usecases/get_notifications_usecase.dart';
import '../domain/usecases/get_unread_count_usecase.dart';

/// Service de polling temps réel pour les notifications
/// Inspiré des patterns Uber, DoorDash pour les mises à jour en temps réel
class NotificationPollingService {
  static final NotificationPollingService _instance =
      NotificationPollingService._internal();
  factory NotificationPollingService() => _instance;
  NotificationPollingService._internal();

  Timer? _pollingTimer;
  Timer? _urgentPollingTimer;
  bool _isPolling = false;
  bool _isInActiveJob = false;

  // Intervalles de polling adaptatifs
  static const Duration _normalInterval = Duration(seconds: 30);
  static const Duration _activeJobInterval = Duration(seconds: 10);
  static const Duration _urgentInterval = Duration(seconds: 5);
  static const Duration _backgroundInterval = Duration(minutes: 2);

  // Use cases
  GetNotificationsUseCase? _getNotifications;
  GetUnreadCountUseCase? _getUnreadCount;

  // Stream controllers pour notifier les listeners
  final StreamController<List<AppNotification>> _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  final StreamController<AppNotification> _newNotificationController =
      StreamController<AppNotification>.broadcast();

  // Streams publics
  Stream<List<AppNotification>> get notificationsStream =>
      _notificationsController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  Stream<AppNotification> get newNotificationStream =>
      _newNotificationController.stream;

  // Dernier état connu
  List<AppNotification> _lastNotifications = [];
  int _lastUnreadCount = 0;

  /// Initialise le service avec les use cases
  void initialize({
    required GetNotificationsUseCase getNotifications,
    required GetUnreadCountUseCase getUnreadCount,
  }) {
    _getNotifications = getNotifications;
    _getUnreadCount = getUnreadCount;
  }

  /// Démarre le polling normal
  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;

    _startPollingWithInterval(_normalInterval);
    debugPrint('[NotificationPolling] Started with normal interval');
  }

  /// Arrête le polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _urgentPollingTimer?.cancel();
    _isPolling = false;
    _isInActiveJob = false;
    debugPrint('[NotificationPolling] Stopped');
  }

  /// Active le mode "travail en cours" avec polling plus fréquent
  void enterActiveJobMode() {
    if (_isInActiveJob) return;
    _isInActiveJob = true;

    _pollingTimer?.cancel();
    _startPollingWithInterval(_activeJobInterval);
    debugPrint('[NotificationPolling] Entered active job mode');
  }

  /// Désactive le mode "travail en cours"
  void exitActiveJobMode() {
    if (!_isInActiveJob) return;
    _isInActiveJob = false;

    _pollingTimer?.cancel();
    _startPollingWithInterval(_normalInterval);
    debugPrint('[NotificationPolling] Exited active job mode');
  }

  /// Active le mode urgent (polling très fréquent)
  void enterUrgentMode({Duration duration = const Duration(minutes: 5)}) {
    _urgentPollingTimer?.cancel();
    _pollingTimer?.cancel();

    _startPollingWithInterval(_urgentInterval);

    // Revenir au mode normal après la durée spécifiée
    _urgentPollingTimer = Timer(duration, () {
      if (_isInActiveJob) {
        _startPollingWithInterval(_activeJobInterval);
      } else {
        _startPollingWithInterval(_normalInterval);
      }
    });

    debugPrint(
        '[NotificationPolling] Entered urgent mode for ${duration.inMinutes} minutes');
  }

  /// Passe en mode background (polling moins fréquent)
  void enterBackgroundMode() {
    _pollingTimer?.cancel();
    _startPollingWithInterval(_backgroundInterval);
    debugPrint('[NotificationPolling] Entered background mode');
  }

  /// Revient au mode foreground
  void enterForegroundMode() {
    _pollingTimer?.cancel();
    if (_isInActiveJob) {
      _startPollingWithInterval(_activeJobInterval);
    } else {
      _startPollingWithInterval(_normalInterval);
    }

    // Fetch immédiat au retour en foreground
    _fetchNotifications();
    debugPrint('[NotificationPolling] Entered foreground mode');
  }

  void _startPollingWithInterval(Duration interval) {
    _pollingTimer?.cancel();

    // Fetch immédiat
    _fetchNotifications();

    // Puis polling régulier
    _pollingTimer = Timer.periodic(interval, (_) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    if (_getNotifications == null || _getUnreadCount == null) {
      debugPrint('[NotificationPolling] Use cases not initialized');
      return;
    }

    try {
      // Récupérer les notifications
      final result = await _getNotifications!();

      result.fold(
        (failure) {
          debugPrint('[NotificationPolling] Error: ${failure.message}');
        },
        (notifications) {
          // Trier par date
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Détecter les nouvelles notifications
          _detectNewNotifications(notifications);

          _lastNotifications = notifications;
          _notificationsController.add(notifications);
        },
      );

      // Récupérer le count
      final countResult = await _getUnreadCount!();
      countResult.fold(
        (failure) {},
        (count) {
          if (count != _lastUnreadCount) {
            _lastUnreadCount = count;
            _unreadCountController.add(count);
          }
        },
      );
    } catch (e) {
      debugPrint('[NotificationPolling] Exception: $e');
    }
  }

  void _detectNewNotifications(List<AppNotification> newNotifications) {
    if (_lastNotifications.isEmpty) return;

    final existingIds = _lastNotifications.map((n) => n.id).toSet();

    for (final notification in newNotifications) {
      if (!existingIds.contains(notification.id)) {
        // Nouvelle notification détectée!
        _newNotificationController.add(notification);
        debugPrint(
            '[NotificationPolling] New notification: ${notification.title}');

        // Si notification urgente, activer le mode urgent
        if (notification.isUrgent) {
          enterUrgentMode(duration: const Duration(minutes: 2));
        }
      }
    }
  }

  /// Force un refresh immédiat
  Future<void> forceRefresh() async {
    await _fetchNotifications();
  }

  /// Libère les ressources
  void dispose() {
    stopPolling();
    _notificationsController.close();
    _unreadCountController.close();
    _newNotificationController.close();
  }

  // Getters
  bool get isPolling => _isPolling;
  bool get isInActiveJobMode => _isInActiveJob;
  List<AppNotification> get lastNotifications =>
      List.unmodifiable(_lastNotifications);
  int get lastUnreadCount => _lastUnreadCount;
}

/// Helper class pour intégrer facilement le polling dans les widgets
class NotificationPollingHelper {
  StreamSubscription<List<AppNotification>>? _notificationsSub;
  StreamSubscription<int>? _unreadCountSub;
  StreamSubscription<AppNotification>? _newNotificationSub;

  void init({
    required Function(List<AppNotification>) onNotificationsUpdated,
    required Function(int) onUnreadCountUpdated,
    Function(AppNotification)? onNewNotification,
  }) {
    final service = NotificationPollingService();

    _notificationsSub =
        service.notificationsStream.listen(onNotificationsUpdated);
    _unreadCountSub = service.unreadCountStream.listen(onUnreadCountUpdated);

    if (onNewNotification != null) {
      _newNotificationSub =
          service.newNotificationStream.listen(onNewNotification);
    }
  }

  void dispose() {
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();
    _newNotificationSub?.cancel();
  }
}
