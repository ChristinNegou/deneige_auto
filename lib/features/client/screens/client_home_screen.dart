import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_theme.dart';
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
                content: Text('Erreur: ${failure.message}'),
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
                content:
                    Text(data['message'] ?? 'Merci pour votre évaluation!'),
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
            content: Text('Erreur lors de l\'envoi: $e'),
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
                content: Text('Erreur pourboire: ${failure.message}'),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        (data) {
          if (mounted) {
            final workerName = data['workerName'] ?? 'le déneigeur';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Pourboire de ${amount.toStringAsFixed(0)}\$ envoyé à $workerName'),
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
            content: Text('Erreur lors de l\'envoi du pourboire: $e'),
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
        body: SafeArea(
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
                        padding: const EdgeInsets.all(AppTheme.paddingLG),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Live tracking (si actif)
                            _buildLiveTrackingSection(),
                            // Actions rapides
                            _buildQuickActions(context),
                            const SizedBox(height: 24),
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
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          // Ligne principale
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Salutation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour,',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      userName.split(' ').first,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Météo badge
              _buildWeatherBadge(),
              const SizedBox(width: 8),
              // Notifications
              _buildNotificationButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherBadge() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (!state.isLoading && state.weather != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.shadowSM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getWeatherIcon(state.weather!.condition),
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${state.weather!.temperature.round()}°',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
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
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.shadowSM,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
                if (state.unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
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
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildCompactTrackingCard(activeReservation),
        );
      },
    );
  }

  Widget _buildCompactTrackingCard(Reservation reservation) {
    final isEnRoute = reservation.status == ReservationStatus.enRoute;
    final isInProgress = reservation.status == ReservationStatus.inProgress;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isInProgress) {
      statusColor = AppTheme.success;
      statusText = 'En cours';
      statusIcon = Icons.construction;
    } else if (isEnRoute) {
      statusColor = AppTheme.secondary;
      statusText = 'En route';
      statusIcon = Icons.directions_car;
    } else {
      statusColor = AppTheme.primary;
      statusText = 'Assigné';
      statusIcon = Icons.person;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.reservationDetails,
            arguments: reservation.id,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône avec animation
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reservation.workerName ?? 'Déneigeur en approche',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton Chat si déneigeur assigné
                if (reservation.workerId != null) ...[
                  GestureDetector(
                    onTap: () => _openChatFromCard(reservation),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Flèche
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: AppTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                label: 'Réserver',
                color: AppTheme.primary,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.newReservation),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_today_outlined,
                label: 'Mes RDV',
                color: AppTheme.success,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.reservations),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.credit_card_outlined,
                label: 'Paiements',
                color: AppTheme.secondary,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prochaines réservations',
              style: AppTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.reservations),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune réservation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Réservez votre premier déneigement',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.newReservation),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Réserver'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.reservationDetails,
            arguments: reservation.id,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Date
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatDay(reservation.departureTime),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        _formatMonth(reservation.departureTime),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reservation.vehicle.make} ${reservation.vehicle.model}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(reservation.departureTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Statut
                StatusBadge(
                  label: _getStatusLabel(reservation.status),
                  color: _getStatusColor(reservation.status),
                  small: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDay(DateTime date) => date.day.toString();

  String _formatMonth(DateTime date) {
    const months = [
      'JAN',
      'FÉV',
      'MAR',
      'AVR',
      'MAI',
      'JUN',
      'JUL',
      'AOÛ',
      'SEP',
      'OCT',
      'NOV',
      'DÉC'
    ];
    return months[date.month - 1];
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.assigned:
        return 'Assigné';
      case ReservationStatus.enRoute:
        return 'En route';
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminé';
      case ReservationStatus.cancelled:
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppTheme.warning;
      case ReservationStatus.assigned:
        return AppTheme.primary;
      case ReservationStatus.enRoute:
        return AppTheme.secondary;
      case ReservationStatus.inProgress:
        return AppTheme.success;
      case ReservationStatus.completed:
        return AppTheme.success;
      case ReservationStatus.cancelled:
        return AppTheme.textTertiary;
      default:
        return AppTheme.textTertiary;
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, 'Accueil', true, () {}),
              _buildNavItem(
                Icons.calendar_month_outlined,
                'Agenda',
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
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
              _buildNavItem(
                Icons.history_outlined,
                'Activités',
                false,
                () => Navigator.pushNamed(context, AppRoutes.activities),
              ),
              _buildNavItem(
                Icons.person_outline,
                'Profil',
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
          content: const Text('Erreur: utilisateur non authentifié'),
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
            otherUserName: reservation.workerName ?? 'Déneigeur',
            otherUserPhoto: null,
            currentUserId: authState.user.id,
          ),
        ),
      ),
    );
  }
}
