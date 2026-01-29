import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../verification/presentation/bloc/verification_bloc.dart';
import '../../../verification/presentation/bloc/verification_event.dart';
import '../../../verification/presentation/bloc/verification_state.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../domain/entities/worker_job.dart';
import '../bloc/worker_availability_bloc.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../bloc/worker_stats_bloc.dart';
import '../widgets/swipeable_job_card.dart';
import '../widgets/shimmer_loading.dart';
import '../../services/worker_notification_service.dart';
import 'worker_main_dashboard.dart';

class WorkerHomeTab extends StatefulWidget {
  const WorkerHomeTab({super.key});

  @override
  State<WorkerHomeTab> createState() => _WorkerHomeTabState();
}

class _WorkerHomeTabState extends State<WorkerHomeTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Position? _currentPosition;
  Timer? _refreshTimer;
  final WorkerNotificationService _notificationService =
      WorkerNotificationService();
  Set<String> _previousJobIds = {};
  late AnimationController _pulseController;
  bool _isFirstLoad = true;
  late VerificationBloc _verificationBloc;

  static const Duration _refreshInterval = Duration(seconds: 15);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _verificationBloc = sl<VerificationBloc>();
    _verificationBloc.add(const LoadVerificationStatus());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initializeLocation();
    _startAutoRefresh();
    // Load weather data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(LoadHomeData());
      }
    });
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

      final l10nNotif = mounted ? AppLocalizations.of(context) : null;
      _notificationService.notifyNewJob(newJobs.first, l10n: l10nNotif);
      HapticFeedback.heavyImpact();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
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
                            ? l10n.worker_newJob
                            : l10n.worker_newJobs(newJobs.length),
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
    super.build(context);

    return SafeArea(
      child: BlocListener<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        listener: (context, state) {
          // Quand le profil est mis à jour, recharger les données
          if (state is WorkerProfileUpdated) {
            // Recharger l'availability pour mettre à jour l'UI avec le nouveau profil
            context
                .read<WorkerAvailabilityBloc>()
                .add(const LoadAvailability());
          }
        },
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
                  SliverToBoxAdapter(
                    child: _buildHeader(user.name),
                  ),
                  SliverToBoxAdapter(
                    child: _buildVerificationBanner(),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.paddingLG),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildAvailabilityCard(),
                        const SizedBox(height: 20),
                        _buildQuickStats(),
                        const SizedBox(height: 24),
                        _buildMyJobsSection(),
                        _buildAvailableJobsSection(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Avatar avec photo de profil
          BlocBuilder<WorkerAvailabilityBloc, WorkerAvailabilityState>(
            builder: (context, workerState) {
              String? photoUrl;
              if (workerState is WorkerAvailabilityLoaded) {
                photoUrl = workerState.profile?.photoUrl;
              }

              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppTheme.border, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          width: 52,
                          height: 52,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.textTertiary,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'D',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.worker_greetingName(userName.split(' ').first),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
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
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAvailable
                              ? l10n.worker_headerAvailable
                              : l10n.worker_headerOffline,
                          style: TextStyle(
                            fontSize: 13,
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
          // Weather badge
          _buildWeatherBadge(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherBadge() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (!state.isLoading && state.weather != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getWeatherIcon(state.weather!.condition),
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${state.weather!.temperature.round()}°',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('snow') || lower.contains('neige')) {
      return Icons.ac_unit;
    } else if (lower.contains('rain') || lower.contains('pluie')) {
      return Icons.water_drop;
    } else if (lower.contains('cloud') || lower.contains('nuag')) {
      return Icons.cloud;
    } else if (lower.contains('sun') ||
        lower.contains('clear') ||
        lower.contains('soleil')) {
      return Icons.wb_sunny;
    }
    return Icons.wb_cloudy;
  }

  Widget _buildVerificationBanner() {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<VerificationBloc, VerificationState>(
      bloc: _verificationBloc,
      builder: (context, state) {
        // Ne rien afficher si en chargement ou si verification deja approuvee
        if (state is VerificationLoading || state is VerificationInitial) {
          return const SizedBox.shrink();
        }

        String? status;
        String? rejectionReason;

        if (state is VerificationStatusLoaded) {
          status = state.status.status.name;
          rejectionReason = state.status.decision?.reason;
        }

        // Si approuve, ne rien afficher
        if (status == 'approved') {
          return const SizedBox.shrink();
        }

        // Determiner le contenu de la banniere selon le statut
        IconData icon;
        Color color;
        String title;
        String subtitle;
        bool showButton = false;

        switch (status) {
          case 'pending':
            icon = Icons.hourglass_empty;
            color = AppTheme.warning;
            title = l10n.worker_verificationOngoing;
            subtitle = l10n.worker_verificationOngoingSubtitle;
            break;
          case 'rejected':
            icon = Icons.cancel_outlined;
            color = AppTheme.error;
            title = l10n.worker_verificationRejected;
            subtitle =
                rejectionReason ?? l10n.worker_verificationRejectedSubtitle;
            showButton = true;
            break;
          case 'expired':
            icon = Icons.timer_off_outlined;
            color = AppTheme.warning;
            title = l10n.worker_verificationExpired;
            subtitle = l10n.worker_verificationExpiredSubtitle;
            showButton = true;
            break;
          default: // not_submitted
            icon = Icons.verified_user_outlined;
            color = AppTheme.primary;
            title = l10n.worker_verificationRequired;
            subtitle = l10n.worker_verificationRequiredSubtitle;
            showButton = true;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: showButton
                  ? () => Navigator.pushNamed(
                      context, AppRoutes.identityVerification)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (showButton) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppTheme.textTertiary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailabilityCard() {
    final l10n = AppLocalizations.of(context)!;
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAvailable ? AppTheme.success : AppTheme.border,
                width: isAvailable ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: isLoading
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ),
                        )
                      : Opacity(
                          opacity: 0.9,
                          child: AppIllustration(
                            type: isAvailable
                                ? IllustrationType.workerAvailable
                                : IllustrationType.workerOffline,
                            width: 52,
                            height: 52,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable
                            ? l10n.worker_youAreAvailable
                            : l10n.worker_youAreOffline,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAvailable
                            ? l10n.worker_receivingJobs
                            : l10n.worker_activateToReceive,
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCustomSwitch(isAvailable),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomSwitch(bool value) {
    return Container(
      width: 48,
      height: 26,
      decoration: BoxDecoration(
        color: value ? AppTheme.success : AppTheme.background,
        borderRadius: BorderRadius.circular(13),
        border: value ? null : Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: value ? Colors.white : AppTheme.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final l10n = AppLocalizations.of(context)!;
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
        double earnings = 0;
        double rating = 0;

        if (state is WorkerStatsLoaded) {
          completed = state.stats.today.completed;
          earnings = state.stats.today.earnings;
          rating = state.stats.allTime.averageRating;
        }

        return Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                icon: Icons.check_circle_rounded,
                iconColor: AppTheme.success,
                value: completed.toString(),
                label: l10n.worker_jobsCompleted,
                illustrationType: IllustrationType.statJobsCompleted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStatCard(
                icon: Icons.attach_money_rounded,
                iconColor: AppTheme.primary,
                value: '${earnings.toStringAsFixed(0)}\$',
                label: l10n.worker_todayLabel,
                illustrationType: IllustrationType.statEarnings,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStatCard(
                icon: Icons.star_rounded,
                iconColor: AppTheme.warning,
                value: rating > 0 ? rating.toStringAsFixed(1) : '-',
                label: l10n.worker_ratingLabel,
                illustrationType: IllustrationType.statRating,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    IllustrationType? illustrationType,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          if (illustrationType != null)
            Opacity(
              opacity: 0.9,
              child: AppIllustration(
                type: illustrationType,
                width: 36,
                height: 36,
              ),
            )
          else
            Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMyJobsSection() {
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  l10n.worker_myActiveJobs,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.worker_activeCount(myJobs.length),
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<WorkerAvailabilityBloc, WorkerAvailabilityState>(
      builder: (context, availabilityState) {
        // Vérifier si l'équipement est configuré
        List<String> equipmentList = [];
        if (availabilityState is WorkerAvailabilityLoaded) {
          equipmentList = availabilityState.profile?.equipmentList ?? [];
        }
        final hasEquipment = equipmentList.isNotEmpty;

        return BlocConsumer<WorkerJobsBloc, WorkerJobsState>(
          listener: (context, state) {
            if (state is WorkerJobsLoaded) {
              _checkForNewJobs(state.availableJobs);
            }
            if (state is JobActionSuccess && state.action == 'accept') {
              _notificationService.notifyJobAccepted(state.job,
                  l10n: AppLocalizations.of(context));
              HapticFeedback.heavyImpact();
            }
          },
          builder: (context, state) {
            if (state is WorkerJobsLoading) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.worker_availableJobs,
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

            if (state is VerificationRequired) {
              return _buildVerificationRequiredState();
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
                          l10n.worker_availableJobs,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (availableJobs.any((j) => j.isPriority)) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: AppTheme.warning,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  l10n.worker_urgentCount(availableJobs
                                      .where((j) => j.isPriority)
                                      .length),
                                  style: TextStyle(
                                    color: AppTheme.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (availableJobs.isNotEmpty)
                      Text(
                        l10n.worker_jobCount(availableJobs.length),
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Afficher un message si aucun équipement n'est configuré
                if (!hasEquipment)
                  _buildNoEquipmentWarning()
                else if (availableJobs.isEmpty)
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
                            context
                                .read<WorkerJobsBloc>()
                                .add(AcceptJob(job.id));
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
      },
    );
  }

  Widget _buildNoEquipmentWarning() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.build_rounded,
            size: 32,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.worker_configureEquipment,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.worker_configureEquipmentMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              WorkerMainDashboard.switchToTab(
                context,
                WorkerMainDashboard.profileTab,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.worker_configure,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<WorkerAvailabilityBloc, WorkerAvailabilityState>(
      builder: (context, state) {
        int equipmentCount = 0;
        if (state is WorkerAvailabilityLoaded && state.profile != null) {
          equipmentCount = state.profile!.equipmentList.length;
        }

        final bool hasLimitedEquipment =
            equipmentCount > 0 && equipmentCount < 4;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Opacity(
                opacity: 0.85,
                child: AppIllustration(
                  type: IllustrationType.emptyWorkerJobs,
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.worker_waitingForJobs,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.worker_waitingSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
              if (hasLimitedEquipment) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.worker_addMoreEquipment,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                l10n.worker_autoRefresh,
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: AppTheme.error,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.worker_oops,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _loadDataWithDefaultLocation();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.worker_retryLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRequiredState() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 32,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.worker_verificationRequired,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.worker_verificationRequiredForJobs,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pushNamed(AppRoutes.identityVerification);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.worker_verify,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
