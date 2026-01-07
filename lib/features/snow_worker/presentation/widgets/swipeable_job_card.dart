import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/worker_job.dart';

class SwipeableJobCard extends StatefulWidget {
  final WorkerJob job;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool showAcceptButton;
  final bool isLoading;
  final bool enableSwipe;

  const SwipeableJobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onAccept,
    this.onDecline,
    this.showAcceptButton = true,
    this.isLoading = false,
    this.enableSwipe = true,
  });

  @override
  State<SwipeableJobCard> createState() => _SwipeableJobCardState();
}

class _SwipeableJobCardState extends State<SwipeableJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _calculateTimeRemaining();
    _startCountdown();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    if (widget.job.departureTime.isAfter(now)) {
      _timeRemaining = widget.job.departureTime.difference(now);
    } else {
      _timeRemaining = Duration.zero;
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _calculateTimeRemaining();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.enableSwipe && widget.job.status == JobStatus.pending) {
      return Dismissible(
        key: Key(widget.job.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right = Accept
            HapticFeedback.mediumImpact();
            widget.onAccept?.call();
            return false; // Don't dismiss, let the bloc handle it
          } else {
            // Swipe left = Decline/Skip
            HapticFeedback.lightImpact();
            widget.onDecline?.call();
            return true;
          }
        },
        background: _buildSwipeBackground(
          color: AppTheme.success,
          icon: Icons.check_circle,
          label: 'ACCEPTER',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeBackground(
          color: AppTheme.textTertiary,
          icon: Icons.skip_next,
          label: 'PASSER',
          alignment: Alignment.centerRight,
        ),
        child: _buildCard(theme),
      );
    }

    return _buildCard(theme);
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: AppTheme.background, size: 32),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: AppTheme.background, size: 32),
              ],
      ),
    );
  }

  Widget _buildCard(ThemeData theme) {
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd MMM', 'fr_CA');
    final isUrgent = widget.job.isPriority || _timeRemaining.inMinutes < 60;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: widget.job.isPriority ? 6 : 2,
        shadowColor: widget.job.isPriority
            ? AppTheme.warning.withOpacity(0.4)
            : AppTheme.shadowColor.withOpacity(0.26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: widget.job.isPriority
              ? const BorderSide(color: AppTheme.warning, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Shimmer effect for urgent jobs
              if (widget.job.isPriority)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.transparent,
                                AppTheme.warning.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: [
                                _shimmerController.value - 0.3,
                                _shimmerController.value,
                                _shimmerController.value + 0.3,
                              ].map((s) => s.clamp(0.0, 1.0)).toList(),
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(color: AppTheme.surface),
                        );
                      },
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with countdown, priority badge, status and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (widget.job.status != JobStatus.pending) ...[
                                _buildStatusChip(widget.job.status),
                                const SizedBox(width: 8),
                              ] else ...[
                                if (widget.job.isPriority) ...[
                                  _buildUrgentBadge(),
                                  const SizedBox(width: 8),
                                ],
                                _buildCountdownBadge(isUrgent),
                              ],
                            ],
                          ),
                        ),
                        _buildPriceTag(theme),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Address with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: AppTheme.info,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.job.displayAddress,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.job.distanceKm != null)
                                Text(
                                  '${widget.job.distanceKm!.toStringAsFixed(1)} km • ~${_estimateTravelTime(widget.job.distanceKm!)} min',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Time and vehicle info row
                    Row(
                      children: [
                        // Time
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: isUrgent ? AppTheme.error : AppTheme.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${dateFormatter.format(widget.job.departureTime)} à ${timeFormatter.format(widget.job.departureTime)}',
                                style: TextStyle(
                                  color:
                                      isUrgent ? AppTheme.error : AppTheme.textSecondary,
                                  fontWeight: isUrgent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vehicle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: AppTheme.textSecondary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.job.vehicle.displayName,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Service options
                    if (widget.job.serviceOptions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildServiceOptions(),
                    ],

                    // Accept button (non-swipe mode)
                    if (widget.showAcceptButton &&
                        widget.job.status == JobStatus.pending &&
                        !widget.enableSwipe) ...[
                      const SizedBox(height: 12),
                      _buildAcceptButton(),
                    ],

                    // Swipe hint for swipe mode
                    if (widget.showAcceptButton &&
                        widget.job.status == JobStatus.pending &&
                        widget.enableSwipe) ...[
                      const SizedBox(height: 8),
                      _buildSwipeHint(),
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

  Widget _buildUrgentBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warning.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: AppTheme.background, size: 16),
                SizedBox(width: 4),
                Text(
                  'URGENT',
                  style: TextStyle(
                    color: AppTheme.background,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        // Reverse animation
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildCountdownBadge(bool isUrgent) {
    if (_timeRemaining.inSeconds <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.errorLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: AppTheme.error, size: 14),
            const SizedBox(width: 4),
            Text(
              'DÉPASSÉ',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    String timeText;
    if (hours > 0) {
      timeText = '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      timeText = '${minutes}m ${seconds}s';
    } else {
      timeText = '${seconds}s';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent ? AppTheme.errorLight : AppTheme.infoLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isUrgent ? AppTheme.error.withOpacity(0.3) : AppTheme.info.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isUrgent ? AppTheme.error : AppTheme.info,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              color: isUrgent ? AppTheme.error : AppTheme.info,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_money, color: AppTheme.success, size: 18),
          Text(
            widget.job.totalPrice.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOptions() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.job.serviceOptions.map((option) {
        final optionData = _getServiceOptionData(option);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: optionData.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: optionData.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(optionData.icon, size: 12, color: optionData.color),
              const SizedBox(width: 4),
              Text(
                optionData.label,
                style: TextStyle(
                  fontSize: 11,
                  color: optionData.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAcceptButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.isLoading ? null : widget.onAccept,
        icon: widget.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.background,
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(widget.isLoading ? 'Acceptation...' : 'Accepter ce job'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: AppTheme.background,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSwipeHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swipe, color: AppTheme.textTertiary, size: 16),
        const SizedBox(width: 6),
        Text(
          'Glisser → accepter  |  ← passer',
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case JobStatus.pending:
        color = AppTheme.info;
        label = 'Disponible';
        icon = Icons.pending;
        break;
      case JobStatus.assigned:
        color = AppTheme.warning;
        label = 'Assigné';
        icon = Icons.assignment_ind;
        break;
      case JobStatus.enRoute:
        color = AppTheme.primary2;
        label = 'En route';
        icon = Icons.directions_car;
        break;
      case JobStatus.inProgress:
        color = AppTheme.primary2;
        label = 'En cours';
        icon = Icons.engineering;
        break;
      case JobStatus.completed:
        color = AppTheme.success;
        label = 'Terminé';
        icon = Icons.check_circle;
        break;
      case JobStatus.cancelled:
        color = AppTheme.error;
        label = 'Annulé';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _estimateTravelTime(double distanceKm) {
    // Estimation basée sur une vitesse moyenne de 30 km/h en ville
    return (distanceKm / 30 * 60).ceil();
  }

  _ServiceOptionData _getServiceOptionData(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return _ServiceOptionData(
          label: 'Vitres',
          icon: Icons.visibility,
          color: AppTheme.info,
        );
      case ServiceOption.doorDeicing:
        return _ServiceOptionData(
          label: 'Portes',
          icon: Icons.door_front_door,
          color: AppTheme.secondary,
        );
      case ServiceOption.wheelClearance:
        return _ServiceOptionData(
          label: 'Roues',
          icon: Icons.trip_origin,
          color: AppTheme.primary2,
        );
    }
  }
}

class _ServiceOptionData {
  final String label;
  final IconData icon;
  final Color color;

  _ServiceOptionData({
    required this.label,
    required this.icon,
    required this.color,
  });
}
