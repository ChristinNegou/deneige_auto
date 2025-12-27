import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/worker_job.dart';
import '../bloc/worker_jobs_bloc.dart';

class WorkerJobDetailsPage extends StatelessWidget {
  final WorkerJob job;

  const WorkerJobDetailsPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du job'),
        backgroundColor: Colors.orange[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card
            _buildCard(
              title: 'Client',
              icon: Icons.person,
              children: [
                _buildInfoRow('Nom', job.client.fullName),
                if (job.client.phoneNumber != null) ...[
                  _buildInfoRow('Téléphone', job.client.phoneNumber!),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callClient(),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Appeler'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _messageClient(),
                          icon: const Icon(Icons.message, size: 18),
                          label: const Text('SMS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Location Card
            _buildCard(
              title: 'Adresse',
              icon: Icons.location_on,
              children: [
                Text(
                  job.displayAddress,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      job.distanceKm != null ? '${job.distanceKm!.toStringAsFixed(1)} km' : 'N/A',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (job.location != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openMaps(job.location!.latitude, job.location!.longitude),
                          icon: const Icon(Icons.map),
                          label: const Text('Google Maps'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openWaze(job.location!.latitude, job.location!.longitude),
                          icon: const Icon(Icons.navigation),
                          label: const Text('Waze'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Vehicle Card
            _buildCard(
              title: 'Véhicule',
              icon: Icons.directions_car,
              children: [
                _buildInfoRow('Véhicule', job.vehicle.displayName),
                if (job.vehicle.color != null)
                  _buildInfoRow('Couleur', job.vehicle.color!),
                if (job.vehicle.licensePlate != null)
                  _buildInfoRow('Plaque', job.vehicle.licensePlate!),
              ],
            ),
            const SizedBox(height: 16),

            // Service Card
            _buildCard(
              title: 'Service demandé',
              icon: Icons.ac_unit,
              children: [
                _buildInfoRow('Type', 'Déneigement'),
                if (job.serviceOptions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Options:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  ...job.serviceOptions.map((option) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green[600], size: 16),
                        const SizedBox(width: 8),
                        Text(_getOptionLabel(option)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Pricing Card
            _buildCard(
              title: 'Tarification',
              icon: Icons.attach_money,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prix total'),
                    Text(
                      '${job.totalPrice.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                if (job.tipAmount != null && job.tipAmount! > 0) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pourboire'),
                      Text(
                        '+ ${job.tipAmount!.toStringAsFixed(2)} \$',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            if (job.clientNotes != null && job.clientNotes!.isNotEmpty)
              _buildCard(
                title: 'Notes du client',
                icon: Icons.note,
                children: [
                  Text(job.clientNotes!),
                ],
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: job.status == JobStatus.pending
          ? _buildAcceptButton(context)
          : null,
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return BlocConsumer<WorkerJobsBloc, WorkerJobsState>(
      listener: (context, state) {
        debugPrint('🔔 WorkerJobDetailsPage state: $state');
        if (state is JobActionSuccess && state.action == 'accept') {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Job accepté avec succès!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate job was accepted
        } else if (state is WorkerJobsError) {
          HapticFeedback.vibrate();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is JobActionLoading && state.jobId == job.id;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        debugPrint('🔔 Accepting job: ${job.id}');
                        context.read<WorkerJobsBloc>().add(AcceptJob(job.id));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isLoading ? 0 : 4,
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Acceptation en cours...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Accepter ce job',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getOptionLabel(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return 'Grattage vitres';
      case ServiceOption.doorDeicing:
        return 'Déglaçage portes';
      case ServiceOption.wheelClearance:
        return 'Dégagement roues';
    }
  }

  Future<void> _callClient() async {
    if (job.client.phoneNumber != null) {
      final uri = Uri.parse('tel:${job.client.phoneNumber}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _messageClient() async {
    if (job.client.phoneNumber != null) {
      final uri = Uri.parse('sms:${job.client.phoneNumber}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    // DEBUG: Détecter les coordonnées de l'émulateur (Mountain View) et utiliser Trois-Rivières
    double finalLat = lat;
    double finalLng = lng;

    final isEmulatorLocation = (lat - 37.4219983).abs() < 0.5 &&
        (lng - (-122.084)).abs() < 0.5;

    if (isEmulatorLocation) {
      finalLat = 46.3432;
      finalLng = -72.5476;
    }

    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$finalLat,$finalLng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWaze(double lat, double lng) async {
    // DEBUG: Détecter les coordonnées de l'émulateur (Mountain View) et utiliser Trois-Rivières
    double finalLat = lat;
    double finalLng = lng;

    final isEmulatorLocation = (lat - 37.4219983).abs() < 0.5 &&
        (lng - (-122.084)).abs() < 0.5;

    if (isEmulatorLocation) {
      finalLat = 46.3432;
      finalLng = -72.5476;
    }

    final uri = Uri.parse('https://waze.com/ul?ll=$finalLat,$finalLng&navigate=yes');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
