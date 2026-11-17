import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../home/presentation/bloc/home_bloc.dart';
import '../../home/presentation/bloc/home_event.dart';
import '../../home/presentation/bloc/home_state.dart';
import '../../notifications/presentation/bloc/notification_bloc.dart';
import '../../reservation/domain/entities/reservation.dart';
import '../../reservation/domain/repositories/reservation_repository.dart';
import '../../reservation/presentation/bloc/reservation_list_bloc.dart'
    as reservation_bloc;
import '../../widgets/service_completed_dialog.dart';
import '../../chat/presentation/bloc/chat_bloc.dart';
import '../../chat/presentation/pages/chat_screen.dart';
import '../../ai_chat/presentation/widgets/draggable_ai_chat_fab.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  Timer? _refreshTimer;
  final Set<String> _ratedReservations = {};

  static const Duration _refreshInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(LoadHomeData());
        context
            .read<reservation_bloc.ReservationListBloc>()
            .add(const reservation_bloc.LoadReservations());
        context.read<NotificationBloc>().add(LoadNotifications());
      }
    });
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        context
            .read<reservation_bloc.ReservationListBloc>()
            .add(reservation_bloc.RefreshReservations());
        context.read<NotificationBloc>().add(RefreshNotifications());
      }
    });
  }

  void _checkForCompletedReservations(List<Reservation> reservations) {
    for (final reservation in reservations) {
      if (reservation.status == ReservationStatus.completed &&
          !_ratedReservations.contains(reservation.id) &&
          reservation.rating == null) {
        _ratedReservations.add(reservation.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            HapticFeedback.heavyImpact();
            ServiceCompletedDialog.show(
              context,
              reservation: reservation,
              onSubmitRating: (rating, tip, comment) async {
                // Soumettre la note au backend
                await _submitRating(reservation.id, rating, comment);

                // Soumettre le pourboire si présent
                if (tip != null && tip > 0) {
                  await _submitTip(reservation.id, tip);
                }
              },
              onViewDetails: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.reservationDetails,
                  arguments: reservation.id,
                );
              },
            );
          }
        });
        break;
      }
    }
  }

  Future<void> _submitRating(
      String reservationId, int rating, String? comment) async {
    try {
      final repository = sl<ReservationRepository>();
      final result = await repository.rateReservation(
        reservationId: reservationId,
        rating: rating,
        review: comment,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .clientHome_errorPrefix(failure.message)),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        (data) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ??
                    AppLocalizations.of(context)!.clientHome_ratingThanks),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Rafraîchir les réservations
            context
                .read<reservation_bloc.ReservationListBloc>()
                .add(reservation_bloc.RefreshReservations());
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientHome_ratingError),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitTip(String reservationId, double amount) async {
    try {
      final repository = sl<ReservationRepository>();
      final result = await repository.addTip(
        reservationId: reservationId,
        amount: amount,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .clientHome_tipErrorPrefix(failure.message)),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        (data) {
          if (mounted) {
            final workerName = data['workerName'] ??
                AppLocalizations.of(context)!.clientHome_theWorker;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .clientHome_tipSent(amount.toStringAsFixed(0), workerName)),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientHome_tipError),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: AIChatFabWrapper(
          screenId: 'client_dashboard',
          child: SafeArea(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return BlocListener<reservation_bloc.ReservationListBloc,
                      reservation_bloc.ReservationListState>(
                    listener: (context, state) {
                      _checkForCompletedReservations(state.reservations);
                    },
                    child: CustomScrollView(
                      slivers: [
                        // Header compact
                        SliverToBoxAdapter(
                          child: _buildHeader(context, state.user.name),
                        ),
                        // Contenu principal
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // Live tracking (si actif)
                              _buildLiveTrackingSection(),
                              // Panneau meteo + reservation
                              _buildHeroCard(context),
                              const SizedBox(height: 28),
                              // Raccourcis
                              _buildQuickActions(context),
                              const SizedBox(height: 28),
                              // Prochaines réservations
                              _buildUpcomingSection(context),
                              const SizedBox(height: 80),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.clientHome_greetingLabel,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  userName.split(' ').first,
                  style: AppTheme.headlineLarge,
                ),
              ],
            ),
          ),
          _buildNotificationButton(context),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Panneau principal : la meteo du moment et l'action de reservation.
  /// C'est l'element signature de l'accueil, le seul en bleu nuit.
  Widget _buildHeroCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final weather = state.isLoading ? null : state.weather;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: AppTheme.shadowLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (weather != null) ...[
                Row(
                  children: [
                    Icon(
                      _getWeatherIcon(weather.condition),
                      size: 20,
                      color: AppTheme.primary3,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${weather.temperature.round()}°C',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        weather.snowDepth != null && weather.snowDepth! > 0
                            ? l10n.weather_snowDepthValue(
                                weather.snowDepth.toString())
                            : weather.condition,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.clientHome_heroTitle,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppTheme.onPrimary,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.newReservation),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(l10n.clientHome_heroCta),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('snow') || lower.contains('neige')) {
      return Icons.ac_unit;
    } else if (lower.contains('rain') || lower.contains('pluie')) {
      return Icons.water_drop;
    } else if (lower.contains('cloud') || lower.contains('nuag')) {
      return Icons.cloud;
    } else if (lower.contains('sun') ||
        lower.contains('clear') ||
        lower.contains('soleil')) {
      return Icons.wb_sunny;
    }
    return Icons.wb_cloudy;
  }

  Widget _buildNotificationButton(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
                if (state.unreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveTrackingSection() {
    return BlocBuilder<reservation_bloc.ReservationListBloc,
        reservation_bloc.ReservationListState>(
      builder: (context, state) {
        final activeReservation = state.reservations
            .where((r) =>
                r.status == ReservationStatus.enRoute ||
                r.status == ReservationStatus.inProgress ||
                r.status == ReservationStatus.assigned)
            .firstOrNull;

        if (activeReservation == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCompactTrackingCard(activeReservation),
        );
      },
    );
  }

  Widget _buildCompactTrackingCard(Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(reservation.status);
    final statusText = _getStatusLabel(reservation.status);
    final IconData statusIcon;
    switch (reservation.status) {
      case ReservationStatus.inProgress:
        statusIcon = Icons.ac_unit_rounded;
        break;
      case ReservationStatus.enRoute:
        statusIcon = Icons.directions_car_rounded;
        break;
      default:
        statusIcon = Icons.person_rounded;
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.reservationDetails,
        arguments: reservation.id,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(label: statusText, color: statusColor, small: true),
                const SizedBox(height: 6),
                Text(
                  reservation.workerName ?? l10n.clientHome_workerApproaching,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
          ),
          if (reservation.workerId != null)
            IconButton.filledTonal(
              onPressed: () => _openChatFromCard(reservation),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainer,
                foregroundColor: AppTheme.textPrimary,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.clientHome_shortcuts, style: AppTheme.headlineMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.event_note_rounded,
                label: l10n.clientHome_myAppointments,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.reservations),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                icon: Icons.directions_car_filled_outlined,
                label: l10n.vehicle_myVehicles,
                onTap: () => Navigator.pushNamed(context, AppRoutes.vehicles),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                icon: Icons.credit_card_rounded,
                label: l10n.profile_payments,
                onTap: () => Navigator.pushNamed(context, AppRoutes.payments),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM + 2),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.clientHome_upcomingReservations,
              style: AppTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.reservations),
              child: Text(l10n.clientHome_viewAll),
            ),
          ],
        ),
        const SizedBox(height: 4),
        BlocBuilder<reservation_bloc.ReservationListBloc,
            reservation_bloc.ReservationListState>(
          builder: (context, state) {
            final upcoming =
                state.reservations.where((r) => r.isUpcoming).take(3).toList();

            if (upcoming.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: upcoming.map((r) => _buildReservationCard(r)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 32,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.reservation_empty,
            textAlign: TextAlign.center,
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.clientHome_bookFirstSnowRemoval,
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.reservationDetails,
          arguments: reservation.id,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Column(
                children: [
                  Text(
                    _formatMonth(reservation.departureTime),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentDark,
                    ),
                  ),
                  Text(
                    _formatDay(reservation.departureTime),
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${reservation.vehicle.make} ${reservation.vehicle.model}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(reservation.departureTime),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: _getStatusLabel(reservation.status),
              color: _getStatusColor(reservation.status),
              small: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDay(DateTime date) => date.day.toString();

  String _formatMonth(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.month_jan,
      l10n.month_feb,
      l10n.month_mar,
      l10n.month_apr,
      l10n.month_may,
      l10n.month_jun,
      l10n.month_jul,
      l10n.month_aug,
      l10n.month_sep,
      l10n.month_oct,
      l10n.month_nov,
      l10n.month_dec
    ];
    return months[date.month - 1];
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusLabel(ReservationStatus status) {
    final l10n = AppLocalizations.of(context)!;
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
      default:
        return l10n.clientHome_unknown;
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
      default:
        return AppTheme.textTertiary;
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  Icons.home_filled,
                  AppLocalizations.of(context)!.clientHome_navHome,
                  true,
                  () {}),
              _buildNavItem(
                Icons.event_note_outlined,
                AppLocalizations.of(context)!.clientHome_myAppointments,
                false,
                () => Navigator.pushNamed(context, AppRoutes.reservations),
              ),
              // Bouton central
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.newReservation),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.glowPrimary,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppTheme.onPrimary, size: 28),
                ),
              ),
              _buildNavItem(
                Icons.history_outlined,
                AppLocalizations.of(context)!.clientHome_navActivities,
                false,
                () => Navigator.pushNamed(context, AppRoutes.activities),
              ),
              _buildNavItem(
                Icons.person_outline,
                AppLocalizations.of(context)!.clientHome_navProfile,
                false,
                () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.primary : AppTheme.textTertiary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppTheme.primary : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Ouvre le chat avec le déneigeur depuis la carte de suivi
  void _openChatFromCard(Reservation reservation) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.clientHome_userNotAuth),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
            otherUserName: reservation.workerName ??
                AppLocalizations.of(context)!.worker_badge,
            otherUserPhoto: null,
            currentUserId: authState.user.id,
          ),
        ),
      ),
    );
  }
}
