import 'package:deneige_auto/features/reservation/domain/entities/reservation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reservation/presentation/bloc/reservation_list_bloc.dart';

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ReservationListBloc>()..add(const LoadReservations()),
      child: const ReservationsView(),
    );
  }
}

class ReservationsView extends StatelessWidget {
  const ReservationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            }
          },
        ),
        title: Text(l10n.reservation_myReservations),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<ReservationListBloc>().add(RefreshReservations());
            },
          ),
        ],
      ),
      body: BlocConsumer<ReservationListBloc, ReservationListState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.reservations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.reservations.isEmpty) {
            return EmptyStateWidget(
              illustrationType: IllustrationType.emptyReservations,
              title: l10n.reservation_empty,
              subtitle: l10n.reservation_emptySubtitle,
              buttonText: l10n.reservation_new,
              onButtonPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.newReservation),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReservationListBloc>().add(RefreshReservations());
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: state.reservations.length,
              itemBuilder: (context, index) {
                final reservation = state.reservations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReservationTile(
                    reservation: reservation,
                    statusColor: _getStatusColor(reservation.status),
                    parkingLabel: l10n.reservation_parkingSpot(
                        reservation.parkingSpot.displayName),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.newReservation),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.reservation_newShort),
      ),
    );
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
}

/// Ligne de reservation : bloc date, vehicule, heure et place, statut et prix.
class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final Color statusColor;
  final String parkingLabel;

  const _ReservationTile({
    required this.reservation,
    required this.statusColor,
    required this.parkingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en_CA'
        : 'fr_CA';
    final date = reservation.departureTime;

    return GlassCard(
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
                  DateFormat('MMM', locale).format(date).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentDark,
                  ),
                ),
                Text(
                  '${date.day}',
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
                  reservation.vehicle.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('HH:mm', locale).format(date)}  ·  $parkingLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                StatusBadge(
                  label: reservation.status.displayName,
                  color: statusColor,
                  small: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
    );
  }
}
