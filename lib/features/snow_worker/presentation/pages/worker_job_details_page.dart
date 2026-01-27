import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart' hide ServiceOption;
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
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
              AppLocalizations.of(context)!.worker_clientCancelled;
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
          title: Text(
            AppLocalizations.of(context)!.worker_jobCancelled,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                            ? AppLocalizations.of(context)!
                                .worker_clientCancelledMessage
                            : AppLocalizations.of(context)!
                                .worker_cancelledMessage,
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
                AppLocalizations.of(context)!.worker_cancelReason(reason),
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
                child: Text(
                  AppLocalizations.of(context)!.worker_backToDashboard,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
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
            AppLocalizations.of(context)!.worker_jobDetails,
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
              Text(AppLocalizations.of(context)!.worker_client,
                  style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              AppLocalizations.of(context)!.common_name, job.client.fullName),
          if (job.client.phoneNumber != null)
            _buildInfoRow(AppLocalizations.of(context)!.common_phone,
                job.client.phoneNumber!),
          const SizedBox(height: 12),
          // Boutons de contact - toujours visibles
          Row(
            children: [
              // Bouton Appeler
              Expanded(
                child: _buildContactButton(
                  icon: Icons.phone_rounded,
                  label: AppLocalizations.of(context)!.common_call,
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
                  label: AppLocalizations.of(context)!.common_sms,
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
            Icon(icon, color: AppTheme.background, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.background,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_rounded,
                color: AppTheme.background, size: 18),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.reservation_chat,
              style: const TextStyle(
                color: AppTheme.background,
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
          content: Text(AppLocalizations.of(context)!.worker_userNotAuth),
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
              Text(AppLocalizations.of(context)!.common_address,
                  style: AppTheme.headlineSmall),
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
                    label:
                        Text(AppLocalizations.of(context)!.worker_googleMaps),
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
                    label: Text(AppLocalizations.of(context)!.worker_waze),
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
    final hasPhoto =
        job.vehicle.photoUrl != null && job.vehicle.photoUrl!.isNotEmpty;
    final photoUrl =
        hasPhoto ? '${AppConfig.apiBaseUrl}${job.vehicle.photoUrl}' : null;

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
              Text(AppLocalizations.of(context)!.step1_vehicle,
                  style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          // Vehicle photo if available
          if (hasPhoto && photoUrl != null) ...[
            GestureDetector(
              onTap: () => _showFullScreenPhoto(photoUrl),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  color: AppTheme.surfaceContainer,
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_rounded,
                          color: AppTheme.textTertiary, size: 48),
                      const SizedBox(height: 8),
                      Text(
                          AppLocalizations.of(context)!
                              .reservation_photoUnavailable,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.textTertiary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(AppLocalizations.of(context)!.step1_vehicle,
              job.vehicle.displayName),
          if (job.vehicle.color != null)
            _buildInfoRow(AppLocalizations.of(context)!.addVehicle_color,
                job.vehicle.color!),
          if (job.vehicle.licensePlate != null)
            _buildInfoRow(AppLocalizations.of(context)!.addVehicle_plate,
                job.vehicle.licensePlate!),
        ],
      ),
    );
  }

  void _showFullScreenPhoto(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Semi-transparent background
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
            // Photo
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            // Vehicle info
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      job.vehicle.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (job.vehicle.color != null ||
                        job.vehicle.licensePlate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (job.vehicle.color != null) job.vehicle.color,
                          if (job.vehicle.licensePlate != null)
                            job.vehicle.licensePlate,
                        ].join(' • '),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
              Text(AppLocalizations.of(context)!.worker_service,
                  style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(AppLocalizations.of(context)!.addVehicle_vehicleType,
              AppLocalizations.of(context)!.worker_snowRemoval),
          if (job.serviceOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.worker_options,
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
              Text(AppLocalizations.of(context)!.worker_pricing,
                  style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.reservation_totalPrice,
                  style: AppTheme.bodyMedium),
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
                Text(AppLocalizations.of(context)!.worker_tip,
                    style: AppTheme.bodyMedium),
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
              Text(AppLocalizations.of(context)!.worker_clientNotes,
                  style: AppTheme.headlineSmall),
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
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.background),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.worker_jobAccepted),
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
                  const Icon(Icons.error, color: AppTheme.background),
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
                color: AppTheme.shadowColor.withValues(alpha: 0.05),
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
                            color: AppTheme.background,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.background, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.worker_acceptJob,
                              style: const TextStyle(
                                color: AppTheme.background,
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
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case JobStatus.pending:
        return l10n.reservation_shortPending;
      case JobStatus.assigned:
        return l10n.worker_earningsAssigned;
      case JobStatus.enRoute:
        return l10n.worker_enRoute;
      case JobStatus.inProgress:
        return l10n.activities_inProgress;
      case JobStatus.completed:
        return l10n.worker_earningsCompleted;
      case JobStatus.cancelled:
        return l10n.reservation_shortCancelled;
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
    final l10n = AppLocalizations.of(context)!;
    switch (option) {
      case ServiceOption.windowScraping:
        return l10n.option_windowScraping;
      case ServiceOption.doorDeicing:
        return l10n.option_doorDeicing;
      case ServiceOption.wheelClearance:
        return l10n.option_wheelClearance;
      case ServiceOption.roofClearing:
        return l10n.option_roofClearing;
      case ServiceOption.saltSpreading:
        return l10n.option_saltSpreading;
      case ServiceOption.lightsCleaning:
        return l10n.option_lightsCleaning;
      case ServiceOption.perimeterClearance:
        return l10n.option_perimeterClearance;
      case ServiceOption.exhaustCheck:
        return l10n.option_exhaustCheck;
    }
  }

  /// Gère l'appel du client avec vérification du numéro
  void _handleCallClient() {
    if (job.client.phoneNumber != null && job.client.phoneNumber!.isNotEmpty) {
      _callClient();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.worker_phoneUnavailable),
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
          content: Text(AppLocalizations.of(context)!.worker_phoneUnavailable),
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
          Color bgColor = AppTheme.warning;

          // Afficher l'avertissement ou la suspension si applicable
          if (state.result.consequence != null) {
            if (state.result.consequence!.type == 'suspension') {
              message = state.result.consequence!.message;
              bgColor = AppTheme.error;
            } else if (state.result.consequence!.type == 'warning') {
              message = state.result.consequence!.message;
              bgColor = AppTheme.warning;
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
                    color: AppTheme.background,
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
                  const Icon(Icons.error, color: AppTheme.background),
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
                color: AppTheme.shadowColor.withValues(alpha: 0.05),
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
                          children: [
                            const Icon(Icons.cancel_rounded,
                                color: AppTheme.error, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!
                                  .worker_cancelThisJob,
                              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    final reasons = <String, WorkerCancellationReason>{
      'vehicle_breakdown': WorkerCancellationReason(
        code: 'vehicle_breakdown',
        label: l10n.worker_cancelReasonVehicleBreakdown,
        description: l10n.worker_cancelReasonVehicleBreakdownDesc,
      ),
      'medical_emergency': WorkerCancellationReason(
        code: 'medical_emergency',
        label: l10n.worker_cancelReasonMedicalEmergency,
        description: l10n.worker_cancelReasonMedicalEmergencyDesc,
      ),
      'severe_weather': WorkerCancellationReason(
        code: 'severe_weather',
        label: l10n.worker_cancelReasonSevereWeather,
        description: l10n.worker_cancelReasonSevereWeatherDesc,
      ),
      'road_blocked': WorkerCancellationReason(
        code: 'road_blocked',
        label: l10n.worker_cancelReasonRoadBlocked,
        description: l10n.worker_cancelReasonRoadBlockedDesc,
      ),
      'family_emergency': WorkerCancellationReason(
        code: 'family_emergency',
        label: l10n.worker_cancelReasonFamilyEmergency,
        description: l10n.worker_cancelReasonFamilyEmergencyDesc,
      ),
      'equipment_failure': WorkerCancellationReason(
        code: 'equipment_failure',
        label: l10n.worker_cancelReasonEquipmentFailure,
        description: l10n.worker_cancelReasonEquipmentFailureDesc,
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
                  color: AppTheme.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: AppTheme.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.worker_cancelJobQuestion,
                  style: const TextStyle(fontSize: 18),
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
                    color: AppTheme.warningLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.worker_cancelWarning,
                          style: const TextStyle(
                            color: AppTheme.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.worker_cancelReasonLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                    hintText: AppLocalizations.of(context)!
                        .worker_additionalDetailsOptional,
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
              child: Text(AppLocalizations.of(context)!.common_back),
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
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.background,
              ),
              child: Text(
                  AppLocalizations.of(context)!.worker_confirmCancellation),
            ),
          ],
        ),
      ),
    );
  }
}
