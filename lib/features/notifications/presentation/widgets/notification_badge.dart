import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../../services/notification_polling_service.dart';

/// Badge de notification - Affiche le nombre de notifications non lues
/// À utiliser sur les icônes de navigation (bottom nav, app bar, etc.)
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final double size;
  final bool showZero;
  final bool animate;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.size = 18,
    this.showZero = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: _Badge(
            count: count,
            color: badgeColor ?? Colors.red,
            textColor: textColor ?? Colors.white,
            size: size,
            animate: animate,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatefulWidget {
  final int count;
  final Color color;
  final Color textColor;
  final double size;
  final bool animate;

  const _Badge({
    required this.count,
    required this.color,
    required this.textColor,
    required this.size,
    required this.animate,
  });

  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(_Badge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count && widget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.count > 99 ? '99+' : '${widget.count}';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        constraints: BoxConstraints(
          minWidth: widget.size,
          minHeight: widget.size,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: displayText.length > 2 ? 4 : 2,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.size / 2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              color: widget.textColor,
              fontSize: widget.size * 0.6,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge qui se met à jour automatiquement via le BLoC
class AutoNotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double size;
  final bool showZero;

  const AutoNotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.size = 18,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return NotificationBadge(
          count: state.unreadCount,
          badgeColor: badgeColor,
          textColor: textColor,
          size: size,
          showZero: showZero,
          child: child,
        );
      },
    );
  }
}

/// Badge qui se met à jour via le service de polling (sans BLoC)
class PollingNotificationBadge extends StatefulWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double size;
  final bool showZero;

  const PollingNotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.size = 18,
    this.showZero = false,
  });

  @override
  State<PollingNotificationBadge> createState() => _PollingNotificationBadgeState();
}

class _PollingNotificationBadgeState extends State<PollingNotificationBadge> {
  late StreamSubscription<int> _subscription;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    final service = NotificationPollingService();
    _count = service.lastUnreadCount;
    _subscription = service.unreadCountStream.listen((count) {
      setState(() => _count = count);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      count: _count,
      badgeColor: widget.badgeColor,
      textColor: widget.textColor,
      size: widget.size,
      showZero: widget.showZero,
      child: widget.child,
    );
  }
}

/// Widget icône de notification avec badge intégré
class NotificationIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? badgeColor;
  final double iconSize;

  const NotificationIconButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.badgeColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: AutoNotificationBadge(
        badgeColor: badgeColor,
        child: Icon(
          Icons.notifications_outlined,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Indicateur de notification en forme de point (dot indicator)
class NotificationDot extends StatelessWidget {
  final bool show;
  final Color? color;
  final double size;
  final bool animate;

  const NotificationDot({
    super.key,
    required this.show,
    this.color,
    this.size = 8,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return _PulsingDot(
      color: color ?? Colors.red,
      size: size,
      animate: animate,
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool animate;

  const _PulsingDot({
    required this.color,
    required this.size,
    required this.animate,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * (widget.animate ? _animation.value : 1),
          height: widget.size * (widget.animate ? _animation.value : 1),
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: widget.animate
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: widget.size,
                      spreadRadius: widget.size * 0.2 * (_animation.value - 1),
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

/// Badge automatique qui s'affiche quand il y a des notifications non lues
class AutoNotificationDot extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double size;
  final Alignment alignment;

  const AutoNotificationDot({
    super.key,
    required this.child,
    this.color,
    this.size = 8,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (state.unreadCount > 0)
              Positioned(
                right: alignment == Alignment.topRight ? -2 : null,
                left: alignment == Alignment.topLeft ? -2 : null,
                top: -2,
                child: NotificationDot(
                  show: true,
                  color: color,
                  size: size,
                ),
              ),
          ],
        );
      },
    );
  }
}
