import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../reservation/domain/entities/reservation.dart';

class UpcomingReservationsList extends StatelessWidget {
  final List<Reservation> reservations;
  final Function(Reservation) onReservationTap;

  const UpcomingReservationsList({
    super.key,
    required this.reservations,
    required this.onReservationTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reservations.length > 3 ? 3 : reservations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return _buildReservationCard(context, reservation);
      },
    );
  }

  Widget _buildReservationCard(BuildContext context, Reservation reservation) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: InkWell(
        onTap: () => onReservationTap(reservation),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(reservation.status),
                  Text(
                    dateFormat.format(reservation.departureTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Départ à ${timeFormat.format(reservation.departureTime)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${reservation.vehicle.make} ${reservation.vehicle.model}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.local_parking,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Place ${reservation.parkingSpot.spotNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReservationStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case ReservationStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        label = 'En attente';
        break;
      case ReservationStatus.assigned:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'Assignée';
        break;
      case ReservationStatus.inProgress:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'En cours';
        break;
      case ReservationStatus.completed:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = 'Terminée';
        break;
      case ReservationStatus.cancelled:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'Annulée';
        break;
      case ReservationStatus.late:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'En retard';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}