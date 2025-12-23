import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_routes.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../domain/entities/worker_job.dart';
import '../presentation/bloc/worker_availability_bloc.dart';
import '../presentation/bloc/worker_jobs_bloc.dart';
import '../presentation/bloc/worker_stats_bloc.dart';
import '../presentation/widgets/availability_toggle.dart';
import '../presentation/widgets/swipeable_job_card.dart';
import '../presentation/widgets/stats_card.dart';
import '../services/worker_notification_service.dart';

class SnowWorkerHomeScreen extends StatefulWidget {
  const SnowWorkerHomeScreen({super.key});

  @override
  State<SnowWorkerHomeScreen> createState() => _SnowWorkerHomeScreenState();
}

class _SnowWorkerHomeScreenState extends State<SnowWorkerHomeScreen>
    with TickerProviderStateMixin {
  Position? _currentPosition;
  Timer? _refreshTimer;
  final WorkerNotificationService _notificationService = WorkerNotificationService();
  Set<String> _previousJobIds = {};
  late AnimationController _pulseController;
  bool _isFirstLoad = true;

  // Auto-refresh interval (15 seconds for better responsiveness)
  static const Duration _refreshInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initializeLocation();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkForNewJobs(List<WorkerJob> currentJobs) {
    if (_isFirstLoad) {
      _previousJobIds = currentJobs.map((j) => j.id).toSet();
      _isFirstLoad = false;
      return;
    }

    final currentIds = currentJobs.map((j) => j.id).toSet();
    final newJobIds = currentIds.difference(_previousJobIds);

    if (newJobIds.isNotEmpty) {
      final newJobs = currentJobs.where((j) => newJobIds.contains(j.id)).toList();
      final hasUrgent = newJobs.any((j) => j.isPriority);

      // Vibration + notification
      if (newJobs.length == 1) {
        _notificationService.notifyNewJob(newJobs.first);
      } else {
        _notificationService.notifyMultipleNewJobs(newJobs.length, hasUrgent: hasUrgent);
      }

      // Haptic feedback
      HapticFeedback.heavyImpact();

      // Show in-app snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  hasUrgent ? Icons.bolt : Icons.work,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    newJobs.length == 1
                        ? 'Nouveau job: ${newJobs.first.displayAddress}'
                        : '${newJobs.length} nouveaux jobs disponibles!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: hasUrgent ? Colors.orange[700] : Colors.green[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'VOIR',
              textColor: Colors.white,
              onPressed: () {
                // Scroll to jobs section
              },
            ),
          ),
        );
      }
    }

    _previousJobIds = currentIds;
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _onRefresh();
      }
    });
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _loadDataWithDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _loadDataWithDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _loadDataWithDefaultLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // DEBUG: Détecter si on est sur l'émulateur (coordonnées de Mountain View)
      // et utiliser Trois-Rivières à la place
      final isEmulatorLocation = (position.latitude - 37.4219983).abs() < 0.01 &&
          (position.longitude - (-122.084)).abs() < 0.01;

      if (isEmulatorLocation) {
        debugPrint('🔧 Emulator detected, using Trois-Rivières coordinates');
        _loadDataWithDefaultLocation();
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      // Load data with position
      _loadData();
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Load with default position (Trois-Rivières)
      _loadDataWithDefaultLocation();
    }
  }

  void _loadData() {
    if (_currentPosition != null) {
      context.read<WorkerJobsBloc>().add(LoadAvailableJobs(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          ));
      context.read<WorkerAvailabilityBloc>().add(const LoadAvailability());
      context.read<WorkerStatsBloc>().add(const LoadStats());
    }
  }

  void _loadDataWithDefaultLocation() {
    // Default: Trois-Rivières
    context.read<WorkerJobsBloc>().add(const LoadAvailableJobs(
          latitude: 46.3432,
          longitude: -72.5476,
        ));
    context.read<WorkerAvailabilityBloc>().add(const LoadAvailability());
    context.read<WorkerStatsBloc>().add(const LoadStats());
  }

  Future<void> _onRefresh() async {
    // Utiliser la position actuelle ou les coordonnées par défaut (Trois-Rivières)
    final lat = _currentPosition?.latitude ?? 46.3432;
    final lng = _currentPosition?.longitude ?? -72.5476;

    context.read<WorkerJobsBloc>().add(RefreshJobs(
          latitude: lat,
          longitude: lng,
        ));
    context.read<WorkerStatsBloc>().add(const RefreshStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final user = authState.user;

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 100,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.orange[600],
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Bonjour, ${user.name.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.history),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.workerHistory);
                        },
                        tooltip: 'Historique',
                      ),
                      IconButton(
                        icon: const Icon(Icons.account_circle),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.profile);
                        },
                        tooltip: 'Profil',
                      ),
                    ],
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Availability Toggle
                        BlocBuilder<WorkerAvailabilityBloc,
                            WorkerAvailabilityState>(
                          builder: (context, state) {
                            bool isAvailable = false;
                            bool isLoading = false;

                            if (state is WorkerAvailabilityLoaded) {
                              isAvailable = state.isAvailable;
                              isLoading = state.isUpdating;
                            } else if (state is WorkerAvailabilityLoading) {
                              isLoading = true;
                            }

                            return AvailabilityToggle(
                              isAvailable: isAvailable,
                              isLoading: isLoading,
                              onToggle: () {
                                context
                                    .read<WorkerAvailabilityBloc>()
                                    .add(const ToggleAvailability());
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Stats Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Aujourd'hui",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        BlocBuilder<WorkerStatsBloc, WorkerStatsState>(
                          builder: (context, state) {
                            if (state is WorkerStatsLoaded) {
                              return StatsRow(
                                completed: state.stats.today.completed,
                                inProgress: state.stats.today.inProgress,
                                earnings: state.stats.today.earnings,
                                rating: state.stats.allTime.averageRating,
                              );
                            }
                            return const StatsRow(
                              completed: 0,
                              inProgress: 0,
                              earnings: 0,
                              rating: 0,
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // My Active Jobs
                        _buildMyJobsSection(),

                        const SizedBox(height: 24),

                        // Available Jobs Section
                        _buildAvailableJobsSection(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.workerEarnings);
        },
        backgroundColor: Colors.green[600],
        icon: const Icon(Icons.attach_money),
        label: const Text('Mes revenus'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMyJobsSection() {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        List<WorkerJob> myJobs = [];

        if (state is WorkerJobsLoaded) {
          myJobs = state.myJobs;
        }

        if (myJobs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.work,
                          color: Colors.purple[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mes jobs actifs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${myJobs.length} actif${myJobs.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...myJobs.map((job) => SwipeableJobCard(
                  job: job,
                  showAcceptButton: false,
                  enableSwipe: false,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pushNamed(
                      context,
                      AppRoutes.workerActiveJob,
                      arguments: job,
                    );
                  },
                )),
          ],
        );
      },
    );
  }

  Widget _buildAvailableJobsSection() {
    return BlocConsumer<WorkerJobsBloc, WorkerJobsState>(
      listener: (context, state) {
        if (state is WorkerJobsLoaded) {
          _checkForNewJobs(state.availableJobs);
        }
        if (state is JobActionSuccess && state.action == 'accept') {
          _notificationService.notifyJobAccepted(state.job);
          HapticFeedback.heavyImpact();
        }
      },
      builder: (context, state) {
        if (state is WorkerJobsLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Recherche de jobs...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is WorkerJobsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadDataWithDefaultLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        List<WorkerJob> availableJobs = [];
        String? loadingJobId;

        if (state is WorkerJobsLoaded) {
          availableJobs = state.availableJobs;
        } else if (state is JobActionLoading) {
          availableJobs = state.previousState.availableJobs;
          loadingJobId = state.jobId;
        }

        // Sort: urgent first, then by departure time
        availableJobs.sort((a, b) {
          if (a.isPriority && !b.isPriority) return -1;
          if (!a.isPriority && b.isPriority) return 1;
          return a.departureTime.compareTo(b.departureTime);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Jobs disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (availableJobs.any((j) => j.isPriority)) ...[
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(
                                  0.7 + (_pulseController.value * 0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bolt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${availableJobs.where((j) => j.isPriority).length} urgent',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  if (availableJobs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${availableJobs.length} job${availableJobs.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (availableJobs.isEmpty)
              _buildEmptyState()
            else
              ...availableJobs.map((job) => SwipeableJobCard(
                    job: job,
                    showAcceptButton: true,
                    enableSwipe: true,
                    isLoading: loadingJobId == job.id,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.workerJobDetails,
                        arguments: job,
                      );
                    },
                    onAccept: () {
                      context.read<WorkerJobsBloc>().add(AcceptJob(job.id));
                    },
                    onDecline: () {
                      // Just dismiss for now, could add to "skipped" list
                      HapticFeedback.lightImpact();
                    },
                  )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Animated waiting icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 0.1,
                  child: Icon(
                    Icons.hourglass_empty,
                    size: 72,
                    color: Colors.grey[400],
                  ),
                );
              },
              onEnd: () {
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 20),
            Text(
              'En attente de jobs...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les nouveaux jobs apparaîtront ici\nautomatiquement',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Actualisation auto. toutes les 15s',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
