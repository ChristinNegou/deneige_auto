import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/notification.dart';
import '../../services/notification_navigation_service.dart';

/// Bannière de notification in-app - Style Uber/DoorDash
/// S'affiche en haut de l'écran quand une nouvelle notification arrive
class NotificationBanner extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final Duration autoDismissDelay;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
    this.autoDismissDelay = const Duration(seconds: 5),
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
    _startAutoDismissTimer();
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer?.cancel();
    if (!widget.notification.isUrgent) {
      _autoDismissTimer = Timer(widget.autoDismissDelay, _dismiss);
    }
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NotificationNavigationService();
    final action = navigationService.getActionForNotification(widget.notification);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  widget.onTap?.call();
                  _dismiss();
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity!.abs() > 200) {
                    _dismiss();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: widget.notification.isUrgent
                        ? Border.all(color: Colors.red, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // App icon / notification type icon
                            _buildIcon(),
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
                                          widget.notification.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'maintenant',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.notification.message,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Dismiss button
                            GestureDetector(
                              onTap: _dismiss,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action button (if available)
                      if (action != null) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                action.icon,
                                size: 18,
                                color: action.isUrgent
                                    ? Colors.red
                                    : const Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                action.label,
                                style: TextStyle(
                                  color: action.isUrgent
                                      ? Colors.red
                                      : const Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: action.isUrgent
                                    ? Colors.red
                                    : const Color(0xFF8B5CF6),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Progress bar for auto-dismiss
                      if (!widget.notification.isUrgent)
                        _AutoDismissProgress(
                          duration: widget.autoDismissDelay,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final color = _getNotificationColor(widget.notification.type);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getNotificationIcon(widget.notification.type),
            color: color,
            size: 24,
          ),
        ),
        if (widget.notification.isUrgent)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reservationAssigned:
        return Icons.person_add;
      case NotificationType.workerEnRoute:
        return Icons.directions_car;
      case NotificationType.workStarted:
        return Icons.construction;
      case NotificationType.workCompleted:
        return Icons.check_circle;
      case NotificationType.reservationCancelled:
        return Icons.cancel;
      case NotificationType.paymentSuccess:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.refundProcessed:
        return Icons.money_off;
      case NotificationType.weatherAlert:
        return Icons.wb_cloudy;
      case NotificationType.urgentRequest:
        return Icons.priority_high;
      case NotificationType.workerMessage:
        return Icons.message;
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.tipReceived:
        return Icons.attach_money;
      case NotificationType.rating:
        return Icons.star;
      case NotificationType.systemNotification:
        return Icons.info;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.reservationAssigned:
      case NotificationType.workCompleted:
      case NotificationType.paymentSuccess:
        return Colors.green;
      case NotificationType.workerEnRoute:
      case NotificationType.workStarted:
        return Colors.blue;
      case NotificationType.reservationCancelled:
      case NotificationType.paymentFailed:
      case NotificationType.urgentRequest:
        return Colors.red;
      case NotificationType.refundProcessed:
        return Colors.orange;
      case NotificationType.weatherAlert:
        return Colors.lightBlue;
      case NotificationType.workerMessage:
      case NotificationType.newMessage:
        return const Color(0xFF8B5CF6);
      case NotificationType.tipReceived:
        return Colors.green;
      case NotificationType.rating:
        return Colors.amber;
      case NotificationType.systemNotification:
        return Colors.grey;
    }
  }
}

/// Progress bar for auto-dismiss countdown
class _AutoDismissProgress extends StatefulWidget {
  final Duration duration;

  const _AutoDismissProgress({required this.duration});

  @override
  State<_AutoDismissProgress> createState() => _AutoDismissProgressState();
}

class _AutoDismissProgressState extends State<_AutoDismissProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 3,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: LinearProgressIndicator(
            value: 1 - _controller.value,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        );
      },
    );
  }
}

/// Manager pour afficher les bannières de notification
class NotificationBannerManager {
  static final NotificationBannerManager _instance =
      NotificationBannerManager._internal();
  factory NotificationBannerManager() => _instance;
  NotificationBannerManager._internal();

  OverlayEntry? _currentEntry;
  final List<AppNotification> _queue = [];
  bool _isShowing = false;

  /// Affiche une notification en bannière
  void show(BuildContext context, AppNotification notification) {
    _queue.add(notification);
    _processQueue(context);
  }

  void _processQueue(BuildContext context) {
    if (_isShowing || _queue.isEmpty) return;
    _isShowing = true;

    final notification = _queue.removeAt(0);
    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: NotificationBanner(
          notification: notification,
          onDismiss: () {
            _currentEntry?.remove();
            _currentEntry = null;
            _isShowing = false;
            _processQueue(context);
          },
          onTap: () {
            NotificationNavigationService().handleNotificationTap(
              context,
              notification,
            );
          },
        ),
      ),
    );

    overlay.insert(_currentEntry!);
  }

  /// Ferme la bannière actuelle
  void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _isShowing = false;
  }

  /// Vide la queue et ferme
  void clear() {
    _queue.clear();
    dismiss();
  }
}
