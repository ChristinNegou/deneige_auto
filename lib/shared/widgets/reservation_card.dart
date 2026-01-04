// ============= reservation_card.dart =============
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../features/reservation/domain/entities/reservation.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onTap;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(reservation.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reservation.status.icon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(reservation.status),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Vehicle info
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
                      reservation.vehicle.displayWithColor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Parking spot
              Row(
                children: [
                  Icon(
                    Icons.local_parking,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Place ${reservation.parkingSpot.displayName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Departure time
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Départ: ${DateFormat('d MMM yyyy, HH:mm', 'fr_CA').format(reservation.departureTime)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      default:
        return Colors.grey;
    }
  }
}
