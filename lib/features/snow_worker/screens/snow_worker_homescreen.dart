import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../domain/entities/worker_job.dart';
import '../presentation/bloc/worker_availability_bloc.dart';
import '../presentation/bloc/worker_jobs_bloc.dart';
import '../presentation/bloc/worker_stats_bloc.dart';
import '../presentation/widgets/swipeable_job_card.dart';
import '../presentation/widgets/shimmer_loading.dart';
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
  final WorkerNotificationService _notificationService =
      WorkerNotificationService();
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
      final newJobs =
          currentJobs.where((j) => newJobIds.contains(j.id)).toList();
      final hasUrgent = newJobs.any((j) => j.isPriority);

      _notificationService.notifyNewJob(newJobs.first);
      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasUrgent ? Icons.bolt : Icons.work_rounded,
                    color: AppTheme.background,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        newJobs.length == 1
                            ? 'Nouveau job!'
                            : '${newJobs.length} nouveaux jobs!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (newJobs.length == 1)
                        Text(
                          newJobs.first.displayAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.background.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: hasUrgent ? AppTheme.warning : AppTheme.success,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            margin: const EdgeInsets.all(16),
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

      final isEmulatorLocation =
          (position.latitude - 37.4219983).abs() < 0.01 &&
              (position.longitude - (-122.084)).abs() < 0.01;

      if (isEmulatorLocation) {
        _loadDataWithDefaultLocation();
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      _loadData();
    } catch (e) {
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
    context.read<WorkerJobsBloc>().add(const LoadAvailableJobs(
          latitude: 46.3432,
          longitude: -72.5476,
        ));
    context.read<WorkerAvailabilityBloc>().add(const LoadAvailability());
    context.read<WorkerStatsBloc>().add(const LoadStats());
  }

  Future<void> _onRefresh() async {
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final user = authState.user;

            return RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await _onRefresh();
              },
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              strokeWidth: 2.5,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(user.name),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.paddingLG),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Availability Toggle
                        FadeSlideTransition(
                          index: 0,
                          child: _buildAvailabilityCard(),
                        ),
                        const SizedBox(height: 20),

                        // Stats Section
                        FadeSlideTransition(
                          index: 1,
                          child: _buildStatsSection(),
                        ),
                        const SizedBox(height: 24),

                        // My Active Jobs
                        FadeSlideTransition(
                          index: 2,
                          child: _buildMyJobsSection(),
                        ),

                        // Available Jobs
                        FadeSlideTransition(
                          index: 3,
                          child: _buildAvailableJobsSection(),
                        ),

                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          // Avatar
          Hero(
            tag: 'worker_avatar',
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.secondary, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                color: AppTheme.background,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${userName.split(' ').first}',
                  style: AppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                BlocBuilder<WorkerAvailabilityBloc, WorkerAvailabilityState>(
                  builder: (context, state) {
                    bool isAvailable = false;
                    if (state is WorkerAvailabilityLoaded) {
                      isAvailable = state.isAvailable;
                    }
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppTheme.success
                                : AppTheme.textTertiary,
                            shape: BoxShape.circle,
                            boxShadow: isAvailable
                                ? [
                                    BoxShadow(
                                      color: AppTheme.success
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAvailable ? 'Disponible' : 'Hors ligne',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          _buildHeaderButton(
            icon: Icons.history_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.workerHistory),
          ),
          const SizedBox(width: 10),
          _buildHeaderButton(
            icon: Icons.settings_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.workerSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Icon(
          icon,
          color: AppTheme.textSecondary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return BlocBuilder<WorkerAvailabilityBloc, WorkerAvailabilityState>(
      builder: (context, state) {
        bool isAvailable = false;
        bool isLoading = false;

        if (state is WorkerAvailabilityLoaded) {
          isAvailable = state.isAvailable;
          isLoading = state.isUpdating;
        } else if (state is WorkerAvailabilityLoading) {
          isLoading = true;
        }

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  context
                      .read<WorkerAvailabilityBloc>()
                      .add(const ToggleAvailability());
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: isAvailable
                  ? LinearGradient(
                      colors: [
                        AppTheme.success,
                        AppTheme.success.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isAvailable ? null : AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              boxShadow: [
                BoxShadow(
                  color: isAvailable
                      ? AppTheme.success.withValues(alpha: 0.3)
                      : AppTheme.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppTheme.background.withValues(alpha: 0.2)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : Icon(
                          isAvailable
                              ? Icons.work_rounded
                              : Icons.work_off_rounded,
                          color: isAvailable
                              ? AppTheme.background
                              : AppTheme.textTertiary,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable
                            ? 'Vous etes disponible'
                            : 'Vous etes hors ligne',
                        style: TextStyle(
                          color: isAvailable
                              ? AppTheme.background
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAvailable
                            ? 'Vous recevez les nouveaux jobs'
                            : 'Activez pour recevoir des jobs',
                        style: TextStyle(
                          color: isAvailable
                              ? AppTheme.background.withValues(alpha: 0.85)
                              : AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppTheme.background.withValues(alpha: 0.2)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Switch(
                    value: isAvailable,
                    onChanged: isLoading
                        ? null
                        : (_) {
                            HapticFeedback.mediumImpact();
                            context
                                .read<WorkerAvailabilityBloc>()
                                .add(const ToggleAvailability());
                          },
                    activeColor: AppTheme.background,
                    activeTrackColor:
                        AppTheme.background.withValues(alpha: 0.3),
                    inactiveThumbColor: AppTheme.textTertiary,
                    inactiveTrackColor: AppTheme.border,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return BlocBuilder<WorkerStatsBloc, WorkerStatsState>(
      builder: (context, state) {
        if (state is WorkerStatsLoading) {
          return Row(
            children: const [
              Expanded(child: StatCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: StatCardSkeleton()),
            ],
          );
        }

        int completed = 0;
        int inProgress = 0;
        double earnings = 0;
        double rating = 0;

        if (state is WorkerStatsLoaded) {
          completed = state.stats.today.completed;
          inProgress = state.stats.today.inProgress;
          earnings = state.stats.today.earnings;
          rating = state.stats.allTime.averageRating;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Aujourd'hui",
                  style: AppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, AppRoutes.workerEarnings);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppTheme.success,
                    value: completed.toString(),
                    label: 'Termines',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_rounded,
                    iconColor: AppTheme.warning,
                    value: inProgress.toString(),
                    label: 'En cours',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.attach_money_rounded,
                    iconColor: AppTheme.primary,
                    value: '${earnings.toStringAsFixed(0)}\$',
                    label: 'Revenus',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFFB800),
                    value: rating > 0 ? rating.toStringAsFixed(1) : '-',
                    label: 'Note',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.15),
                  iconColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.secondary.withValues(alpha: 0.15),
                            AppTheme.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: const Icon(
                        Icons.work_rounded,
                        color: AppTheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mes jobs actifs',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.secondary, AppTheme.primary],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '${myJobs.length} actif${myJobs.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppTheme.background,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...myJobs.map((job) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SwipeableJobCard(
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
                  ),
                )),
            const SizedBox(height: 10),
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jobs disponibles',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const JobCardSkeleton(),
              const SizedBox(height: 12),
              const JobCardSkeleton(),
            ],
          );
        }

        if (state is WorkerJobsError) {
          return _buildErrorState(state.message);
        }

        List<WorkerJob> availableJobs = [];
        String? loadingJobId;

        if (state is WorkerJobsLoaded) {
          availableJobs = state.availableJobs;
        } else if (state is JobActionLoading) {
          availableJobs = state.previousState.availableJobs;
          loadingJobId = state.jobId;
        }

        availableJobs.sort((a, b) {
          if (a.isPriority && !b.isPriority) return -1;
          if (!a.isPriority && b.isPriority) return 1;
          return a.departureTime.compareTo(b.departureTime);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Jobs disponibles',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (availableJobs.any((j) => j.isPriority)) ...[
                      const SizedBox(width: 10),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.warning,
                                  AppTheme.warning.withValues(
                                    alpha: 0.7 + (_pulseController.value * 0.3),
                                  ),
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.warning.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: AppTheme.background,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${availableJobs.where((j) => j.isPriority).length} urgent',
                                  style: TextStyle(
                                    color: AppTheme.background,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '${availableJobs.length} job${availableJobs.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppTheme.info,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (availableJobs.isEmpty)
              _buildEmptyState()
            else
              ...availableJobs.map((job) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SwipeableJobCard(
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
                        HapticFeedback.lightImpact();
                      },
                    ),
                  )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 0.1,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.1),
                        AppTheme.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    size: 40,
                    color: AppTheme.primary,
                  ),
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
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouveaux jobs apparaitront ici\nautomatiquement',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: AppTheme.info, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Actualisation auto. toutes les 15s',
                  style: TextStyle(
                    color: AppTheme.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Oups!',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _loadDataWithDefaultLocation();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded,
                      color: AppTheme.background, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Reessayer',
                    style: TextStyle(
                      color: AppTheme.background,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, AppRoutes.workerEarnings);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.success,
              AppTheme.success.withValues(alpha: 0.85),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppTheme.success.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                color: AppTheme.background, size: 20),
            SizedBox(width: 10),
            Text(
              'Mes revenus',
              style: TextStyle(
                color: AppTheme.background,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
