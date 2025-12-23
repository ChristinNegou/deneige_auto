import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/mark_all_as_read_usecase.dart';

// Events
abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {}

class RefreshNotifications extends NotificationEvent {}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {}

// States
class NotificationState extends Equatable {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
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
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        unreadCount,
        isLoading,
        errorMessage,
        successMessage,
      ];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotifications;
  final GetUnreadCountUseCase getUnreadCount;
  final MarkAsReadUseCase markAsRead;
  final MarkAllAsReadUseCase markAllAsRead;

  NotificationBloc({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.markAsRead,
    required this.markAllAsRead,
  }) : super(const NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
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
      },
    );
  }
}
