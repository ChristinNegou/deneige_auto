import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../bloc/reservation_list_bloc.dart';
import '../../../widgets/rating_tip_dialog.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../disputes/presentation/pages/report_no_show_page.dart';
import '../../../disputes/presentation/pages/create_dispute_page.dart';

class ReservationDetailsPage extends StatelessWidget {
  final String reservationId;

  const ReservationDetailsPage({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ReservationListBloc>()..add(LoadReservationById(reservationId)),
      child: ReservationDetailsView(reservationId: reservationId),
    );
  }
}

class ReservationDetailsView extends StatefulWidget {
  final String reservationId;

  const ReservationDetailsView({super.key, required this.reservationId});

  @override
  State<ReservationDetailsView> createState() => _ReservationDetailsViewState();
}

class _ReservationDetailsViewState extends State<ReservationDetailsView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-refresh every 15 seconds for active reservations
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        final state = context.read<ReservationListBloc>().state;
        final reservation = state.selectedReservation;
        // Ne rafraîchir que si la réservation est active
        if (reservation != null && _isActiveReservation(reservation.status)) {
          context
              .read<ReservationListBloc>()
              .add(LoadReservationById(widget.reservationId));
        }
      }
    });
  }

  bool _isActiveReservation(ReservationStatus status) {
    return status == ReservationStatus.pending ||
        status == ReservationStatus.assigned ||
        status == ReservationStatus.enRoute ||
        status == ReservationStatus.inProgress;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ReservationListBloc, ReservationListState>(
      builder: (context, state) {
        final reservation = state.selectedReservation;

        // Afficher le chargement uniquement lors du premier chargement
        // (quand on n'a pas encore de réservation)
        if (state.isLoading && reservation == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              title: Text(
                l10n.reservation_details,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.textPrimary,
            ),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        // Réservation introuvable après chargement
        if (reservation == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              title: Text(
                l10n.reservation_details,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.textPrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 64, color: AppTheme.textTertiary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.reservation_notFound,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.reservation_notFoundSubtitle,
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<ReservationListBloc>()
                          .add(LoadReservationById(widget.reservationId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.reservation_refresh),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.common_back,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isActive = reservation.status == ReservationStatus.enRoute ||
            reservation.status == ReservationStatus.inProgress;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: ColoredBox(
            color: AppTheme.background,
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    backgroundColor: AppTheme.background,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    floating: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(l10n.reservation_details,
                        style: AppTheme.labelMedium),
                    centerTitle: true,
                    actions: [
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorLight,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Row(
                            children: [
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.reservation_live,
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Status Header
                        _buildStatusHeader(context, reservation),

                        // Main Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline
                              _buildTimeline(context, reservation),
                              const SizedBox(height: 16),

                              // Worker Card (if assigned)
                              if (reservation.workerId != null) ...[
                                _buildWorkerCard(context, reservation),
                                const SizedBox(height: 16),
                              ],

                              // Quick Actions (if active)
                              if (isActive) ...[
                                _buildQuickActions(context, reservation),
                                const SizedBox(height: 16),
                              ],

                              // Details Card
                              _buildDetailsCard(context, reservation),
                              const SizedBox(height: 16),

                              // Service Options Card
                              _buildServiceOptionsCard(context, reservation),
                              const SizedBox(height: 16),

                              // Photos Card (if available)
                              if (reservation.afterPhotoUrl != null ||
                                  reservation.beforePhotoUrl != null) ...[
                                _buildPhotosCard(context, reservation),
                                const SizedBox(height: 16),
                              ],

                              // Price Card
                              _buildPriceCard(context, reservation),
                              const SizedBox(height: 24),

                              // Rating section (if completed and not rated)
                              if (reservation.status ==
                                  ReservationStatus.completed)
                                _buildRatingSection(context, reservation),

                              // Action Buttons
                              if (reservation.canBeEdited)
                                _buildEditButton(context, reservation),
                              if (reservation.canBeEdited &&
                                  reservation.canBeCancelled)
                                const SizedBox(height: 12),
                              if (reservation.canBeCancelled)
                                _buildCancelButton(context, reservation),

                              // Report No-Show button
                              if (_canReportNoShow(reservation)) ...[
                                const SizedBox(height: 12),
                                _buildReportNoShowButton(context, reservation),
                              ],

                              // Report Problem button (for completed reservations)
                              if (_canReportProblem(reservation)) ...[
                                const SizedBox(height: 12),
                                _buildReportProblemButton(context, reservation),
                              ],

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getStatusColor(reservation.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(
            label: reservation.status.displayName,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusDescription(l10n, reservation),
            style: AppTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat(
                    'EEEE d MMMM, HH:mm',
                    Localizations.localeOf(context).languageCode == 'en'
                        ? 'en_CA'
                        : 'fr_CA')
                .format(reservation.departureTime),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(AppLocalizations l10n, Reservation reservation) {
    switch (reservation.status) {
      case ReservationStatus.pending:
        return l10n.reservation_statusPending;
      case ReservationStatus.assigned:
        return l10n.reservation_statusAssigned;
      case ReservationStatus.enRoute:
        return l10n.reservation_statusEnRoute(
            reservation.workerName ?? 'Le d\u00e9neigeur');
      case ReservationStatus.inProgress:
        return l10n.reservation_statusInProgress;
      case ReservationStatus.completed:
        return l10n.reservation_statusCompleted;
      case ReservationStatus.cancelled:
        return l10n.reservation_statusCancelled;
      case ReservationStatus.late:
        return l10n.reservation_statusDelayed;
    }
  }

  Widget _buildTimeline(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final statuses = [
      ReservationStatus.pending,
      ReservationStatus.assigned,
      ReservationStatus.enRoute,
      ReservationStatus.inProgress,
      ReservationStatus.completed,
    ];

    final currentIndex = statuses.indexOf(reservation.status);
    // Une reservation annulee ou en retard n'est pas sur le parcours normal
    if (currentIndex < 0) return const SizedBox.shrink();
    final currentColor = _getStatusColor(reservation.status);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reservation_progress, style: AppTheme.headlineSmall),
          const SizedBox(height: 14),
          Row(
            children: List.generate(statuses.length, (index) {
              final Color color;
              if (index < currentIndex) {
                color = AppTheme.primary;
              } else if (index == currentIndex) {
                color = currentColor;
              } else {
                color = AppTheme.border;
              }
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                      right: index < statuses.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: statuses.asMap().entries.map((entry) {
              final isCurrent = entry.key == currentIndex;
              final isDone = entry.key < currentIndex;
              return Expanded(
                child: Text(
                  _getShortStatusName(l10n, entry.value),
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: isCurrent
                        ? AppTheme.textPrimary
                        : isDone
                            ? AppTheme.textSecondary
                            : AppTheme.textTertiary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getShortStatusName(AppLocalizations l10n, ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return l10n.reservation_shortPending;
      case ReservationStatus.assigned:
        return l10n.reservation_shortAssigned;
      case ReservationStatus.enRoute:
        return l10n.reservation_shortEnRoute;
      case ReservationStatus.inProgress:
        return l10n.reservation_shortInProgress;
      case ReservationStatus.completed:
        return l10n.reservation_shortCompleted;
      case ReservationStatus.cancelled:
        return l10n.reservation_shortCancelled;
      case ReservationStatus.late:
        return l10n.reservation_shortDelayed;
    }
  }

  Widget _buildWorkerCard(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final initial = reservation.workerName?.isNotEmpty == true
        ? reservation.workerName![0].toUpperCase()
        : '?';
    final initialAvatar = Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppTheme.onPrimary,
        ),
      ),
    );

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: reservation.workerPhotoUrl != null &&
                      reservation.workerPhotoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: reservation.workerPhotoUrl!,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      placeholder: (context, url) => initialAvatar,
                      errorWidget: (context, url, error) => initialAvatar,
                    )
                  : initialAvatar,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.reservation_yourWorker, style: AppTheme.labelMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reservation.workerName ??
                            l10n.reservation_workerAssigned,
                        style: AppTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (reservation.workerIsVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        color: AppTheme.info,
                        size: 16,
                        semanticLabel: l10n.worker_verified,
                      ),
                    ],
                  ],
                ),
                if (reservation.rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (reservation.rating ?? 0).round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppTheme.warning,
                        size: 15,
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => _openChat(context, reservation),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceContainer,
              foregroundColor: AppTheme.textPrimary,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
          ),
          if (reservation.workerPhone != null)
            IconButton.filledTonal(
              onPressed: () => _callWorker(reservation),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainer,
                foregroundColor: AppTheme.textPrimary,
              ),
              icon: const Icon(Icons.phone_outlined, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.reservation_chat,
            filled: true,
            onTap: () => _openChat(context, reservation),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.phone_outlined,
            label: l10n.common_call,
            onTap: () => _callWorker(reservation),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.map_outlined,
            label: l10n.reservation_map,
            onTap: () => _openMap(reservation),
          ),
        ),
      ],
    );
  }

  void _openChat(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.reservation_userNotAuth,
            style: TextStyle(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Vérifier qu'un déneigeur est assigné
    if (reservation.workerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.onPrimary),
              const SizedBox(width: 12),
              Text(
                l10n.reservation_noWorkerYet,
                style: TextStyle(color: AppTheme.onPrimary),
              ),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<ChatBloc>()..add(LoadMessages(reservation.id)),
          child: ChatScreen(
            reservationId: reservation.id,
            otherUserName:
                reservation.workerName ?? l10n.reservation_workerAssigned,
            otherUserPhoto: null,
            currentUserId: authState.user.id,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    final foreground = filled ? AppTheme.onPrimary : AppTheme.textPrimary;
    return Material(
      color: filled ? AppTheme.primary : AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat(
        'd MMM yyyy, HH:mm',
        Localizations.localeOf(context).languageCode == 'en'
            ? 'en_CA'
            : 'fr_CA');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reservation_info, style: AppTheme.headlineSmall),
          const Divider(height: 28),
          _buildDetailRow(
            Icons.directions_car,
            l10n.reservation_vehicle,
            reservation.vehicle.displayName,
            subtitle: reservation.vehicle.color,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.local_parking,
            l10n.reservation_location,
            reservation.parkingSpot.displayName,
          ),
          if (reservation.locationAddress != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.location_on,
              l10n.common_address,
              reservation.locationAddress!,
            ),
          ],
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.schedule,
            l10n.reservation_departureTime,
            dateFormat.format(reservation.departureTime),
          ),
          if (reservation.assignedAt != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.person_add,
              l10n.reservation_assignedAt,
              dateFormat.format(reservation.assignedAt!),
            ),
          ],
          if (reservation.startedAt != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.play_arrow,
              l10n.reservation_startedAt,
              dateFormat.format(reservation.startedAt!),
            ),
          ],
          if (reservation.completedAt != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.check_circle,
              l10n.reservation_completedAt,
              dateFormat.format(reservation.completedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceOptionsCard(
      BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reservation_servicesRequested,
              style: AppTheme.headlineSmall),
          const Divider(height: 28),
          // Base service
          _buildServiceItem(
            icon: Icons.cleaning_services,
            label: l10n.reservation_basicSnowRemoval,
            price: reservation.basePrice,
            isIncluded: true,
          ),
          if (reservation.serviceOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...reservation.serviceOptions.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildServiceItem(
                  icon: _getOptionIcon(option),
                  label: _getOptionLabel(l10n, option),
                  price: _getOptionPrice(option),
                  isIncluded: true,
                ),
              );
            }),
          ],
          if (reservation.snowDepthCm != null) ...[
            const Divider(height: 28),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Icon(Icons.ac_unit_rounded,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.reservation_snowDepthCm(
                      reservation.snowDepthCm.toString()),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required double price,
    required bool isIncluded,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Icon(
            icon,
            color: isIncluded ? AppTheme.primary : AppTheme.textTertiary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
        ),
        Text(
          '${price.toStringAsFixed(2)} \$',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  IconData _getOptionIcon(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return Icons.window;
      case ServiceOption.doorDeicing:
        return Icons.door_front_door;
      case ServiceOption.wheelClearance:
        return Icons.trip_origin;
      case ServiceOption.roofClearing:
        return Icons.car_rental;
      case ServiceOption.saltSpreading:
        return Icons.grain_rounded;
      case ServiceOption.lightsCleaning:
        return Icons.highlight_rounded;
      case ServiceOption.perimeterClearance:
        return Icons.crop_free_rounded;
      case ServiceOption.exhaustCheck:
        return Icons.air_rounded;
    }
  }

  String _getOptionLabel(AppLocalizations l10n, ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return l10n.reservation_windowScraping;
      case ServiceOption.doorDeicing:
        return l10n.reservation_doorDeicing;
      case ServiceOption.wheelClearance:
        return l10n.reservation_wheelClearing;
      case ServiceOption.roofClearing:
        return l10n.reservation_roofSnowRemoval;
      case ServiceOption.saltSpreading:
        return l10n.reservation_saltSpreading;
      case ServiceOption.lightsCleaning:
        return l10n.reservation_lightsCleanup;
      case ServiceOption.perimeterClearance:
        return l10n.reservation_perimeterClearing;
      case ServiceOption.exhaustCheck:
        return l10n.reservation_exhaustCheck;
    }
  }

  double _getOptionPrice(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return 5.0;
      case ServiceOption.doorDeicing:
        return 3.0;
      case ServiceOption.wheelClearance:
        return 4.0;
      case ServiceOption.roofClearing:
        return 8.0;
      case ServiceOption.saltSpreading:
        return 5.0;
      case ServiceOption.lightsCleaning:
        return 3.0;
      case ServiceOption.perimeterClearance:
        return 12.0;
      case ServiceOption.exhaustCheck:
        return 2.0;
    }
  }

  Widget _buildPhotosCard(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reservation_photos, style: AppTheme.headlineSmall),
          const Divider(height: 28),

          // After Photo (primary - result)
          if (reservation.afterPhotoUrl != null) ...[
            Text(l10n.reservation_afterPhoto, style: AppTheme.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showPhotoFullscreen(
                context,
                reservation.afterPhotoUrl!,
                l10n.reservation_afterPhoto,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: reservation.afterPhotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                    errorWidget: (context, url, error) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error,
                            color: AppTheme.textTertiary, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          l10n.reservation_photoUnavailable,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.reservation_tapToEnlarge,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Before Photo (if exists)
          if (reservation.beforePhotoUrl != null) ...[
            if (reservation.afterPhotoUrl != null) const SizedBox(height: 20),
            Text(
              l10n.reservation_beforePhoto,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showPhotoFullscreen(
                context,
                reservation.beforePhotoUrl!,
                l10n.reservation_beforePhoto,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: reservation.beforePhotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                    errorWidget: (context, url, error) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error,
                            color: AppTheme.textTertiary, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          l10n.reservation_photoUnavailable,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPhotoFullscreen(
      BuildContext context, String imageUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reservation_totalPrice,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reservation.totalPrice.toStringAsFixed(2)} \$',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppTheme.onPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (reservation.tip != null && reservation.tip! > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.reservation_tipAmount(
                        reservation.tip!.toStringAsFixed(2)),
                    style: TextStyle(
                      color: AppTheme.onPrimary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    if (reservation.rating != null) {
      // Already rated - show the rating
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.successLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star, color: AppTheme.success, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reservation_yourRating,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < reservation.rating!.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: AppTheme.warning,
                        size: 24,
                      );
                    }),
                  ),
                  if (reservation.review != null &&
                      reservation.review!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"${reservation.review}"',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Not rated yet - show button to rate
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: const BorderSide(color: AppTheme.border, width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            RatingTipDialog.show(
              context,
              workerName:
                  reservation.workerName ?? l10n.reservation_workerAssigned,
              servicePrice: reservation.totalPrice,
              onSubmit: (rating, tip, comment) async {
                // Submit rating to backend
                final repository = sl<ReservationRepository>();

                // Send rating first
                final ratingResult = await repository.rateReservation(
                  reservationId: reservation.id,
                  rating: rating,
                  review: comment,
                );

                ratingResult.fold(
                  (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error, color: AppTheme.onPrimary),
                            const SizedBox(width: 12),
                            Text(
                              l10n.resDetail_errorPrefix(failure.message),
                              style: TextStyle(color: AppTheme.onPrimary),
                            ),
                          ],
                        ),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  (success) async {
                    // If tip is provided, send it
                    if (tip != null && tip > 0) {
                      final tipResult = await repository.addTip(
                        reservationId: reservation.id,
                        amount: tip,
                      );

                      tipResult.fold(
                        (failure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.warning,
                                      color: AppTheme.onPrimary),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.resDetail_ratingSuccessTipError(
                                        failure.message),
                                    style: TextStyle(color: AppTheme.onPrimary),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.warning,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        (tipSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: AppTheme.onPrimary),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.resDetail_tipSent(
                                        tip.toStringAsFixed(0)),
                                    style: TextStyle(color: AppTheme.onPrimary),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppTheme.onPrimary),
                              const SizedBox(width: 12),
                              Text(
                                l10n.resDetail_ratingSuccess,
                                style: TextStyle(color: AppTheme.onPrimary),
                              ),
                            ],
                          ),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }

                    // Retourner au dashboard après un court délai pour voir le message
                    await Future.delayed(const Duration(milliseconds: 1500));
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: AppTheme.warning, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.reservation_rateService,
                          style: AppTheme.headlineSmall),
                      const SizedBox(height: 2),
                      Text(l10n.reservation_rateSubtitle,
                          style: AppTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            AppRoutes.editReservation,
            arguments: reservation,
          );
        },
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.reservation_edit),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelDialog(context, reservation),
        icon: const Icon(Icons.close_rounded),
        label: Text(l10n.reservation_cancelReservation),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();

    // Calculer les frais selon le statut
    String feeMessage;
    int feePercent;
    Color feeColor;

    switch (reservation.status) {
      case ReservationStatus.pending:
      case ReservationStatus.assigned:
        feePercent = 0;
        feeMessage = l10n.reservation_cancelFullRefund;
        feeColor = AppTheme.success;
        break;
      case ReservationStatus.enRoute:
        feePercent = 50;
        feeMessage = l10n.reservation_cancelHalfRefund(
            (reservation.totalPrice * 0.5).toStringAsFixed(2));
        feeColor = AppTheme.warning;
        break;
      case ReservationStatus.inProgress:
        feePercent = 100;
        feeMessage = l10n.reservation_cancelNoRefund;
        feeColor = AppTheme.error;
        break;
      default:
        feePercent = 0;
        feeMessage = '';
        feeColor = AppTheme.textTertiary;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning, color: AppTheme.error),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.reservation_cancelConfirmTitle,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reservation_cancelConfirmMessage,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: feeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    feePercent == 0 ? Icons.check_circle : Icons.info,
                    color: feeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feeMessage,
                      style: TextStyle(
                        color: feeColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.reservation_cancelKeep,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ReservationListBloc>().add(
                    CancelReservationEvent(reservation.id),
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.onPrimary,
              minimumSize: const Size(0, 44),
            ),
            child: Text(l10n.reservation_cancelYes),
          ),
        ],
      ),
    );
  }

  Future<void> _callWorker(Reservation reservation) async {
    if (reservation.workerPhone != null) {
      final uri = Uri.parse('tel:${reservation.workerPhone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.reservation_phoneUnavailable,
              style: TextStyle(color: AppTheme.onPrimary),
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    }
  }

  Future<void> _openMap(Reservation reservation) async {
    if (reservation.locationLatitude != null &&
        reservation.locationLongitude != null) {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${reservation.locationLatitude},${reservation.locationLongitude}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppTheme.statusPending;
      case ReservationStatus.assigned:
        return AppTheme.statusAssigned;
      case ReservationStatus.enRoute:
        return AppTheme.statusEnRoute;
      case ReservationStatus.inProgress:
        return AppTheme.statusInProgress;
      case ReservationStatus.completed:
        return AppTheme.statusCompleted;
      case ReservationStatus.cancelled:
        return AppTheme.statusCancelled;
      case ReservationStatus.late:
        return AppTheme.error;
    }
  }

  /// Check if the user can report a no-show for this reservation
  bool _canReportNoShow(Reservation reservation) {
    // Cannot report if cancelled
    if (reservation.status == ReservationStatus.cancelled) {
      return false;
    }

    // Must have a worker assigned
    if (reservation.workerId == null) {
      return false;
    }

    // Check if departure time has passed
    final now = DateTime.now();
    final departureTime = reservation.departureTime;

    // Allow reporting if:
    // 1. The departure time has passed (with 30 min grace period)
    // 2. Status is assigned, enRoute, or late (worker was supposed to come but maybe didn't)
    // 3. Or completed within the last 24 hours (in case user realizes later)

    if (reservation.status == ReservationStatus.completed) {
      // Can report within 24 hours of completion
      final completedAt = reservation.completedAt;
      if (completedAt != null) {
        final hoursSinceCompletion = now.difference(completedAt).inHours;
        return hoursSinceCompletion < 24;
      }
      return false;
    }

    if (reservation.status == ReservationStatus.assigned ||
        reservation.status == ReservationStatus.enRoute ||
        reservation.status == ReservationStatus.late) {
      // Can report if 30 minutes past departure time
      return now.isAfter(departureTime.add(const Duration(minutes: 30)));
    }

    return false;
  }

  Widget _buildReportNoShowButton(
      BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportNoShowPage(
                reservationId: reservation.id,
                workerName: reservation.workerName,
                totalPrice: reservation.totalPrice,
                departureTime: reservation.departureTime,
              ),
            ),
          ).then((reported) {
            if (reported == true) {
              if (!mounted) return;
              this
                  .context
                  .read<ReservationListBloc>()
                  .add(LoadReservationById(widget.reservationId));

              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.onPrimary),
                      const SizedBox(width: 12),
                      Text(
                        l10n.reservation_noShowReported,
                        style: TextStyle(color: AppTheme.onPrimary),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          });
        },
        icon: Icon(Icons.person_off, color: AppTheme.error),
        label: Text(
          l10n.reservation_reportNoShow,
          style: TextStyle(color: AppTheme.error),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  /// Check if the user can report a general problem for this reservation
  bool _canReportProblem(Reservation reservation) {
    // Cannot report if cancelled
    if (reservation.status == ReservationStatus.cancelled) {
      return false;
    }

    // Must have a worker assigned
    if (reservation.workerId == null) {
      return false;
    }

    // Can report problem for completed reservations within 72 hours
    if (reservation.status == ReservationStatus.completed) {
      final completedAt = reservation.completedAt;
      if (completedAt != null) {
        final hoursSinceCompletion =
            DateTime.now().difference(completedAt).inHours;
        return hoursSinceCompletion < 72;
      }
      return false;
    }

    // Can also report for in-progress or late reservations
    if (reservation.status == ReservationStatus.inProgress ||
        reservation.status == ReservationStatus.late) {
      return true;
    }

    return false;
  }

  Widget _buildReportProblemButton(
      BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateDisputePage(
                reservationId: reservation.id,
                workerName: reservation.workerName,
                totalPrice: reservation.totalPrice,
                serviceDate:
                    reservation.completedAt ?? reservation.departureTime,
              ),
            ),
          ).then((reported) {
            if (reported == true) {
              if (!mounted) return;
              this
                  .context
                  .read<ReservationListBloc>()
                  .add(LoadReservationById(widget.reservationId));

              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.onPrimary),
                      const SizedBox(width: 12),
                      Text(
                        l10n.dispute_created,
                        style: TextStyle(color: AppTheme.onPrimary),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          });
        },
        icon: Icon(Icons.report_problem, color: AppTheme.warning),
        label: Text(
          l10n.dispute_reportProblem,
          style: TextStyle(color: AppTheme.warning),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.warning,
          side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
