import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_features/presentation/widgets/ai_photo_feedback_dialog.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../vehicule/presentation/widgets/vehicle_visuals.dart';
import '../../domain/entities/worker_job.dart';
import '../../domain/repositories/worker_repository.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../widgets/client_contact_row.dart';
import '../widgets/job_labels.dart';

/// Distance maximale (metres) pour confirmer l'arrivee pres de la voiture.
const double _arrivalRadiusMeters = 200.0;

/// Position par defaut de l'emulateur Android (Mountain View), ignoree en
/// mode debug pour pouvoir tester sans se deplacer.
bool _isEmulatorPosition(double lat, double lng) =>
    kDebugMode && (lat - 37.4219983).abs() < 0.5 && (lng + 122.084).abs() < 0.5;

/// Deneigement accepte, du depart jusqu'a la fin : une etape a la fois, avec
/// un seul bouton principal en bas de l'ecran.
class ActiveJobPage extends StatefulWidget {
  final WorkerJob job;

  const ActiveJobPage({super.key, required this.job});

  @override
  State<ActiveJobPage> createState() => _ActiveJobPageState();
}

class _ActiveJobPageState extends State<ActiveJobPage> {
  late WorkerJob _job;
  Timer? _timer;
  Timer? _statusCheckTimer;
  DateTime? _startedAt;
  bool _isJobCancelled = false;

  final ImagePicker _imagePicker = ImagePicker();
  File? _afterPhoto;
  bool _isUploadingPhoto = false;
  bool _photoUploaded = false;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _photoUploaded = _job.afterPhotoUrl != null;
    if (_job.status == JobStatus.inProgress) {
      _startedAt = _job.startedAt ?? DateTime.now();
      _startTimer();
    }
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _checkJobStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  /// Le client peut annuler pendant que le deneigeur est en route.
  Future<void> _checkJobStatus() async {
    if (_isJobCancelled || !mounted) return;
    try {
      final response = await sl<Dio>().get('/reservations/${_job.id}');
      if (!mounted) return;
      final data = response.data['data'];
      if (response.statusCode == 200 &&
          response.data['success'] == true &&
          data['status'] == 'cancelled') {
        _isJobCancelled = true;
        _timer?.cancel();
        _statusCheckTimer?.cancel();
        _showJobCancelledDialog(
          data['cancelReason'] as String?,
          data['cancelledBy'] as String? ?? 'client',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification statut job: $e');
    }
  }

  String _time(DateTime date) =>
      DateFormat.Hm(Localizations.localeOf(context).toString())
          .format(date.toLocal());

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  // --- Ecran ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);

    return BlocListener<WorkerJobsBloc, WorkerJobsState>(
      listener: (context, state) {
        if (state is JobActionSuccess) {
          if (state.action == 'complete') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.activeJ_done)),
            );
            Navigator.pop(context);
          } else if (state.updatedJob != null) {
            setState(() {
              _job = state.updatedJob!;
              if (_job.status == JobStatus.inProgress && _timer == null) {
                _startedAt = _job.startedAt ?? DateTime.now();
                _startTimer();
              }
            });
          }
        } else if (state is WorkerJobsError) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
          title: Text(l10n.activeJ_title, style: AppTheme.labelLarge),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _StepTracker(status: _job.status),
            const SizedBox(height: 20),
            _buildHero(l10n),
            const SizedBox(height: 16),
            if (_job.status == JobStatus.inProgress) ...[
              _buildPhotoCard(l10n),
              const SizedBox(height: 16),
            ],
            _buildWhereCard(l10n),
            const SizedBox(height: 16),
            _buildVehicleCard(l10n),
            const SizedBox(height: 16),
            _buildTodoCard(l10n),
            const SizedBox(height: 16),
            _buildClientCard(l10n),
          ],
        ),
        bottomNavigationBar: _buildMainAction(l10n),
      ),
    );
  }

  /// Panneau bleu nuit : l'heure qui compte, ou le chrono une fois commence.
  Widget _buildHero(AppLocalizations l10n) {
    final onPrimary = AppTheme.onPrimary;
    final deadline = _job.deadlineTime ??
        _job.departureTime.subtract(const Duration(minutes: 30));

    Widget content;
    if (_job.status == JobStatus.inProgress && _startedAt != null) {
      final elapsed = DateTime.now().difference(_startedAt!);
      final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
      final seconds =
          elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.activeJ_elapsed,
              style: AppTheme.labelMedium
                  .copyWith(color: onPrimary.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: onPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.activeJ_readyBy(_time(deadline)),
              style: AppTheme.bodyMedium.copyWith(color: onPrimary)),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.activeJ_readyBy(_time(deadline)),
            style: AppTheme.headlineLarge.copyWith(color: onPrimary),
          ),
          const SizedBox(height: 4),
          Text(l10n.activeJ_clientLeaves(_time(_job.departureTime)),
              style: AppTheme.bodyMedium
                  .copyWith(color: onPrimary.withValues(alpha: 0.75))),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: content,
    );
  }

  Widget _buildWhereCard(AppLocalizations l10n) {
    final spot = jobSpotLabel(l10n, _job);
    final address = _job.location?.address;
    return _Card(
      title: l10n.activeJ_where,
      children: [
        if (spot != null) Text(spot, style: AppTheme.headlineSmall),
        if (address != null && address.isNotEmpty) ...[
          if (spot != null) const SizedBox(height: 2),
          Text(address,
              style: spot != null ? AppTheme.bodySmall : AppTheme.bodyLarge),
        ],
        if (_job.location != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openMaps(
                      _job.location!.latitude, _job.location!.longitude),
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(l10n.worker_googleMaps),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openWaze(
                      _job.location!.latitude, _job.location!.longitude),
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: Text(l10n.worker_waze),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleCard(AppLocalizations l10n) {
    final vehicle = _job.vehicle;
    final photoUrl = vehicle.photoUrl != null && vehicle.photoUrl!.isNotEmpty
        ? '${AppConfig.apiBaseUrl}${vehicle.photoUrl}'
        : null;

    return _Card(
      title: l10n.activeJ_vehicle,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap:
                  photoUrl != null ? () => _showVehiclePhoto(photoUrl) : null,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                            Icons.directions_car_filled_rounded,
                            color: AppTheme.textSecondary),
                      )
                    : Icon(Icons.directions_car_filled_rounded,
                        size: 28, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.displayName, style: AppTheme.headlineSmall),
                  if (vehicle.color != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        VehicleColorDot(colorName: vehicle.color!),
                        const SizedBox(width: 6),
                        Text(vehicle.color!, style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (vehicle.licensePlate != null)
              LicensePlate(plate: vehicle.licensePlate!),
          ],
        ),
      ],
    );
  }

  Widget _buildTodoCard(AppLocalizations l10n) {
    return _Card(
      title: l10n.activeJ_todo,
      children: [
        _TodoLine(l10n.activeJ_basicClearing),
        for (final option in _job.serviceOptions)
          _TodoLine(serviceOptionLabel(l10n, option)),
        if (_job.snowDepthCm != null && _job.snowDepthCm! > 0) ...[
          const SizedBox(height: 6),
          Text(l10n.activeJ_snowDepth(_job.snowDepthCm!),
              style: AppTheme.bodySmall),
        ],
        if (_job.clientNotes != null &&
            _job.clientNotes!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.worker_clientNotes, style: AppTheme.labelMedium),
                const SizedBox(height: 4),
                Text(_job.clientNotes!.trim(), style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClientCard(AppLocalizations l10n) {
    return _Card(
      title: l10n.activeJ_client,
      children: [
        Text(_job.client.fullName, style: AppTheme.headlineSmall),
        const SizedBox(height: 12),
        ClientContactRow(
          hasPhone: _job.client.phoneNumber?.isNotEmpty ?? false,
          onCall: () => _launchPhone('tel'),
          onChat: () => _openChat(context),
          onSms: () => _launchPhone('sms'),
        ),
      ],
    );
  }

  /// Photo "apres", obligatoire pour terminer. Envoyee des qu'elle est prise.
  Widget _buildPhotoCard(AppLocalizations l10n) {
    return _Card(
      title: l10n.activeJ_photoTitle,
      children: [
        Text(l10n.activeJ_photoHelp, style: AppTheme.bodySmall),
        const SizedBox(height: 12),
        if (_afterPhoto != null || _job.afterPhotoUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _afterPhoto != null
                      ? Image.file(_afterPhoto!, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: _job.afterPhotoUrl!, fit: BoxFit.cover),
                ),
                if (_isUploadingPhoto)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child:
                          const CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (_isUploadingPhoto)
              Text(l10n.activeJ_photoSending, style: AppTheme.bodySmall)
            else if (_photoUploaded)
              Row(
                children: [
                  Icon(Icons.check_rounded,
                      size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(l10n.activeJ_photoSent, style: AppTheme.bodySmall),
                ],
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isUploadingPhoto ? null : _takePhoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(_afterPhoto != null || _photoUploaded
                  ? l10n.worker_retakePhoto
                  : l10n.worker_takePhoto),
            ),
          ],
        ),
        if (_photoError != null)
          Text(_photoError!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
      ],
    );
  }

  /// Le bouton de l'etape suivante, toujours au meme endroit.
  Widget _buildMainAction(AppLocalizations l10n) {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        final isLoading = state is JobActionLoading && state.jobId == _job.id;

        String? label;
        VoidCallback? onPressed;
        switch (_job.status) {
          case JobStatus.assigned:
            label = l10n.activeJ_goEnRoute;
            onPressed = _goEnRoute;
          case JobStatus.enRoute:
            label = l10n.activeJ_arrivedStart;
            onPressed = () => _verifyArrivalAndStart(context);
          case JobStatus.inProgress:
            label = l10n.activeJ_finish;
            onPressed = _photoUploaded && !_isUploadingPhoto
                ? () => _confirmFinish(context)
                : null;
          default:
            return const SizedBox.shrink();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton(
              onPressed: isLoading || onPressed == null
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onPressed!();
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 58),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppTheme.onPrimary),
                    )
                  : Text(label),
            ),
          ),
        );
      },
    );
  }

  // --- Actions ---

  Future<void> _goEnRoute() async {
    context.read<WorkerJobsBloc>().add(MarkEnRoute(_job.id));
    if (_job.location != null) {
      await _openMaps(_job.location!.latitude, _job.location!.longitude);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (photo == null) return;
      setState(() {
        _afterPhoto = File(photo.path);
        _photoUploaded = false;
        _photoError = null;
      });
      await _uploadPhoto();
    } catch (_) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.worker_cameraPermissionError);
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_afterPhoto == null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isUploadingPhoto = true);
    try {
      final result = await sl<WorkerRepository>().uploadPhoto(
        jobId: _job.id,
        type: 'after',
        photo: _afterPhoto!,
      );
      if (!mounted) return;
      result.fold(
        (failure) => setState(() => _photoError = failure.message),
        (_) {
          setState(() => _photoUploaded = true);
          // Analyse de la photo : propose de la reprendre si elle est floue
          AIPhotoFeedbackDialog.show(
            context,
            reservationId: _job.id,
            onDismiss: () {},
            onRetake: _takePhoto,
          );
        },
      );
    } catch (_) {
      if (mounted) setState(() => _photoError = l10n.worker_photoUploadError);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _confirmFinish(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.activeJ_finish),
        content: Text(l10n.activeJ_confirmFinish),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel,
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkerJobsBloc>().add(CompleteJob(_job.id));
            },
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );
  }

  /// Verifie la position puis commence directement si le deneigeur est a
  /// moins de 200 m de la voiture.
  Future<void> _verifyArrivalAndStart(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<WorkerJobsBloc>();
    void start() => bloc.add(StartJob(_job.id));

    if (_job.location == null) {
      _confirmDialog(
        title: l10n.worker_coordinatesUnavailable,
        message: l10n.worker_noGpsConfirmArrival,
        confirmLabel: l10n.worker_yesStart,
        onConfirm: start,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.worker_verifyingPosition)),
          ],
        ),
      ),
    );

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!context.mounted) return;
        Navigator.pop(context);
        _messageDialog(
          l10n.worker_locationError,
          permission == LocationPermission.deniedForever
              ? l10n.worker_locationPermissionDeniedForever
              : l10n.worker_locationPermissionDenied,
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

      final distance =
          _isEmulatorPosition(position.latitude, position.longitude)
              ? 0.0
              : Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  _job.location!.latitude,
                  _job.location!.longitude,
                );

      if (distance <= _arrivalRadiusMeters) {
        start();
      } else {
        _confirmDialog(
          title: l10n.worker_tooFar,
          message: l10n.worker_tooFarMessage(
              distance.round(), _arrivalRadiusMeters.round()),
          confirmLabel: l10n.worker_openGps,
          onConfirm: () =>
              _openMaps(_job.location!.latitude, _job.location!.longitude),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _messageDialog(
          l10n.worker_locationError, l10n.worker_cannotDeterminePosition);
    }
  }

  void _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel,
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _messageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
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

  void _showJobCancelledDialog(String? reason, String cancelledBy) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l10n.activeJ_cancelled),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cancelledBy == 'client'
                  ? l10n.worker_clientCancelledMessage
                  : l10n.worker_cancelledMessage),
              if (reason != null && reason.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.worker_cancelReason(reason.trim()),
                    style: AppTheme.bodySmall),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(l10n.activeJ_backHome),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehiclePhoto(String photoUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child:
                  CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: MediaQuery.of(dialogContext).padding.top + 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String scheme) async {
    final phone = _job.client.phoneNumber;
    if (phone == null || phone.isEmpty) {
      _showError(AppLocalizations.of(context)!.worker_phoneUnavailable);
      return;
    }
    final uri = Uri.parse('$scheme:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openChat(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showError(AppLocalizations.of(context)!.worker_userNotAuth);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<ChatBloc>()..add(LoadMessages(_job.id)),
          child: ChatScreen(
            reservationId: _job.id,
            otherUserName: _job.client.fullName,
            otherUserPhoto: null,
            currentUserId: authState.user.id,
          ),
        ),
      ),
    );
  }

  /// En debug, la position de l'emulateur est remplacee par Trois-Rivieres.
  (double, double) _destination(double lat, double lng) =>
      _isEmulatorPosition(lat, lng)
          ? (AppConfig.targetLatitude, AppConfig.targetLongitude)
          : (lat, lng);

  Future<void> _openMaps(double lat, double lng) async {
    final (dLat, dLng) = _destination(lat, lng);
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$dLat,$dLng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWaze(double lat, double lng) async {
    final (dLat, dLng) = _destination(lat, lng);
    final uri = Uri.parse('https://waze.com/ul?ll=$dLat,$dLng&navigate=yes');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Les quatre etapes d'un deneigement, l'etape courante mise en avant.
class _StepTracker extends StatelessWidget {
  final JobStatus status;
  const _StepTracker({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.activeJ_stepAccepted,
      l10n.activeJ_stepEnRoute,
      l10n.activeJ_stepOnSite,
      l10n.activeJ_stepDone,
    ];
    final current = switch (status) {
      JobStatus.assigned => 0,
      JobStatus.enRoute => 1,
      JobStatus.inProgress => 2,
      JobStatus.completed => 3,
      _ => 0,
    };

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < labels.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= current ? AppTheme.primary : AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: AppTheme.labelSmall.copyWith(
                    color: i == current
                        ? AppTheme.textPrimary
                        : AppTheme.textTertiary,
                    fontWeight:
                        i == current ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelMedium),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _TodoLine extends StatelessWidget {
  final String text;
  const _TodoLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTheme.bodyMedium)),
        ],
      ),
    );
  }
}
