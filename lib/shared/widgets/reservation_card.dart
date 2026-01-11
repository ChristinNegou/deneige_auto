// ============= reservation_card.dart =============
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
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
      color: AppTheme.surface,
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
                      color: _getStatusColor(reservation.status)
                          .withValues(alpha: 0.2),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
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
                    color: AppTheme.textSecondary,
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
                    color: AppTheme.textSecondary,
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
                    color: AppTheme.textSecondary,
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
        return AppTheme.warning;
      case ReservationStatus.assigned:
        return AppTheme.statusAssigned;
      case ReservationStatus.inProgress:
        return AppTheme.primary2;
      case ReservationStatus.completed:
        return AppTheme.success;
      case ReservationStatus.cancelled:
        return AppTheme.textTertiary;
      case ReservationStatus.late:
        return AppTheme.error;
      default:
        return AppTheme.textTertiary;
    }
  }
}
