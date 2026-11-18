import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart' hide ServiceOption;
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/worker_job.dart';
import '../../../../core/utils/money.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

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
          label: l10n.worker_acceptLabel,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeBackground(
          color: AppTheme.textTertiary,
          icon: Icons.skip_next,
          label: l10n.worker_passLabel,
          alignment: Alignment.centerRight,
        ),
        child: _buildCard(theme, l10n, locale),
      );
    }

    return _buildCard(theme, l10n, locale);
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: AppTheme.onPrimary, size: 32),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: AppTheme.onPrimary, size: 32),
              ],
      ),
    );
  }

  Widget _buildCard(ThemeData theme, AppLocalizations l10n, String locale) {
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd MMM', locale == 'fr' ? 'fr_CA' : 'en');
    // Echeance proche : le compte a rebours passe en orange
    final isUrgent = _timeRemaining.inMinutes < 60;

    final radius = BorderRadius.circular(AppTheme.radiusLG);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.7),
        ),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          child: Stack(
            children: [
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
                                _buildStatusChip(widget.job.status, l10n),
                                const SizedBox(width: 8),
                              ] else ...[
                                _buildCountdownBadge(isUrgent, l10n),
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
                        Icon(
                          Icons.place_outlined,
                          color: AppTheme.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.job.displayAddress,
                                style: AppTheme.headlineSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.job.distanceKm != null)
                                Text(
                                  l10n.worker_distanceAndTime(
                                    widget.job.distanceKm!.toStringAsFixed(1),
                                    _estimateTravelTime(widget.job.distanceKm!)
                                        .toString(),
                                  ),
                                  style: AppTheme.bodySmall,
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
                                Icons.schedule_rounded,
                                color: isUrgent
                                    ? AppTheme.accentDark
                                    : AppTheme.textTertiary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.worker_dateAtTime(
                                  dateFormatter
                                      .format(widget.job.departureTime),
                                  timeFormatter
                                      .format(widget.job.departureTime),
                                ),
                                style: TextStyle(
                                  color: isUrgent
                                      ? AppTheme.accentDark
                                      : AppTheme.textSecondary,
                                  fontWeight: isUrgent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vehicle with photo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildVehiclePhoto(widget.job.vehicle.photoUrl),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.job.vehicle.displayName,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (widget.job.vehicle.color != null)
                                    Text(
                                      widget.job.vehicle.color!,
                                      style: TextStyle(
                                        color: AppTheme.textTertiary,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Service options
                    if (widget.job.serviceOptions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildServiceOptions(l10n),
                    ],

                    // Required equipment
                    if (widget.job.requiredEquipment.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildRequiredEquipment(l10n),
                    ],

                    // Accept button (non-swipe mode)
                    if (widget.showAcceptButton &&
                        widget.job.status == JobStatus.pending &&
                        !widget.enableSwipe) ...[
                      const SizedBox(height: 12),
                      _buildAcceptButton(l10n),
                    ],

                    // Swipe hint for swipe mode
                    if (widget.showAcceptButton &&
                        widget.job.status == JobStatus.pending &&
                        widget.enableSwipe) ...[
                      const SizedBox(height: 8),
                      _buildSwipeHint(l10n),
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

  Widget _buildCountdownBadge(bool isUrgent, AppLocalizations l10n) {
    if (_timeRemaining.inSeconds <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.errorLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: AppTheme.error, size: 14),
            const SizedBox(width: 4),
            Text(
              l10n.worker_exceeded,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isUrgent ? AppTheme.accentLight : AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: isUrgent ? AppTheme.accentDark : AppTheme.textSecondary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              color: isUrgent ? AppTheme.accentDark : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag(ThemeData theme) {
    return Text(
      formatMoney(context, widget.job.workerEarnings),
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        letterSpacing: -0.4,
        color: AppTheme.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildServiceOptions(AppLocalizations l10n) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.job.serviceOptions.map((option) {
        final optionData = _getServiceOptionData(option, l10n);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(optionData.icon, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                optionData.label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRequiredEquipment(AppLocalizations l10n) {
    final hasEquipment = widget.job.workerHasEquipment;
    final statusColor = hasEquipment ? AppTheme.success : AppTheme.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with compatibility status
        Row(
          children: [
            Icon(
              hasEquipment ? Icons.check_circle : Icons.warning_amber_rounded,
              size: 14,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              hasEquipment
                  ? l10n.worker_equipmentCompatible
                  : l10n.worker_equipmentRequiredLabel,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Equipment chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.job.requiredEquipment.map((equipment) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    equipment.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAcceptButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.isLoading ? null : widget.onAccept,
        icon: widget.isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.onPrimary,
                ),
              )
            : const Icon(Icons.check_rounded),
        label: Text(widget.isLoading
            ? l10n.worker_accepting
            : l10n.worker_acceptThisJob),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: AppTheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildSwipeHint(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swipe_right_alt_rounded,
            color: AppTheme.textTertiary, size: 16),
        const SizedBox(width: 6),
        Text(l10n.worker_swipeHint, style: AppTheme.labelSmall),
      ],
    );
  }

  Widget _buildStatusChip(JobStatus status, AppLocalizations l10n) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case JobStatus.pending:
        color = AppTheme.statusPending;
        label = l10n.worker_statusAvailable;
        icon = Icons.pending;
        break;
      case JobStatus.assigned:
        color = AppTheme.statusAssigned;
        label = l10n.worker_statusAssigned;
        icon = Icons.assignment_ind;
        break;
      case JobStatus.enRoute:
        color = AppTheme.statusEnRoute;
        label = l10n.worker_statusEnRoute;
        icon = Icons.directions_car;
        break;
      case JobStatus.inProgress:
        color = AppTheme.statusInProgress;
        label = l10n.worker_statusInProgress;
        icon = Icons.engineering;
        break;
      case JobStatus.completed:
        color = AppTheme.success;
        label = l10n.worker_statusCompleted;
        icon = Icons.check_circle;
        break;
      case JobStatus.cancelled:
        color = AppTheme.error;
        label = l10n.worker_statusCancelled;
        icon = Icons.cancel;
        break;
    }

    return StatusBadge(label: label, color: color, icon: icon);
  }

  int _estimateTravelTime(double distanceKm) {
    // Estimation based on average speed of 30 km/h in the city
    return (distanceKm / 30 * 60).ceil();
  }

  _ServiceOptionData _getServiceOptionData(
      ServiceOption option, AppLocalizations l10n) {
    switch (option) {
      case ServiceOption.windowScraping:
        return _ServiceOptionData(
          label: l10n.worker_serviceWindows,
          icon: Icons.visibility,
          color: AppTheme.info,
        );
      case ServiceOption.doorDeicing:
        return _ServiceOptionData(
          label: l10n.worker_serviceDoors,
          icon: Icons.door_front_door,
          color: AppTheme.secondary,
        );
      case ServiceOption.wheelClearance:
        return _ServiceOptionData(
          label: l10n.worker_serviceWheels,
          icon: Icons.trip_origin,
          color: AppTheme.primary2,
        );
      case ServiceOption.roofClearing:
        return _ServiceOptionData(
          label: l10n.worker_serviceRoof,
          icon: Icons.car_rental,
          color: AppTheme.warning,
        );
      case ServiceOption.saltSpreading:
        return _ServiceOptionData(
          label: l10n.worker_serviceSalt,
          icon: Icons.grain_rounded,
          color: AppTheme.info,
        );
      case ServiceOption.lightsCleaning:
        return _ServiceOptionData(
          label: l10n.worker_serviceLights,
          icon: Icons.highlight_rounded,
          color: AppTheme.secondary,
        );
      case ServiceOption.perimeterClearance:
        return _ServiceOptionData(
          label: l10n.worker_servicePerimeter,
          icon: Icons.crop_free_rounded,
          color: AppTheme.primary,
        );
      case ServiceOption.exhaustCheck:
        return _ServiceOptionData(
          label: l10n.worker_serviceExhaustShort,
          icon: Icons.air_rounded,
          color: AppTheme.textSecondary,
        );
    }
  }

  Widget _buildVehiclePhoto(String? photoUrl) {
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final fullPhotoUrl = hasPhoto ? '${AppConfig.apiBaseUrl}$photoUrl' : null;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? CachedNetworkImage(
              imageUrl: fullPhotoUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Icon(
                Icons.directions_car,
                color: AppTheme.primary,
                size: 14,
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.directions_car,
                color: AppTheme.primary,
                size: 14,
              ),
            )
          : Icon(
              Icons.directions_car,
              color: AppTheme.primary,
              size: 14,
            ),
    );
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
