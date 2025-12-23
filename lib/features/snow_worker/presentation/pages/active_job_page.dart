import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
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
  Duration _elapsed = Duration.zero;
  late WorkerJob _currentJob;

  // Photo management
  final ImagePicker _imagePicker = ImagePicker();
  File? _afterPhoto;
  bool _isUploadingPhoto = false;
  bool _photoUploaded = false;
  String? _uploadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    if (_currentJob.status == JobStatus.inProgress && _currentJob.startedAt != null) {
      _elapsed = DateTime.now().difference(_currentJob.startedAt!);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    return BlocListener<WorkerJobsBloc, WorkerJobsState>(
      listener: (context, state) {
        if (state is JobActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getSuccessMessage(state.action)),
              backgroundColor: Colors.green,
            ),
          );
          if (state.action == 'complete') {
            Navigator.pop(context);
          } else if (state.updatedJob != null) {
            setState(() {
              _currentJob = state.updatedJob!;
              if (_currentJob.status == JobStatus.inProgress && _timer == null) {
                _startTimer();
              }
            });
          }
        } else if (state is WorkerJobsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job actif'),
          backgroundColor: _getStatusColor(_currentJob.status),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBanner(),
              const SizedBox(height: 16),
              if (_currentJob.status == JobStatus.inProgress)
                _buildTimerCard(),
              const SizedBox(height: 16),
              _buildClientCard(),
              const SizedBox(height: 16),
              _buildVehicleCard(),
              const SizedBox(height: 16),
              if (_currentJob.location != null) _buildNavigationButtons(),
              const SizedBox(height: 16),
              _buildActionSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(_currentJob.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(_currentJob.status),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_currentJob.status),
            color: _getStatusColor(_currentJob.status),
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusLabel(_currentJob.status),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(_currentJob.status),
                ),
              ),
              Text(
                _getStatusSubtitle(_currentJob.status),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Temps écoulé',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard() {
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange[100],
            child: Text(
              _currentJob.client.firstName[0].toUpperCase(),
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentJob.client.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentJob.displayAddress,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          if (_currentJob.client.phoneNumber != null)
            IconButton(
              onPressed: () => _callClient(_currentJob.client.phoneNumber!),
              icon: Icon(Icons.phone, color: Colors.green[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.directions_car, color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentJob.vehicle.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_currentJob.vehicle.licensePlate != null)
                  Text(
                    _currentJob.vehicle.licensePlate!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
              ],
            ),
          ),
          if (_currentJob.vehicle.color != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentJob.vehicle.color!,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openMaps(
              _currentJob.location!.latitude,
              _currentJob.location!.longitude,
            ),
            icon: const Icon(Icons.map),
            label: const Text('Google Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openWaze(
              _currentJob.location!.latitude,
              _currentJob.location!.longitude,
            ),
            icon: const Icon(Icons.navigation),
            label: const Text('Waze'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        final isLoading = state is JobActionLoading && state.jobId == _currentJob.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 32),
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            if (_currentJob.status == JobStatus.assigned)
              _buildActionButton(
                label: 'En route',
                icon: Icons.directions_car,
                color: Colors.blue,
                isLoading: isLoading,
                onPressed: () async {
                  // Marquer en route
                  context.read<WorkerJobsBloc>().add(MarkEnRoute(_currentJob.id));

                  // Ouvrir la navigation GPS
                  if (_currentJob.location != null) {
                    await _openMaps(
                      _currentJob.location!.latitude,
                      _currentJob.location!.longitude,
                    );
                  } else {
                    // Afficher un message si pas de coordonnées
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coordonnées GPS non disponibles. Utilisez l\'adresse affichée.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
              ),
            if (_currentJob.status == JobStatus.enRoute) ...[
              // Bouton "Je suis arrivé" - vérifie la position GPS
              _buildActionButton(
                label: 'Je suis arrivé',
                icon: Icons.location_on,
                color: Colors.purple,
                isLoading: isLoading,
                onPressed: () => _verifyArrivalAndStart(context),
              ),
              const SizedBox(height: 12),
              // Boutons de navigation (au cas où l'utilisateur a fermé l'app GPS)
              if (_currentJob.location != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaps(
                          _currentJob.location!.latitude,
                          _currentJob.location!.longitude,
                        ),
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openWaze(
                          _currentJob.location!.latitude,
                          _currentJob.location!.longitude,
                        ),
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Waze'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
            if (_currentJob.status == JobStatus.inProgress) ...[
              // Section photo obligatoire
              _buildPhotoSection(),
              const SizedBox(height: 16),
              // Bouton terminer - uniquement si photo uploadée
              _buildActionButton(
                label: _photoUploaded ? 'Terminer le job' : 'Photo requise',
                icon: _photoUploaded ? Icons.check_circle : Icons.camera_alt,
                color: _photoUploaded ? Colors.green : Colors.grey,
                isLoading: isLoading,
                onPressed: _photoUploaded ? () => _showCompleteDialog(context) : null,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _photoUploaded ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _photoUploaded ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _photoUploaded ? Icons.check_circle : Icons.camera_alt,
                color: _photoUploaded ? Colors.green : Colors.orange,
                size: 28,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _photoUploaded ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                    Text(
                      _photoUploaded
                          ? 'Vous pouvez maintenant terminer le job'
                          : 'Prenez une photo avant de terminer',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_afterPhoto != null && !_photoUploaded) ...[
            // Afficher la preview de la photo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingPhoto ? null : _takePhoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reprendre'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingPhoto ? null : _uploadPhoto,
                    icon: _isUploadingPhoto
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploadingPhoto ? 'Envoi...' : 'Envoyer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_photoUploaded) ...[
            // Photo uploadée avec succès
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _afterPhoto!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ] else ...[
            // Pas encore de photo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Prendre une photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
          _uploadedPhotoUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de photo: $e'),
            backgroundColor: Colors.red,
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
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (photoUrl) {
          setState(() {
            _uploadedPhotoUrl = photoUrl;
            _photoUploaded = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo envoyée avec succès!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
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
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Vérification de votre position...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Vérifier les permissions
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

      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Fermer le loading

      // Vérifier si le job a une localisation
      if (_currentJob.location == null) {
        // Pas de coordonnées GPS pour le job, permettre de commencer avec confirmation
        _showArrivedDialogNoGps(context);
        return;
      }

      // DEBUG: Détecter si on est sur l'émulateur (coordonnées de Mountain View)
      final isEmulatorPosition = (position.latitude - 37.4219983).abs() < 0.5 &&
          (position.longitude - (-122.084)).abs() < 0.5;

      // Si on est sur l'émulateur, on bypass la vérification de distance
      if (isEmulatorPosition) {
        debugPrint('🔧 DEBUG: Position émulateur détectée - Bypass de la vérification GPS');
        _showArrivedDialogConfirmed(context, 0);
        return;
      }

      // Calculer la distance
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _currentJob.location!.latitude,
        _currentJob.location!.longitude,
      );

      if (distance <= _arrivalRadiusMeters) {
        // Worker est dans le rayon autorisé
        _showArrivedDialogConfirmed(context, distance.round());
      } else {
        // Worker est trop loin
        _showTooFarDialog(context, distance.round());
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showLocationError(context, 'Erreur de localisation: ${e.toString()}');
    }
  }

  void _showArrivedDialogConfirmed(BuildContext context, int distanceMeters) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Position confirmée!'),
        content: Text(
          'Vous êtes à ${distanceMeters}m du véhicule.\n\n'
          'Vous pouvez maintenant commencer le travail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkerJobsBloc>().add(StartJob(_currentJob.id));
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Commencer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showArrivedDialogNoGps(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Coordonnées non disponibles'),
        content: const Text(
          'Ce job n\'a pas de coordonnées GPS enregistrées.\n\n'
          'Confirmez-vous être arrivé à l\'emplacement indiqué?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Non'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkerJobsBloc>().add(StartJob(_currentJob.id));
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Oui, commencer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  void _showTooFarDialog(BuildContext context, int distanceMeters) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.location_off, color: Colors.red, size: 48),
        title: const Text('Trop loin'),
        content: Text(
          'Vous êtes à ${distanceMeters}m du véhicule.\n\n'
          'Vous devez être à moins de ${_arrivalRadiusMeters.round()}m pour confirmer votre arrivée.\n\n'
          'Continuez à vous rapprocher.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
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
            icon: const Icon(Icons.navigation),
            label: const Text('Ouvrir GPS'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _showLocationError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading || isDisabled ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terminer le job'),
        content: const Text('Êtes-vous sûr de vouloir marquer ce job comme terminé?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkerJobsBloc>().add(CompleteJob(_currentJob.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return Colors.blue;
      case JobStatus.enRoute:
        return Colors.purple;
      case JobStatus.inProgress:
        return Colors.orange;
      case JobStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return Icons.assignment;
      case JobStatus.enRoute:
        return Icons.directions_car;
      case JobStatus.inProgress:
        return Icons.engineering;
      case JobStatus.completed:
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Job assigné';
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

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
