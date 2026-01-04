import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/bloc/reservation_list_bloc.dart';
import '../../../reservation/domain/usecases/get_reservations_usecase.dart';
import '../../../reservation/domain/usecases/get_reservation_by_id_usecase.dart';
import '../../../reservation/domain/usecases/cancel_reservation_usecase.dart';
import '../../../../core/di/injection_container.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReservationListBloc(
        getReservations: sl<GetReservationsUseCase>(),
        getReservationById: sl<GetReservationByIdUseCase>(),
        cancelReservation: sl<CancelReservationUseCase>(),
      )..add(const LoadAllReservations()),
      child: const _ActivitiesScreenContent(),
    );
  }
}

class _ActivitiesScreenContent extends StatefulWidget {
  const _ActivitiesScreenContent();

  @override
  State<_ActivitiesScreenContent> createState() =>
      _ActivitiesScreenContentState();
}

class _ActivitiesScreenContentState extends State<_ActivitiesScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Activités'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
          ],
        ),
      ),
      body: BlocBuilder<ReservationListBloc, ReservationListState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ReservationListBloc>()
                          .add(const LoadAllReservations());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Filtrer les réservations en cours
          final inProgressReservations = state.reservations
              .where((r) =>
                  r.status == ReservationStatus.enRoute ||
                  r.status == ReservationStatus.inProgress ||
                  r.status == ReservationStatus.assigned)
              .toList();

          // Filtrer les réservations terminées
          final completedReservations = state.reservations
              .where((r) => r.status == ReservationStatus.completed)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActivityList(inProgressReservations, isCompleted: false),
              _buildActivityList(completedReservations, isCompleted: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityList(List<Reservation> reservations,
      {required bool isCompleted}) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_outline : Icons.hourglass_empty,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted
                  ? 'Aucune activité terminée'
                  : 'Aucune activité en cours',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted
                  ? 'Vos déneigements terminés apparaîtront ici'
                  : 'Vos déneigements en cours apparaîtront ici',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReservationListBloc>().add(const LoadAllReservations());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return _buildActivityCard(reservation);
        },
      ),
    );
  }

  Widget _buildActivityCard(Reservation reservation) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.activityDetails,
          arguments: reservation.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildStatusIcon(reservation.status),
                      const SizedBox(width: 8),
                      Text(
                        reservation.status.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(reservation.status),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Informations du véhicule
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reservation.vehicle.make} ${reservation.vehicle.model}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (reservation.vehicle.licensePlate != null)
                          Text(
                            reservation.vehicle.licensePlate!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date et heure
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(reservation.departureTime),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(reservation.departureTime),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              // Déneigeur assigné (si disponible)
              if (reservation.workerName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reservation.workerName!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              // Prix
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} \$',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),

              // Rating si terminé
              if (reservation.status == ReservationStatus.completed &&
                  reservation.rating != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < reservation.rating!.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 18,
                        color: Colors.amber,
                      );
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ReservationStatus status) {
    IconData icon;
    Color color = _getStatusColor(status);

    switch (status) {
      case ReservationStatus.assigned:
        icon = Icons.person_add;
        break;
      case ReservationStatus.enRoute:
        icon = Icons.directions_car;
        break;
      case ReservationStatus.inProgress:
        icon = Icons.build;
        break;
      case ReservationStatus.completed:
        icon = Icons.check_circle;
        break;
      default:
        icon = Icons.hourglass_empty;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.assigned:
        return AppTheme.statusAssigned;
      case ReservationStatus.enRoute:
        return AppTheme.statusEnRoute;
      case ReservationStatus.inProgress:
        return AppTheme.statusInProgress;
      case ReservationStatus.completed:
        return AppTheme.statusCompleted;
      default:
        return AppTheme.textSecondary;
    }
  }
}
