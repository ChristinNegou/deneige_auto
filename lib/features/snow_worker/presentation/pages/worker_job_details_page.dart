import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../domain/entities/worker_job.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../../data/datasources/worker_remote_datasource.dart'
    show WorkerCancellationReason;

class WorkerJobDetailsPage extends StatefulWidget {
  final WorkerJob job;

  const WorkerJobDetailsPage({super.key, required this.job});

  @override
  State<WorkerJobDetailsPage> createState() => _WorkerJobDetailsPageState();
}

class _WorkerJobDetailsPageState extends State<WorkerJobDetailsPage> {
  Timer? _statusCheckTimer;
  bool _isJobCancelled = false;
  late WorkerJob _currentJob;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    // Démarrer la vérification périodique du statut si le job est actif
    if (_currentJob.status == JobStatus.assigned ||
        _currentJob.status == JobStatus.enRoute ||
        _currentJob.status == JobStatus.inProgress) {
      _startStatusCheck();
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkJobStatus();
    });
  }

  Future<void> _checkJobStatus() async {
    if (_isJobCancelled || !mounted) return;

    try {
      final dio = sl<Dio>();
      final response = await dio.get('/reservations/${_currentJob.id}');

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final status = data['status'] as String?;

        if (status == 'cancelled') {
          _isJobCancelled = true;
          _statusCheckTimer?.cancel();

          final cancelReason = data['cancelReason'] as String? ??
              'Le client a annulé la réservation';
          final cancelledBy = data['cancelledBy'] as String? ?? 'client';

          _showJobCancelledDialog(cancelReason, cancelledBy);
        }
      }
    } catch (e) {
      debugPrint('Erreur vérification statut job: $e');
    }
  }

  void _showJobCancelledDialog(String reason, String cancelledBy) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          icon: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.errorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_rounded,
              color: AppTheme.error,
              size: 48,
            ),
          ),
          title: const Text(
            'Job annulé',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border:
                      Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cancelledBy == 'client'
                            ? 'Le client a annulé cette réservation.'
                            : 'Cette réservation a été annulée.',
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Raison: $reason',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: const Text(
                  'Retour au tableau de bord',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  WorkerJob get job => _currentJob;

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
                    if (job.clientNotes != null &&
                        job.clientNotes!.isNotEmpty) ...[
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
      bottomNavigationBar: _buildBottomButtons(context),
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
                child: const Icon(Icons.person_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Client', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nom', job.client.fullName),
          if (job.client.phoneNumber != null)
            _buildInfoRow('Téléphone', job.client.phoneNumber!),
          const SizedBox(height: 12),
          // Boutons de contact - toujours visibles
          Row(
            children: [
              // Bouton Appeler
              Expanded(
                child: _buildContactButton(
                  icon: Icons.phone_rounded,
                  label: 'Appeler',
                  color: job.client.phoneNumber != null
                      ? AppTheme.success
                      : AppTheme.textTertiary,
                  onTap: _handleCallClient,
                ),
              ),
              const SizedBox(width: 8),
              // Bouton Chat avec gradient
              Expanded(
                child: _buildChatButton(),
              ),
              const SizedBox(width: 8),
              // Bouton SMS
              Expanded(
                child: _buildContactButton(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  color: job.client.phoneNumber != null
                      ? AppTheme.info
                      : AppTheme.textTertiary,
                  onTap: _handleMessageClient,
                ),
              ),
            ],
          ),
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
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: _openChat,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur: utilisateur non authentifié'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<ChatBloc>()..add(LoadMessages(_currentJob.id)),
          child: ChatScreen(
            reservationId: _currentJob.id,
            otherUserName: _currentJob.client.fullName,
            otherUserPhoto: null,
            currentUserId: authState.user.id,
          ),
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
                child: const Icon(Icons.location_on_rounded,
                    color: AppTheme.error, size: 22),
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
              Icon(Icons.directions_rounded,
                  size: 16, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text(
                job.distanceKm != null
                    ? '${job.distanceKm!.toStringAsFixed(1)} km'
                    : 'N/A',
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
                    onPressed: () => _openMaps(
                        job.location!.latitude, job.location!.longitude),
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
                    onPressed: () => _openWaze(
                        job.location!.latitude, job.location!.longitude),
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
                child: const Icon(Icons.directions_car_rounded,
                    color: AppTheme.secondary, size: 22),
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
                child: const Icon(Icons.ac_unit_rounded,
                    color: AppTheme.info, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Service', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Type', 'Déneigement'),
          if (job.serviceOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Options:',
                style:
                    AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...job.serviceOptions.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 16),
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
                child: const Icon(Icons.attach_money_rounded,
                    color: AppTheme.success, size: 22),
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
                style:
                    AppTheme.headlineMedium.copyWith(color: AppTheme.success),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                child: const Icon(Icons.note_rounded,
                    color: AppTheme.warning, size: 22),
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
          Text(value,
              style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w500)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
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
                            Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 24),
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

  /// Gère l'appel du client avec vérification du numéro
  void _handleCallClient() {
    if (job.client.phoneNumber != null && job.client.phoneNumber!.isNotEmpty) {
      _callClient();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Numéro de téléphone non disponible'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
      );
    }
  }

  /// Gère l'envoi de SMS au client avec vérification du numéro
  void _handleMessageClient() {
    if (job.client.phoneNumber != null && job.client.phoneNumber!.isNotEmpty) {
      _messageClient();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Numéro de téléphone non disponible'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
      );
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

    final isEmulatorLocation =
        (lat - 37.4219983).abs() < 0.5 && (lng - (-122.084)).abs() < 0.5;

    if (isEmulatorLocation) {
      finalLat = 46.3432;
      finalLng = -72.5476;
    }

    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$finalLat,$finalLng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWaze(double lat, double lng) async {
    double finalLat = lat;
    double finalLng = lng;

    final isEmulatorLocation =
        (lat - 37.4219983).abs() < 0.5 && (lng - (-122.084)).abs() < 0.5;

    if (isEmulatorLocation) {
      finalLat = 46.3432;
      finalLng = -72.5476;
    }

    final uri =
        Uri.parse('https://waze.com/ul?ll=$finalLat,$finalLng&navigate=yes');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget? _buildBottomButtons(BuildContext context) {
    // Bouton d'acceptation pour les jobs en attente
    if (job.status == JobStatus.pending) {
      return _buildAcceptButton(context);
    }

    // Bouton d'annulation pour les jobs assignés/en route/en cours
    if (job.status == JobStatus.assigned ||
        job.status == JobStatus.enRoute ||
        job.status == JobStatus.inProgress) {
      return _buildCancelButton(context);
    }

    return null;
  }

  Widget _buildCancelButton(BuildContext context) {
    return BlocConsumer<WorkerJobsBloc, WorkerJobsState>(
      listener: (context, state) {
        if (state is JobCancellationSuccess) {
          HapticFeedback.heavyImpact();

          String message = state.result.message;
          Color bgColor = Colors.orange;

          // Afficher l'avertissement ou la suspension si applicable
          if (state.result.consequence != null) {
            if (state.result.consequence!.type == 'suspension') {
              message = state.result.consequence!.message;
              bgColor = AppTheme.error;
            } else if (state.result.consequence!.type == 'warning') {
              message = state.result.consequence!.message;
              bgColor = Colors.orange;
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.result.consequence?.type == 'suspension'
                        ? Icons.block
                        : Icons.warning_amber_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: bgColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is JobActionLoading && state.action == 'cancel';

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
              onTap: isLoading ? null : () => _showCancelDialog(context),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.error, width: 2),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.error,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cancel_rounded,
                                color: AppTheme.error, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Annuler ce job',
                              style: TextStyle(
                                color: AppTheme.error,
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

  void _showCancelDialog(BuildContext context) {
    HapticFeedback.mediumImpact();

    // Raisons valables d'annulation
    final reasons = <String, WorkerCancellationReason>{
      'vehicle_breakdown': WorkerCancellationReason(
        code: 'vehicle_breakdown',
        label: 'Panne de véhicule',
        description: 'Mon véhicule est en panne ou a un problème mécanique',
      ),
      'medical_emergency': WorkerCancellationReason(
        code: 'medical_emergency',
        label: 'Urgence médicale',
        description: 'J\'ai une urgence médicale personnelle',
      ),
      'severe_weather': WorkerCancellationReason(
        code: 'severe_weather',
        label: 'Conditions météo dangereuses',
        description: 'Les conditions météo rendent le trajet dangereux',
      ),
      'road_blocked': WorkerCancellationReason(
        code: 'road_blocked',
        label: 'Route bloquée',
        description: 'La route vers le client est bloquée ou inaccessible',
      ),
      'family_emergency': WorkerCancellationReason(
        code: 'family_emergency',
        label: 'Urgence familiale',
        description: 'J\'ai une urgence familiale',
      ),
      'equipment_failure': WorkerCancellationReason(
        code: 'equipment_failure',
        label: 'Équipement défaillant',
        description: 'Mon équipement de déneigement est défaillant',
      ),
    };

    String? selectedReasonCode;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Annuler le job?',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vous ne serez pas payé pour ce job.\nLes annulations fréquentes peuvent entraîner une suspension.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Raison de l\'annulation:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: selectedReasonCode,
                  onChanged: (value) {
                    setState(() => selectedReasonCode = value);
                  },
                  child: Column(
                    children: reasons.entries
                        .map((entry) => RadioListTile<String>(
                              title: Text(entry.value.label,
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: Text(entry.value.description,
                                  style: const TextStyle(fontSize: 11)),
                              value: entry.key,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Détails supplémentaires (optionnel)',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Retour'),
            ),
            ElevatedButton(
              onPressed: selectedReasonCode == null
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      context.read<WorkerJobsBloc>().add(
                            CancelJob(
                              jobId: job.id,
                              reasonCode: selectedReasonCode!,
                              reason: reasons[selectedReasonCode]?.label,
                              description: descriptionController.text.isNotEmpty
                                  ? descriptionController.text
                                  : null,
                            ),
                          );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer l\'annulation'),
            ),
          ],
        ),
      ),
    );
  }
}
