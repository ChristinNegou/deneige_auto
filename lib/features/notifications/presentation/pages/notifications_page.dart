import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/notification.dart';
import '../../services/notification_navigation_service.dart';
import '../bloc/notification_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationsPageContent();
  }
}

final _navigationService = NotificationNavigationService();

class NotificationsPageContent extends StatelessWidget {
  const NotificationsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocConsumer<NotificationBloc, NotificationState>(
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  if (state.successMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.successMessage!),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state.isLoading && state.notifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  if (state.notifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<NotificationBloc>().add(RefreshNotifications());
                    },
                    color: AppTheme.primary,
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.paddingLG),
                      children: [
                        if (state.unreadCount > 0) ...[
                          _buildUnreadBadge(state.unreadCount),
                          const SizedBox(height: 16),
                        ],
                        if (state.todayNotifications.isNotEmpty) ...[
                          _buildSectionHeader('Aujourd\'hui'),
                          const SizedBox(height: 8),
                          ...state.todayNotifications.map(
                            (notification) => _buildNotificationCard(context, notification),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (state.earlierNotifications.isNotEmpty) ...[
                          _buildSectionHeader('Plus tôt'),
                          const SizedBox(height: 8),
                          ...state.earlierNotifications.map(
                            (notification) => _buildNotificationCard(context, notification),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.shadowSM,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Notifications',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount > 0) {
                return GestureDetector(
                  onTap: () {
                    context.read<NotificationBloc>().add(MarkAllNotificationsAsRead());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.done_all_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tout lire',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune notification',
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas de nouvelles notifications',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count notification${count > 1 ? 's' : ''} non lue${count > 1 ? 's' : ''}',
            style: AppTheme.labelLarge.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.headlineSmall.copyWith(fontSize: 14),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    final action = _navigationService.getActionForNotification(notification);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<NotificationBloc>().add(DeleteNotification(notification.id));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationBloc>().add(MarkNotificationAsRead(notification.id));
          }
          _navigationService.handleNotificationTap(context, notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? AppTheme.surface : AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: notification.isRead ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.3),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: AppTheme.shadowSM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: _getNotificationColor(notification.type),
                          size: 22,
                        ),
                      ),
                      if (notification.isUrgent)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTheme.labelLarge.copyWith(
                                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.timeAgo,
                              style: AppTheme.labelSmall,
                            ),
                            if (notification.isUrgent) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Urgent',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                ],
              ),
              // Action button
              if (action != null && !notification.isRead) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.divider),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<NotificationBloc>().add(MarkNotificationAsRead(notification.id));
                      _navigationService.handleNotificationTap(context, notification);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: action.isUrgent ? AppTheme.error : AppTheme.primary,
                      side: BorderSide(
                        color: action.isUrgent ? AppTheme.error : AppTheme.primary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                    ),
                    icon: Icon(action.icon, size: 18),
                    label: Text(
                      action.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reservationAssigned:
        return Icons.person_add_rounded;
      case NotificationType.workerEnRoute:
        return Icons.directions_car_rounded;
      case NotificationType.workStarted:
        return Icons.construction_rounded;
      case NotificationType.workCompleted:
        return Icons.check_circle_rounded;
      case NotificationType.reservationCancelled:
        return Icons.cancel_rounded;
      case NotificationType.paymentSuccess:
        return Icons.payment_rounded;
      case NotificationType.paymentFailed:
        return Icons.error_rounded;
      case NotificationType.refundProcessed:
        return Icons.money_off_rounded;
      case NotificationType.weatherAlert:
        return Icons.wb_cloudy_rounded;
      case NotificationType.urgentRequest:
        return Icons.priority_high_rounded;
      case NotificationType.workerMessage:
        return Icons.message_rounded;
      case NotificationType.systemNotification:
        return Icons.info_rounded;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.reservationAssigned:
      case NotificationType.workCompleted:
      case NotificationType.paymentSuccess:
        return AppTheme.success;
      case NotificationType.workerEnRoute:
      case NotificationType.workStarted:
        return AppTheme.primary;
      case NotificationType.reservationCancelled:
      case NotificationType.paymentFailed:
      case NotificationType.urgentRequest:
        return AppTheme.error;
      case NotificationType.refundProcessed:
        return AppTheme.warning;
      case NotificationType.weatherAlert:
        return AppTheme.info;
      case NotificationType.workerMessage:
        return AppTheme.secondary;
      case NotificationType.systemNotification:
        return AppTheme.textSecondary;
    }
  }
}
