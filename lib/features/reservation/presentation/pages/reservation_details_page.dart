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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.info,
                      foregroundColor: AppTheme.textPrimary,
                    ),
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getStatusColor(reservation.status),
                  _getStatusColor(reservation.status).withValues(alpha: 0.7),
                  AppTheme.background,
                ],
                stops: const [0.0, 0.15, 0.3],
              ),
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    floating: true,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.textPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.reservation_live,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline
                                _buildTimeline(context, reservation),
                                const SizedBox(height: 24),

                                // Worker Card (if assigned)
                                if (reservation.workerId != null)
                                  _buildWorkerCard(context, reservation),

                                const SizedBox(height: 20),

                                // Quick Actions (if active)
                                if (isActive) ...[
                                  _buildQuickActions(context, reservation),
                                  const SizedBox(height: 20),
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
                                  _buildReportNoShowButton(
                                      context, reservation),
                                ],

                                const SizedBox(height: 40),
                              ],
                            ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        children: [
          // Status Icon with animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.border.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                reservation.status.icon,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            reservation.status.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(l10n, reservation),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: AppTheme.info),
              const SizedBox(width: 8),
              Text(
                l10n.reservation_progress,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(statuses.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Connector line
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.success : AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              } else {
                // Step circle
                final stepIndex = index ~/ 2;
                final status = statuses[stepIndex];
                final isCompleted = stepIndex < currentIndex;
                final isCurrent = stepIndex == currentIndex;

                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.success
                        : isCurrent
                            ? _getStatusColor(status)
                            : AppTheme.surfaceContainer,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(
                            color:
                                _getStatusColor(status).withValues(alpha: 0.3),
                            width: 4,
                          )
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check,
                            color: AppTheme.background, size: 20)
                        : Text(
                            status.icon,
                            style: TextStyle(
                              fontSize: isCurrent ? 18 : 14,
                            ),
                          ),
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: statuses.map((status) {
              final isCurrent = status == reservation.status;
              return SizedBox(
                width: 50,
                child: Text(
                  _getShortStatusName(l10n, status),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? _getStatusColor(status)
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withValues(alpha: 0.1),
            AppTheme.primary2.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.info,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.info.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: reservation.workerPhotoUrl != null &&
                      reservation.workerPhotoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: reservation.workerPhotoUrl!,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.textPrimary,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          reservation.workerName?.isNotEmpty == true
                              ? reservation.workerName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        reservation.workerName?.isNotEmpty == true
                            ? reservation.workerName![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reservation_yourWorker,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reservation.workerName ??
                            l10n.reservation_workerAssigned,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (reservation.workerIsVerified == true) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified, color: AppTheme.info, size: 18),
                    ],
                  ],
                ),
                if (reservation.workerIsVerified == true) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.info, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        l10n.worker_verified,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (reservation.rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < (reservation.rating ?? 0).round()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.warning,
                          size: 16,
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Bouton Chat
          IconButton(
            onPressed: () => _openChat(context, reservation),
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.info, AppTheme.primary2],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_rounded,
                  color: AppTheme.textPrimary, size: 20),
            ),
          ),
          if (reservation.workerPhone != null) ...[
            IconButton(
              onPressed: () => _callWorker(reservation),
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone, color: AppTheme.textPrimary, size: 20),
              ),
            ),
          ],
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
            icon: Icons.phone,
            label: l10n.common_call,
            color: AppTheme.success,
            onTap: () => _callWorker(reservation),
          ),
        ),
        const SizedBox(width: 8),
        // Chat in-app avec gradient
        Expanded(
          child: _buildChatButton(context, reservation),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.map,
            label: l10n.reservation_map,
            color: AppTheme.primary2,
            onTap: () => _openMap(reservation),
          ),
        ),
      ],
    );
  }

  Widget _buildChatButton(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _openChat(context, reservation);
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.info, AppTheme.primary2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.info.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_rounded,
                    color: AppTheme.textPrimary, size: 24),
                const SizedBox(height: 6),
                Text(
                  l10n.reservation_chat,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            style: TextStyle(color: AppTheme.textPrimary),
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
              Icon(Icons.info_outline, color: AppTheme.textPrimary),
              const SizedBox(width: 12),
              Text(
                l10n.reservation_noWorkerYet,
                style: TextStyle(color: AppTheme.textPrimary),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.textPrimary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.info),
              const SizedBox(width: 8),
              Text(
                l10n.reservation_info,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: AppTheme.border),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.ac_unit, color: AppTheme.info),
              const SizedBox(width: 8),
              Text(
                l10n.reservation_servicesRequested,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: AppTheme.border),
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
            Divider(height: 24, color: AppTheme.border),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.infoLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.height, color: AppTheme.info, size: 20),
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
            color:
                isIncluded ? AppTheme.successLight : AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isIncluded ? AppTheme.success : AppTheme.textTertiary,
            size: 20,
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.photo_camera, color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.reservation_photos,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: AppTheme.border),

          // After Photo (primary - result)
          if (reservation.afterPhotoUrl != null) ...[
            Text(
              l10n.reservation_afterPhoto,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.success,
              ),
            ),
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
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            iconTheme: IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              title,
              style: TextStyle(color: AppTheme.textPrimary),
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
                errorWidget: (context, url, error) => Icon(
                  Icons.error,
                  color: AppTheme.textPrimary,
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
        gradient: LinearGradient(
          colors: [
            AppTheme.info,
            AppTheme.info.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.info.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reservation_totalPrice,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reservation.totalPrice.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              if (reservation.tip != null && reservation.tip! > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: AppTheme.warning, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n.reservation_tipAmount(
                            reservation.tip!.toStringAsFixed(2)),
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (reservation.isPriority)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warning,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: AppTheme.background, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.reservation_urgent,
                    style: TextStyle(
                      color: AppTheme.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
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
        color: AppTheme.warning,
        borderRadius: BorderRadius.circular(16),
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
                            Icon(Icons.error, color: AppTheme.textPrimary),
                            const SizedBox(width: 12),
                            Text(
                              l10n.resDetail_errorPrefix(failure.message),
                              style: TextStyle(color: AppTheme.textPrimary),
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
                                      color: AppTheme.textPrimary),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.resDetail_ratingSuccessTipError(
                                        failure.message),
                                    style:
                                        TextStyle(color: AppTheme.textPrimary),
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
                                      color: AppTheme.textPrimary),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.resDetail_tipSent(
                                        tip.toStringAsFixed(0)),
                                    style:
                                        TextStyle(color: AppTheme.textPrimary),
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
                                  color: AppTheme.textPrimary),
                              const SizedBox(width: 12),
                              Text(
                                l10n.resDetail_ratingSuccess,
                                style: TextStyle(color: AppTheme.textPrimary),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star, color: AppTheme.background, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reservation_rateService,
                        style: TextStyle(
                          color: AppTheme.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.reservation_rateSubtitle,
                        style: TextStyle(
                          color: AppTheme.background.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: AppTheme.background, size: 18),
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
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.textSecondary),
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
        icon: const Icon(Icons.edit),
        label: Text(l10n.reservation_edit),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.info,
          foregroundColor: AppTheme.textPrimary,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelDialog(context, reservation),
        icon: const Icon(Icons.cancel),
        label: Text(l10n.reservation_cancelReservation),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              foregroundColor: AppTheme.textPrimary,
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
              style: TextStyle(color: AppTheme.textPrimary),
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
        return AppTheme.warning;
      case ReservationStatus.assigned:
        return AppTheme.info;
      case ReservationStatus.enRoute:
        return AppTheme.primary2;
      case ReservationStatus.inProgress:
        return AppTheme.primary2;
      case ReservationStatus.completed:
        return AppTheme.success;
      case ReservationStatus.cancelled:
        return AppTheme.textTertiary;
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
                      Icon(Icons.check_circle, color: AppTheme.textPrimary),
                      const SizedBox(width: 12),
                      Text(
                        l10n.reservation_noShowReported,
                        style: TextStyle(color: AppTheme.textPrimary),
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
          side: BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
