import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/worker_job.dart';

class JobCard extends StatelessWidget {
  final WorkerJob job;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final bool showAcceptButton;
  final bool isLoading;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onAccept,
    this.showAcceptButton = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd MMM', 'fr_CA');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: job.isPriority
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority badge and price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (job.isPriority) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildStatusChip(job.status),
                    ],
                  ),
                  Text(
                    '${job.totalPrice.toStringAsFixed(2)} \$',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.displayAddress,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Distance and time
              Row(
                children: [
                  if (job.distanceKm != null) ...[
                    Icon(Icons.near_me, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${job.distanceKm!.toStringAsFixed(1)} km',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.schedule, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormatter.format(job.departureTime)} à ${timeFormatter.format(job.departureTime)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Vehicle info
              Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    job.vehicle.displayName,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (job.vehicle.color != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        job.vehicle.color!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),

              // Service options
              if (job.serviceOptions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: job.serviceOptions.map((option) {
                    return Chip(
                      label: Text(
                        _getServiceOptionLabel(option),
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              // Accept button
              if (showAcceptButton && job.status == JobStatus.pending) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onAccept,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(isLoading ? 'Acceptation...' : 'Accepter ce job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case JobStatus.pending:
        color = Colors.blue;
        label = 'Disponible';
        icon = Icons.pending;
        break;
      case JobStatus.assigned:
        color = Colors.orange;
        label = 'Assigné';
        icon = Icons.assignment_ind;
        break;
      case JobStatus.enRoute:
        color = Colors.amber;
        label = 'En route';
        icon = Icons.directions_car;
        break;
      case JobStatus.inProgress:
        color = Colors.purple;
        label = 'En cours';
        icon = Icons.engineering;
        break;
      case JobStatus.completed:
        color = Colors.green;
        label = 'Terminé';
        icon = Icons.check_circle;
        break;
      case JobStatus.cancelled:
        color = Colors.red;
        label = 'Annulé';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceOptionLabel(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return 'Grattage vitres';
      case ServiceOption.doorDeicing:
        return 'Déglaçage portes';
      case ServiceOption.wheelClearance:
        return 'Dégagement roues';
    }
  }
}
