import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
                        content:
                            Text(_translateMessage(state.errorMessage!, l10n)),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  if (state.successMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            _translateMessage(state.successMessage!, l10n)),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state.isLoading && state.notifications.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  if (state.notifications.isEmpty) {
                    return _buildEmptyState(l10n);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<NotificationBloc>()
                          .add(RefreshNotifications());
                    },
                    color: AppTheme.primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        if (state.todayNotifications.isNotEmpty) ...[
                          _buildSectionHeader(l10n.common_today),
                          _buildGroup(context, state.todayNotifications),
                          const SizedBox(height: 24),
                        ],
                        if (state.earlierNotifications.isNotEmpty) ...[
                          _buildSectionHeader(l10n.common_earlier),
                          _buildGroup(context, state.earlierNotifications),
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Text(l10n.notifications_title, style: AppTheme.headlineMedium),
          const Spacer(),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  context
                      .read<NotificationBloc>()
                      .add(MarkAllNotificationsAsRead());
                },
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(l10n.notifications_readAll),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return EmptyStateWidget(
      illustrationType: IllustrationType.emptyNotifications,
      title: l10n.notifications_empty,
      subtitle: l10n.notifications_emptySubtitle,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: AppTheme.labelMedium),
    );
  }

  /// Un bloc blanc par groupe, les notifications separees par un filet.
  Widget _buildGroup(
      BuildContext context, List<AppNotification> notifications) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Column(
          children: [
            for (var i = 0; i < notifications.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 66),
              _buildNotificationCard(context, notifications[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, AppNotification notification) {
    final l10n = AppLocalizations.of(context)!;
    final action =
        _navigationService.getActionForNotification(notification, l10n);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context
            .read<NotificationBloc>()
            .add(DeleteNotification(notification.id));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.error,
        child: Icon(Icons.delete_outline_rounded, color: AppTheme.onPrimary),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context
                .read<NotificationBloc>()
                .add(MarkNotificationAsRead(notification.id));
          }
          _navigationService.handleNotificationTap(context, notification);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTheme.labelLarge.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notification.localizedTimeAgo(l10n),
                          style: AppTheme.labelSmall,
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: AppTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.isUrgent) ...[
                      const SizedBox(height: 8),
                      StatusBadge(
                        label: l10n.notif_urgent,
                        color: AppTheme.error,
                        small: true,
                      ),
                    ],
                    if (action != null && !notification.isRead) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () {
                          context
                              .read<NotificationBloc>()
                              .add(MarkNotificationAsRead(notification.id));
                          _navigationService.handleNotificationTap(
                              context, notification);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: action.isUrgent
                              ? AppTheme.error
                              : AppTheme.primary2,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(action.icon, size: 16),
                        label: Text(action.label),
                      ),
                    ],
                  ],
                ),
              ),
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
      case NotificationType.searchingWorker:
        return Icons.person_search_rounded;
      case NotificationType.workerMessage:
        return Icons.message_rounded;
      case NotificationType.newMessage:
        return Icons.chat_bubble_rounded;
      case NotificationType.tipReceived:
        return Icons.attach_money_rounded;
      case NotificationType.rating:
        return Icons.star_rounded;
      case NotificationType.systemNotification:
        return Icons.info_rounded;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.workCompleted:
      case NotificationType.paymentSuccess:
      case NotificationType.tipReceived:
        return AppTheme.success;
      case NotificationType.reservationCancelled:
      case NotificationType.paymentFailed:
      case NotificationType.urgentRequest:
        return AppTheme.error;
      case NotificationType.weatherAlert:
        return AppTheme.info;
      case NotificationType.rating:
        return AppTheme.warning;
      case NotificationType.workerEnRoute:
      case NotificationType.workStarted:
        return AppTheme.statusInProgress;
      default:
        return AppTheme.primary;
    }
  }

  String _translateMessage(String key, AppLocalizations l10n) {
    // Handle parameterized keys (format: 'key:value')
    if (key.startsWith('notif_deletedCount:')) {
      final count = int.tryParse(key.split(':')[1]) ?? 0;
      return l10n.notif_deletedCount(count);
    }
    if (key.startsWith('notif_autoDeleteEnabled:')) {
      final seconds = int.tryParse(key.split(':')[1]) ?? 3;
      return l10n.notif_autoDeleteEnabled(seconds);
    }

    // Simple keys
    switch (key) {
      case 'notif_allMarkedRead':
        return l10n.notif_allMarkedRead;
      case 'notif_allDeleted':
        return l10n.notif_allDeleted;
      case 'notif_noReadToDelete':
        return l10n.notif_noReadToDelete;
      case 'notif_someNotDeleted':
        return l10n.notif_someNotDeleted;
      case 'notif_autoDeleteDisabled':
        return l10n.notif_autoDeleteDisabled;
      case 'notif_errorLoading':
        return l10n.notif_errorLoading;
      case 'notif_errorRefreshing':
        return l10n.notif_errorRefreshing;
      case 'notif_errorLoadingNotifications':
        return l10n.notif_errorLoadingNotifications;
      case 'notif_errorCountingUnread':
        return l10n.notif_errorCountingUnread;
      case 'notif_errorMarkingRead':
        return l10n.notif_errorMarkingRead;
      case 'notif_errorMarkingAllRead':
        return l10n.notif_errorMarkingAllRead;
      case 'notif_errorDeleting':
        return l10n.notif_errorDeleting;
      case 'notif_errorDeletingAll':
        return l10n.notif_errorDeletingAll;
      case 'notif_connectionTimeout':
        return l10n.notif_connectionTimeout;
      case 'notif_cannotConnect':
        return l10n.notif_cannotConnect;
      case 'notif_serverError':
        return l10n.notif_serverError;
      default:
        return key;
    }
  }
}
