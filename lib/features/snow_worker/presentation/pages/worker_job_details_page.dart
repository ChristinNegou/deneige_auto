import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/worker_job.dart';
import '../bloc/worker_jobs_bloc.dart';

class WorkerJobDetailsPage extends StatelessWidget {
  final WorkerJob job;

  const WorkerJobDetailsPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.paddingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClientCard(),
                    const SizedBox(height: 16),
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildVehicleCard(),
                    const SizedBox(height: 16),
                    _buildServiceCard(),
                    const SizedBox(height: 16),
                    _buildPricingCard(),
                    if (job.clientNotes != null && job.clientNotes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildNotesCard(),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: job.status == JobStatus.pending
          ? _buildAcceptButton(context)
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.shadowSM,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Détails du job',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          StatusBadge(
            label: _getStatusLabel(job.status),
            color: _getStatusColor(job.status),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Client', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nom', job.client.fullName),
          if (job.client.phoneNumber != null) ...[
            _buildInfoRow('Téléphone', job.client.phoneNumber!),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContactButton(
                    icon: Icons.phone_rounded,
                    label: 'Appeler',
                    color: AppTheme.success,
                    onTap: _callClient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactButton(
                    icon: Icons.message_rounded,
                    label: 'SMS',
                    color: AppTheme.primary,
                    onTap: _messageClient,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppTheme.error, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Adresse', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          Text(job.displayAddress, style: AppTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.directions_rounded, size: 16, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text(
                job.distanceKm != null ? '${job.distanceKm!.toStringAsFixed(1)} km' : 'N/A',
                style: AppTheme.bodySmall,
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
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Google Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWaze(job.location!.latitude, job.location!.longitude),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Waze'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.info,
                      side: const BorderSide(color: AppTheme.info),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.directions_car_rounded, color: AppTheme.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Véhicule', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Véhicule', job.vehicle.displayName),
          if (job.vehicle.color != null)
            _buildInfoRow('Couleur', job.vehicle.color!),
          if (job.vehicle.licensePlate != null)
            _buildInfoRow('Plaque', job.vehicle.licensePlate!),
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.ac_unit_rounded, color: AppTheme.info, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Service', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Type', 'Déneigement'),
          if (job.serviceOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Options:', style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...job.serviceOptions.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
                  const SizedBox(width: 8),
                  Text(_getOptionLabel(option), style: AppTheme.bodyMedium),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.attach_money_rounded, color: AppTheme.success, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Tarification', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prix total', style: AppTheme.bodyMedium),
              Text(
                '${job.totalPrice.toStringAsFixed(2)} \$',
                style: AppTheme.headlineMedium.copyWith(color: AppTheme.success),
              ),
            ],
          ),
          if (job.tipAmount != null && job.tipAmount! > 0) ...[
            const Divider(height: 24, color: AppTheme.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pourboire', style: AppTheme.bodyMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '+ ${job.tipAmount!.toStringAsFixed(2)} \$',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.note_rounded, color: AppTheme.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Notes du client', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          Text(job.clientNotes!, style: AppTheme.bodyMedium),
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
          Text(label, style: AppTheme.bodySmall),
          Text(value, style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return BlocConsumer<WorkerJobsBloc, WorkerJobsState>(
      listener: (context, state) {
        if (state is JobActionSuccess && state.action == 'accept') {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Job accepté avec succès!'),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
            ),
          );
          Navigator.pop(context, true);
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
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is JobActionLoading && state.jobId == job.id;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      context.read<WorkerJobsBloc>().add(AcceptJob(job.id));
                    },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.success, Color(0xFF059669)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Accepter ce job',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'En attente';
      case JobStatus.assigned:
        return 'Assigné';
      case JobStatus.enRoute:
        return 'En route';
      case JobStatus.inProgress:
        return 'En cours';
      case JobStatus.completed:
        return 'Terminé';
      case JobStatus.cancelled:
        return 'Annulé';
    }
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return AppTheme.warning;
      case JobStatus.assigned:
        return AppTheme.primary;
      case JobStatus.enRoute:
        return AppTheme.secondary;
      case JobStatus.inProgress:
        return AppTheme.success;
      case JobStatus.completed:
        return const Color(0xFF059669);
      case JobStatus.cancelled:
        return AppTheme.textTertiary;
    }
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
