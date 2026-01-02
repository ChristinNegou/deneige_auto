
import 'package:deneige_auto/features/reservation/domain/entities/reservation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../reservation/presentation/bloc/reservation_list_bloc.dart';


class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReservationListBloc>()..add(const LoadReservations()),
      child: const ReservationsView(),
    );
  }
}

class ReservationsView extends StatelessWidget {
  const ReservationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            }
          },
        ),
        title: const Text('Mes réservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.reservations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune réservation',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez par créer votre première réservation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReservationListBloc>().add(RefreshReservations());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.reservations.length,
              itemBuilder: (context, index) {
                final reservation = state.reservations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(reservation.status).withOpacity(0.2),
                      child: Text(
                        reservation.status.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(reservation.vehicle.displayName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Place ${reservation.parkingSpot.displayName}'),
                        Text(
                          DateFormat('d MMM yyyy, HH:mm').format(reservation.departureTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reservation.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reservation.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(reservation.status),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reservation.totalPrice.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.reservationDetails,
                        arguments: reservation.id,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.newReservation),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle'),
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.assigned:
        return Colors.blue;
      case ReservationStatus.enRoute:
        return Colors.indigo;
      case ReservationStatus.inProgress:
        return Colors.purple;
      case ReservationStatus.completed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.grey;
      case ReservationStatus.late:
        return Colors.red;
    }
  }
}