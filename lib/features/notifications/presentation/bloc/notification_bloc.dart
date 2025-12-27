import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/mark_all_as_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/clear_all_notifications_usecase.dart';

// Events
abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {}

class RefreshNotifications extends NotificationEvent {}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;
  final bool autoDeleteAfterRead;

  MarkNotificationAsRead(this.notificationId, {this.autoDeleteAfterRead = false});

  @override
  List<Object?> get props => [notificationId, autoDeleteAfterRead];
}

class MarkAllNotificationsAsRead extends NotificationEvent {}

class DeleteNotification extends NotificationEvent {
  final String notificationId;

  DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class ClearAllNotifications extends NotificationEvent {}

class ClearReadNotifications extends NotificationEvent {}

class UpdateAutoDeleteSetting extends NotificationEvent {
  final bool enabled;
  final int delaySeconds;

  UpdateAutoDeleteSetting({required this.enabled, this.delaySeconds = 3});

  @override
  List<Object?> get props => [enabled, delaySeconds];
}

// States
class NotificationState extends Equatable {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool autoDeleteEnabled;
  final int autoDeleteDelaySeconds;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.autoDeleteEnabled = false,
    this.autoDeleteDelaySeconds = 3,
  });

  List<AppNotification> get unreadNotifications {
    return notifications.where((n) => !n.isRead).toList();
  }

  List<AppNotification> get readNotifications {
    return notifications.where((n) => n.isRead).toList();
  }

  List<AppNotification> get todayNotifications {
    return notifications.where((n) => n.isToday).toList();
  }

  List<AppNotification> get earlierNotifications {
    return notifications.where((n) => !n.isToday).toList();
  }

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
    bool? autoDeleteEnabled,
    int? autoDeleteDelaySeconds,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      autoDeleteEnabled: autoDeleteEnabled ?? this.autoDeleteEnabled,
      autoDeleteDelaySeconds: autoDeleteDelaySeconds ?? this.autoDeleteDelaySeconds,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        unreadCount,
        isLoading,
        errorMessage,
        successMessage,
        autoDeleteEnabled,
        autoDeleteDelaySeconds,
      ];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotifications;
  final GetUnreadCountUseCase getUnreadCount;
  final MarkAsReadUseCase markAsRead;
  final MarkAllAsReadUseCase markAllAsRead;
  final DeleteNotificationUseCase deleteNotification;
  final ClearAllNotificationsUseCase clearAllNotifications;

  // Timers pour la suppression automatique différée
  final Map<String, Timer> _autoDeleteTimers = {};

  NotificationBloc({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.markAsRead,
    required this.markAllAsRead,
    required this.deleteNotification,
    required this.clearAllNotifications,
  }) : super(const NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
    on<ClearReadNotifications>(_onClearReadNotifications);
    on<UpdateAutoDeleteSetting>(_onUpdateAutoDeleteSetting);
  }

  @override
  Future<void> close() {
    // Annuler tous les timers en cours
    for (final timer in _autoDeleteTimers.values) {
      timer.cancel();
    }
    _autoDeleteTimers.clear();
    return super.close();
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await getNotifications();

    if (result.isLeft()) {
      final failure = result.fold((l) => l, (r) => null);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: failure?.message ?? 'Erreur lors du chargement',
      ));
      return;
    }

    final notifications = result.fold((l) => <AppNotification>[], (r) => r);

    // Trier par date de création (plus récent en premier)
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Get unread count
    final countResult = await getUnreadCount();
    final count = countResult.fold((l) => 0, (r) => r);

    emit(state.copyWith(
      isLoading: false,
      notifications: notifications,
      unreadCount: count,
      clearMessages: true,
    ));
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await getNotifications();

    if (result.isLeft()) {
      final failure = result.fold((l) => l, (r) => null);
      emit(state.copyWith(errorMessage: failure?.message ?? 'Erreur lors du rafraîchissement'));
      return;
    }

    final notifications = result.fold((l) => <AppNotification>[], (r) => r);

    // Trier par date de création (plus récent en premier)
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final countResult = await getUnreadCount();
    final count = countResult.fold((l) => 0, (r) => r);

    emit(state.copyWith(
      notifications: notifications,
      unreadCount: count,
      clearMessages: true,
    ));
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await markAsRead(event.notificationId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message ?? 'Erreur lors de la mise à jour')),
      (_) {
        // Update local state
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification.markAsRead();
          }
          return notification;
        }).toList();

        final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

        emit(state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        ));

        // Planifier la suppression automatique si activée
        if (state.autoDeleteEnabled || event.autoDeleteAfterRead) {
          _scheduleAutoDelete(event.notificationId);
        }
      },
    );
  }

  void _scheduleAutoDelete(String notificationId) {
    // Annuler le timer existant si présent
    _autoDeleteTimers[notificationId]?.cancel();

    // Créer un nouveau timer
    _autoDeleteTimers[notificationId] = Timer(
      Duration(seconds: state.autoDeleteDelaySeconds),
      () {
        add(DeleteNotification(notificationId));
        _autoDeleteTimers.remove(notificationId);
      },
    );
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await markAllAsRead();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message ?? 'Erreur lors de la mise à jour')),
      (_) {
        // Mark all notifications as read locally
        final updatedNotifications = state.notifications
            .map((notification) => notification.markAsRead())
            .toList();

        emit(state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
          successMessage: 'Toutes les notifications marquées comme lues',
        ));

        // Planifier la suppression automatique de toutes les notifications si activée
        if (state.autoDeleteEnabled) {
          for (final notification in updatedNotifications) {
            _scheduleAutoDelete(notification.id);
          }
        }
      },
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    // Annuler le timer si existant
    _autoDeleteTimers[event.notificationId]?.cancel();
    _autoDeleteTimers.remove(event.notificationId);

    final result = await deleteNotification(event.notificationId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message ?? 'Erreur lors de la suppression')),
      (_) {
        // Retirer la notification localement
        final updatedNotifications = state.notifications
            .where((n) => n.id != event.notificationId)
            .toList();

        final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

        emit(state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        ));
      },
    );
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    // Annuler tous les timers
    for (final timer in _autoDeleteTimers.values) {
      timer.cancel();
    }
    _autoDeleteTimers.clear();

    final result = await clearAllNotifications();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message ?? 'Erreur lors de la suppression')),
      (_) {
        emit(state.copyWith(
          notifications: [],
          unreadCount: 0,
          successMessage: 'Toutes les notifications supprimées',
        ));
      },
    );
  }

  Future<void> _onClearReadNotifications(
    ClearReadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    // Supprimer uniquement les notifications lues
    final readNotifications = state.notifications.where((n) => n.isRead).toList();

    if (readNotifications.isEmpty) {
      emit(state.copyWith(successMessage: 'Aucune notification lue à supprimer'));
      return;
    }

    // Supprimer chaque notification lue
    bool hasError = false;
    for (final notification in readNotifications) {
      // Annuler le timer si existant
      _autoDeleteTimers[notification.id]?.cancel();
      _autoDeleteTimers.remove(notification.id);

      final result = await deleteNotification(notification.id);
      if (result.isLeft()) {
        hasError = true;
      }
    }

    if (hasError) {
      // Rafraîchir pour synchroniser l'état
      add(RefreshNotifications());
      emit(state.copyWith(errorMessage: 'Certaines notifications n\'ont pas pu être supprimées'));
    } else {
      // Garder uniquement les notifications non lues
      final unreadNotifications = state.notifications.where((n) => !n.isRead).toList();

      emit(state.copyWith(
        notifications: unreadNotifications,
        successMessage: '${readNotifications.length} notification${readNotifications.length > 1 ? 's' : ''} supprimée${readNotifications.length > 1 ? 's' : ''}',
      ));
    }
  }

  void _onUpdateAutoDeleteSetting(
    UpdateAutoDeleteSetting event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(
      autoDeleteEnabled: event.enabled,
      autoDeleteDelaySeconds: event.delaySeconds,
      successMessage: event.enabled
          ? 'Suppression automatique activée (${event.delaySeconds}s)'
          : 'Suppression automatique désactivée',
    ));
  }
}
