import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/bloc/reservation_list_bloc.dart';
import '../../../reservation/domain/usecases/get_reservations_usecase.dart';
import '../../../reservation/domain/usecases/get_reservation_by_id_usecase.dart';
import '../../../reservation/domain/usecases/cancel_reservation_usecase.dart';
import '../../../../core/di/injection_container.dart';
import '../../../vehicule/presentation/widgets/vehicle_visuals.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.activities_title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.activities_inProgress),
            Tab(text: l10n.activities_completed),
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
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(160, 44),
                    ),
                    onPressed: () {
                      context
                          .read<ReservationListBloc>()
                          .add(const LoadAllReservations());
                    },
                    child: Text(l10n.common_retry),
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
            AppIllustration(
              type: IllustrationType.emptyActivities,
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              isCompleted
                  ? AppLocalizations.of(context)!.activities_emptyCompleted
                  : AppLocalizations.of(context)!.activities_emptyInProgress,
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              isCompleted
                  ? AppLocalizations.of(context)!
                      .activities_emptyCompletedSubtitle
                  : AppLocalizations.of(context)!
                      .activities_emptyInProgressSubtitle,
              style: AppTheme.bodySmall,
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return _buildActivityCard(reservation);
        },
      ),
    );
  }

  Widget _buildActivityCard(Reservation reservation) {
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en_CA'
        : 'fr_CA';
    final when =
        DateFormat('d MMM, HH:mm', locale).format(reservation.departureTime);
    final statusColor = _getStatusColor(reservation.status);
    final isRated = reservation.status == ReservationStatus.completed &&
        reservation.rating != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.activityDetails,
            arguments: reservation.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut et moment
            Row(
              children: [
                StatusBadge(
                  label: reservation.status.displayName,
                  color: statusColor,
                  small: true,
                ),
                const Spacer(),
                Text(when, style: AppTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),

            // Vehicule
            Row(
              children: [
                Icon(
                  vehicleTypeIcon(reservation.vehicle.type),
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '${reservation.vehicle.make} ${reservation.vehicle.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headlineSmall,
                  ),
                ),
                if (reservation.vehicle.licensePlate != null) ...[
                  const SizedBox(width: 10),
                  LicensePlate(plate: reservation.vehicle.licensePlate!),
                ],
              ],
            ),
            const Divider(height: 24),

            // Deneigeur, note et prix
            Row(
              children: [
                if (reservation.workerName != null) ...[
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      reservation.workerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
                if (isRated) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.star_rounded,
                      size: 16, color: AppTheme.warning),
                  const SizedBox(width: 2),
                  Text(
                    reservation.rating!.toStringAsFixed(1),
                    style: AppTheme.labelMedium
                        .copyWith(color: AppTheme.textPrimary),
                  ),
                ],
                const Spacer(),
                Text(
                  '${reservation.totalPrice.toStringAsFixed(2)} \$',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
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
