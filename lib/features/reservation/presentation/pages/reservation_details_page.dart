import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/reservation.dart';
import '../bloc/reservation_list_bloc.dart';


class ReservationDetailsPage extends StatelessWidget {
  final String reservationId;

  const ReservationDetailsPage({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReservationListBloc>()..add(const LoadReservations()),
      child: ReservationDetailsView(reservationId: reservationId),
    );
  }
}

class ReservationDetailsView extends StatelessWidget {
  final String reservationId;

  const ReservationDetailsView({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationListBloc, ReservationListState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détails de la réservation')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final reservation = _findReservation(state.reservations);

        if (reservation == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détails de la réservation')),
            body: const Center(
              child: Text('Réservation introuvable'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Détails de la réservation')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard(context, reservation),
              const SizedBox(height: 16),
              _buildDetailsCard(context, reservation),
              const SizedBox(height: 16),
              _buildServiceOptionsCard(context, reservation),
              const SizedBox(height: 16),
              _buildPriceCard(context, reservation),
              const SizedBox(height: 24),
              if (reservation.canBeEdited)
                _buildEditButton(context, reservation),
              if (reservation.canBeEdited && reservation.canBeCancelled)
                const SizedBox(height: 12),
              if (reservation.canBeCancelled)
                _buildCancelButton(context, reservation),
            ],
          ),
        );
      },
    );
  }

  Reservation? _findReservation(List<Reservation> reservations) {
    try {
      return reservations.firstWhere((r) => r.id == reservationId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildStatusCard(BuildContext context, Reservation reservation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(reservation.status).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  reservation.status.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statut',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reservation.status.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(reservation.status),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Reservation reservation) {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              Icons.directions_car,
              'Véhicule',
              '${reservation.vehicle.displayName} (${reservation.vehicle.color})',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.local_parking,
              'Place de parking',
              reservation.parkingSpot.displayName,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.access_time,
              'Heure de départ',
              dateFormat.format(reservation.departureTime),
            ),
            if (reservation.deadlineTime != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.alarm,
                'Deadline',
                dateFormat.format(reservation.deadlineTime!),
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today,
              'Créée le',
              dateFormat.format(reservation.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOptionsCard(BuildContext context, Reservation reservation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options de service',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            if (reservation.serviceOptions.isEmpty)
              const Text('Aucune option supplémentaire')
            else
              ...reservation.serviceOptions.map((option) {
                String optionText;
                switch (option) {
                  case ServiceOption.windowScraping:
                    optionText = 'Grattage des vitres (+5\$)';
                    break;
                  case ServiceOption.doorDeicing:
                    optionText = 'Déglaçage des portes (+3\$)';
                    break;
                  case ServiceOption.wheelClearance:
                    optionText = 'Dégagement des roues (+4\$)';
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(optionText),
                    ],
                  ),
                );
              }).toList(),
            if (reservation.snowDepthCm != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.ac_unit, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text('Profondeur de neige: ${reservation.snowDepthCm} cm'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, Reservation reservation) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reservation.totalPrice.toStringAsFixed(2)} \$',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            if (reservation.isPriority)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Urgent',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, Reservation reservation) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.editReservation,
            arguments: reservation,
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Modifier la réservation'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, Reservation reservation) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showCancelDialog(context, reservation),
        icon: const Icon(Icons.cancel),
        label: const Text('Annuler la réservation'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette réservation? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ReservationListBloc>().add(
                    CancelReservationEvent(reservation.id),
                  );
              Navigator.pop(context); // Retour à la liste
            },
            child: const Text(
              'Oui, annuler',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.assigned:
        return Colors.blue;
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
