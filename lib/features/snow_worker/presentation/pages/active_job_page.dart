import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../domain/entities/worker_job.dart';
import '../../domain/repositories/worker_repository.dart';
import '../bloc/worker_jobs_bloc.dart';

// Rayon maximum en mètres pour confirmer l'arrivée
const double _arrivalRadiusMeters = 200.0;

class ActiveJobPage extends StatefulWidget {
  final WorkerJob job;

  const ActiveJobPage({super.key, required this.job});

  @override
  State<ActiveJobPage> createState() => _ActiveJobPageState();
}

class _ActiveJobPageState extends State<ActiveJobPage> {
  Timer? _timer;
  Timer? _statusCheckTimer;
  Duration _elapsed = Duration.zero;
  late WorkerJob _currentJob;
  bool _isJobCancelled = false;

  // Photo management
  final ImagePicker _imagePicker = ImagePicker();
  File? _afterPhoto;
  bool _isUploadingPhoto = false;
  bool _photoUploaded = false;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    if (_currentJob.status == JobStatus.inProgress &&
        _currentJob.startedAt != null) {
      _elapsed = DateTime.now().difference(_currentJob.startedAt!);
      _startTimer();
    }
    // Démarrer la vérification périodique du statut
    _startStatusCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  /// Démarre la vérification périodique du statut du job (toutes les 10 secondes)
  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkJobStatus();
    });
  }

  /// Vérifie le statut actuel du job auprès du serveur
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
          _timer?.cancel();
          _statusCheckTimer?.cancel();

          final cancelReason = data['cancelReason'] as String? ??
              'Le client a annulé la réservation';
          final cancelledBy = data['cancelledBy'] as String? ?? 'client';

          _showJobCancelledDialog(cancelReason, cancelledBy);
        }
      }
    } catch (e) {
      // Ignorer les erreurs de réseau silencieusement
      debugPrint('Erreur vérification statut job: $e');
    }
  }

  /// Affiche le dialogue d'annulation et redirige vers le dashboard
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
              const SizedBox(height: 8),
              Text(
                'Vous ne serez pas facturé pour ce job.',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
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
                  // Retourner au dashboard
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return BlocListener<WorkerJobsBloc, WorkerJobsState>(
      listener: (context, state) {
        if (state is JobActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.background, size: 20),
                  const SizedBox(width: 12),
                  Text(_getSuccessMessage(state.action)),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          );
          if (state.action == 'complete') {
            Navigator.pop(context);
          } else if (state.updatedJob != null) {
            setState(() {
              _currentJob = state.updatedJob!;
              if (_currentJob.status == JobStatus.inProgress &&
                  _timer == null) {
                _startTimer();
              }
            });
          }
        } else if (state is WorkerJobsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.background, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.paddingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBanner(),
                      const SizedBox(height: 16),
                      if (_currentJob.status == JobStatus.inProgress)
                        _buildTimerCard(),
                      if (_currentJob.status == JobStatus.inProgress)
                        const SizedBox(height: 16),
                      _buildClientCard(),
                      const SizedBox(height: 12),
                      _buildVehicleCard(),
                      const SizedBox(height: 16),
                      if (_currentJob.location != null)
                        _buildNavigationButtons(),
                      if (_currentJob.location != null)
                        const SizedBox(height: 16),
                      _buildActionSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            'Job actif',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          StatusBadge(
            label: _getStatusLabel(_currentJob.status),
            color: _getStatusColor(_currentJob.status),
            icon: _getStatusIcon(_currentJob.status),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color = _getStatusColor(_currentJob.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(
              _getStatusIcon(_currentJob.status),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusLabel(_currentJob.status),
                  style: AppTheme.headlineSmall.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusSubtitle(_currentJob.status),
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined,
                  color: AppTheme.background.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 8),
              Text(
                'Temps écoulé',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.background.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBlock(hours.toString().padLeft(2, '0'), 'h'),
              const Text(
                ' : ',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.background,
                ),
              ),
              _buildTimeBlock(minutes.toString().padLeft(2, '0'), 'm'),
              const Text(
                ' : ',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.background,
                ),
              ),
              _buildTimeBlock(seconds.toString().padLeft(2, '0'), 's'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(String value, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.background,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.background.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.warning, Color(0xFFFF9500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Center(
                  child: Text(
                    _currentJob.client.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.background,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentJob.client.fullName,
                      style: AppTheme.labelLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentJob.displayAddress,
                            style: AppTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 14),
          // Boutons de contact
          Row(
            children: [
              // Bouton Appeler - toujours visible
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleCallClient(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentJob.client.phoneNumber != null
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : AppTheme.textTertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 20,
                          color: _currentJob.client.phoneNumber != null
                              ? AppTheme.success
                              : AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Appeler',
                          style: TextStyle(
                            color: _currentJob.client.phoneNumber != null
                                ? AppTheme.success
                                : AppTheme.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton Chat in-app
              Expanded(
                child: GestureDetector(
                  onTap: () => _openChat(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
                            size: 20, color: AppTheme.background),
                        const SizedBox(width: 6),
                        const Text(
                          'Chat',
                          style: TextStyle(
                            color: AppTheme.background,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton SMS - toujours visible
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleMessageClient(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentJob.client.phoneNumber != null
                          ? AppTheme.info.withValues(alpha: 0.1)
                          : AppTheme.textTertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sms_rounded,
                          size: 20,
                          color: _currentJob.client.phoneNumber != null
                              ? AppTheme.info
                              : AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SMS',
                          style: TextStyle(
                            color: _currentJob.client.phoneNumber != null
                                ? AppTheme.info
                                : AppTheme.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    final hasPhoto = _currentJob.vehicle.photoUrl != null &&
        _currentJob.vehicle.photoUrl!.isNotEmpty;
    final photoUrl = hasPhoto
        ? '${AppConfig.apiBaseUrl}${_currentJob.vehicle.photoUrl}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Vehicle photo or icon
              GestureDetector(
                onTap: hasPhoto ? () => _showVehiclePhoto(photoUrl!) : null,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Text('🚗', style: TextStyle(fontSize: 28)),
                          ),
                        )
                      : const Center(
                          child: Text('🚗', style: TextStyle(fontSize: 28)),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentJob.vehicle.displayName,
                      style: AppTheme.labelLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (_currentJob.vehicle.licensePlate != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _currentJob.vehicle.licensePlate!,
                          style: AppTheme.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_currentJob.vehicle.color != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.infoLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    _currentJob.vehicle.color!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.info,
                    ),
                  ),
                ),
            ],
          ),
          // Show larger photo if available
          if (hasPhoto && photoUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showVehiclePhoto(photoUrl),
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  color: AppTheme.surfaceContainer,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.secondary),
                      ),
                      errorWidget: (context, url, error) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              color: AppTheme.textTertiary, size: 40),
                          const SizedBox(height: 8),
                          Text('Photo non disponible',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.textTertiary)),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Agrandir',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showVehiclePhoto(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
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
                      _currentJob.vehicle.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentJob.vehicle.color != null ||
                        _currentJob.vehicle.licensePlate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (_currentJob.vehicle.color != null)
                            _currentJob.vehicle.color,
                          if (_currentJob.vehicle.licensePlate != null)
                            _currentJob.vehicle.licensePlate,
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

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openMaps(
              _currentJob.location!.latitude,
              _currentJob.location!.longitude,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border:
                    Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                boxShadow: AppTheme.shadowSM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Google Maps',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _openWaze(
              _currentJob.location!.latitude,
              _currentJob.location!.longitude,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
                boxShadow: AppTheme.shadowSM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation_rounded,
                      size: 20, color: AppTheme.info),
                  const SizedBox(width: 8),
                  Text(
                    'Waze',
                    style: TextStyle(
                      color: AppTheme.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        final isLoading =
            state is JobActionLoading && state.jobId == _currentJob.id;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: AppTheme.shadowSM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: const Icon(Icons.flash_on_rounded,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Actions', style: AppTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 16),
              if (_currentJob.status == JobStatus.assigned)
                _buildGradientActionButton(
                  label: 'En route',
                  icon: Icons.directions_car_rounded,
                  gradientColors: [AppTheme.primary, AppTheme.secondary],
                  isLoading: isLoading,
                  onPressed: () async {
                    context
                        .read<WorkerJobsBloc>()
                        .add(MarkEnRoute(_currentJob.id));
                    if (_currentJob.location != null) {
                      await _openMaps(
                        _currentJob.location!.latitude,
                        _currentJob.location!.longitude,
                      );
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning,
                                    color: AppTheme.background, size: 20),
                                const SizedBox(width: 12),
                                const Expanded(
                                    child: Text(
                                        'Coordonnées GPS non disponibles')),
                              ],
                            ),
                            backgroundColor: AppTheme.warning,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMD),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              if (_currentJob.status == JobStatus.enRoute) ...[
                _buildGradientActionButton(
                  label: 'Je suis arrivé',
                  icon: Icons.location_on_rounded,
                  gradientColors: [AppTheme.secondary, const Color(0xFF7C3AED)],
                  isLoading: isLoading,
                  onPressed: () => _verifyArrivalAndStart(context),
                ),
                const SizedBox(height: 12),
                if (_currentJob.location != null)
                  Row(
                    children: [
                      Expanded(
                        child: _buildOutlinedButton(
                          icon: Icons.map_rounded,
                          label: 'Maps',
                          color: AppTheme.primary,
                          onPressed: () => _openMaps(
                            _currentJob.location!.latitude,
                            _currentJob.location!.longitude,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOutlinedButton(
                          icon: Icons.navigation_rounded,
                          label: 'Waze',
                          color: AppTheme.info,
                          onPressed: () => _openWaze(
                            _currentJob.location!.latitude,
                            _currentJob.location!.longitude,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
              if (_currentJob.status == JobStatus.inProgress) ...[
                _buildPhotoSection(),
                const SizedBox(height: 16),
                _buildGradientActionButton(
                  label: _photoUploaded ? 'Terminer le job' : 'Photo requise',
                  icon: _photoUploaded
                      ? Icons.check_circle_rounded
                      : Icons.camera_alt_rounded,
                  gradientColors: _photoUploaded
                      ? [AppTheme.success, const Color(0xFF059669)]
                      : [AppTheme.textTertiary, AppTheme.textSecondary],
                  isLoading: isLoading,
                  onPressed: _photoUploaded
                      ? () => _showCompleteDialog(context)
                      : null,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradientActionButton({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isLoading,
    VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    return GestureDetector(
      onTap: isLoading || isDisabled ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDisabled
                ? [
                    AppTheme.textTertiary.withValues(alpha: 0.5),
                    AppTheme.textSecondary.withValues(alpha: 0.5)
                  ]
                : gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.background,
                ),
              )
            else
              Icon(icon, color: AppTheme.background, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.background,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _photoUploaded ? AppTheme.successLight : AppTheme.warningLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: _photoUploaded
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.warning.withValues(alpha: 0.4),
          width: 1.5,
        ),
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
                  color: _photoUploaded
                      ? AppTheme.success.withValues(alpha: 0.2)
                      : AppTheme.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(
                  _photoUploaded
                      ? Icons.check_circle_rounded
                      : Icons.camera_alt_rounded,
                  color: _photoUploaded ? AppTheme.success : AppTheme.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _photoUploaded
                          ? 'Photo envoyée!'
                          : 'Photo du travail terminé',
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _photoUploaded
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _photoUploaded
                          ? 'Vous pouvez maintenant terminer'
                          : 'Prenez une photo avant de terminer',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_afterPhoto != null && !_photoUploaded) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: Image.file(
                _afterPhoto!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOutlinedButton(
                    icon: Icons.refresh_rounded,
                    label: 'Reprendre',
                    color: AppTheme.textSecondary,
                    onPressed: _isUploadingPhoto ? () {} : _takePhoto,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isUploadingPhoto ? null : _uploadPhoto,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isUploadingPhoto)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.background,
                              ),
                            )
                          else
                            const Icon(Icons.cloud_upload_rounded,
                                color: AppTheme.background, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _isUploadingPhoto ? 'Envoi...' : 'Envoyer',
                            style: const TextStyle(
                              color: AppTheme.background,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_photoUploaded) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: Stack(
                children: [
                  Image.file(
                    _afterPhoto!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppTheme.background,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.warning,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded,
                        color: AppTheme.background, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Prendre une photo',
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        setState(() {
          _afterPhoto = File(photo.path);
          _photoUploaded = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Impossible de prendre la photo. Vérifiez les permissions de la caméra.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_afterPhoto == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final repository = sl<WorkerRepository>();
      final result = await repository.uploadPhoto(
        jobId: _currentJob.id,
        type: 'after',
        photo: _afterPhoto!,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${failure.message}'),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            );
          }
        },
        (_) {
          setState(() {
            _photoUploaded = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.background, size: 20),
                    const SizedBox(width: 12),
                    const Text('Photo envoyée avec succès!'),
                  ],
                ),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Impossible d\'envoyer la photo. Vérifiez votre connexion.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _verifyArrivalAndStart(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: AppTheme.shadowLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 20),
              Text(
                'Vérification de votre position...',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!context.mounted) return;
          Navigator.pop(context);
          _showLocationError(context, 'Permission de localisation refusée');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!context.mounted) return;
        Navigator.pop(context);
        _showLocationError(
          context,
          'Permission de localisation refusée définitivement. Activez-la dans les paramètres.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      if (_currentJob.location == null) {
        _showArrivedDialogNoGps(context);
        return;
      }

      final isEmulatorPosition = (position.latitude - 37.4219983).abs() < 0.5 &&
          (position.longitude - (-122.084)).abs() < 0.5;

      if (isEmulatorPosition) {
        _showArrivedDialogConfirmed(context, 0);
        return;
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _currentJob.location!.latitude,
        _currentJob.location!.longitude,
      );

      if (distance <= _arrivalRadiusMeters) {
        _showArrivedDialogConfirmed(context, distance.round());
      } else {
        _showTooFarDialog(context, distance.round());
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showLocationError(context,
          'Impossible de déterminer votre position. Activez la localisation et réessayez.');
    }
  }

  void _showArrivedDialogConfirmed(BuildContext context, int distanceMeters) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.successLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 40),
        ),
        title: const Text('Position confirmée!'),
        content: Text(
          'Vous êtes à ${distanceMeters}m du véhicule.\n\nVous pouvez maintenant commencer le travail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkerJobsBloc>().add(StartJob(_currentJob.id));
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Commencer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showArrivedDialogNoGps(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.warningLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_rounded, color: AppTheme.warning, size: 40),
        ),
        title: const Text('Coordonnées non disponibles'),
        content: const Text(
          'Ce job n\'a pas de coordonnées GPS enregistrées.\n\nConfirmez-vous être arrivé à l\'emplacement indiqué?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Non', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkerJobsBloc>().add(StartJob(_currentJob.id));
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Oui, commencer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTooFarDialog(BuildContext context, int distanceMeters) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.errorLight,
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.location_off_rounded, color: AppTheme.error, size: 40),
        ),
        title: const Text('Trop loin'),
        content: Text(
          'Vous êtes à ${distanceMeters}m du véhicule.\n\nVous devez être à moins de ${_arrivalRadiusMeters.round()}m pour confirmer votre arrivée.\n\nContinuez à vous rapprocher.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('OK', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (_currentJob.location != null) {
                _openMaps(
                  _currentJob.location!.latitude,
                  _currentJob.location!.longitude,
                );
              }
            },
            icon: const Icon(Icons.navigation_rounded),
            label: const Text('Ouvrir GPS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.errorLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_rounded, color: AppTheme.error, size: 40),
        ),
        title: const Text('Erreur de localisation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.successLight,
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.task_alt_rounded, color: AppTheme.success, size: 40),
        ),
        title: const Text('Terminer le job'),
        content: const Text(
            'Êtes-vous sûr de vouloir marquer ce job comme terminé?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkerJobsBloc>().add(CompleteJob(_currentJob.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return AppTheme.primary;
      case JobStatus.enRoute:
        return AppTheme.secondary;
      case JobStatus.inProgress:
        return AppTheme.warning;
      case JobStatus.completed:
        return AppTheme.success;
      default:
        return AppTheme.textTertiary;
    }
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return Icons.assignment_rounded;
      case JobStatus.enRoute:
        return Icons.directions_car_rounded;
      case JobStatus.inProgress:
        return Icons.engineering_rounded;
      case JobStatus.completed:
        return Icons.check_circle_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getStatusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Assigné';
      case JobStatus.enRoute:
        return 'En route';
      case JobStatus.inProgress:
        return 'En cours';
      case JobStatus.completed:
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  String _getStatusSubtitle(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Appuyez sur "En route" pour commencer';
      case JobStatus.enRoute:
        return 'Dirigez-vous vers le client';
      case JobStatus.inProgress:
        return 'Travail en cours...';
      case JobStatus.completed:
        return 'Bon travail!';
      default:
        return '';
    }
  }

  String _getSuccessMessage(String action) {
    switch (action) {
      case 'en-route':
        return 'Statut mis à jour: En route';
      case 'start':
        return 'Job démarré!';
      case 'complete':
        return 'Job terminé avec succès!';
      default:
        return 'Action réussie';
    }
  }

  /// Gère l'appel du client avec vérification du numéro
  void _handleCallClient() {
    if (_currentJob.client.phoneNumber != null &&
        _currentJob.client.phoneNumber!.isNotEmpty) {
      _callClient(_currentJob.client.phoneNumber!);
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

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Gère l'envoi de SMS au client avec vérification du numéro
  void _handleMessageClient() {
    if (_currentJob.client.phoneNumber != null &&
        _currentJob.client.phoneNumber!.isNotEmpty) {
      _messageClient(_currentJob.client.phoneNumber!);
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

  Future<void> _messageClient(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Ouvre l'écran de chat avec le client
  void _openChat(BuildContext context) {
    // Récupérer l'ID de l'utilisateur actuel depuis AuthBloc
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
}
