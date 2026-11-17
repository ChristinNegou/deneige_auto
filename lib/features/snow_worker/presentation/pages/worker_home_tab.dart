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
                    color: AppTheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasUrgent ? Icons.bolt : Icons.work_rounded,
                    color: AppTheme.onPrimary,
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
                            color: AppTheme.onPrimary.withValues(alpha: 0.9),
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildAvailabilityCard(),
                        const SizedBox(height: 12),
                        _buildQuickStats(),
                        const SizedBox(height: 28),
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
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
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
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onPrimary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onPrimary,
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
                  style: AppTheme.headlineMedium,
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
                          style: AppTheme.bodySmall,
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
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.textPrimary,
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
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getWeatherIcon(state.weather!.condition),
                  size: 18,
                  color: AppTheme.primary2,
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
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: color.withValues(alpha: 0.25)),
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

  /// Interrupteur de service : panneau bleu nuit en service, carte blanche hors ligne.
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

        final onDark = isAvailable;
        final titleColor = onDark ? AppTheme.onPrimary : AppTheme.textPrimary;
        final subtitleColor = onDark
            ? AppTheme.onPrimary.withValues(alpha: 0.7)
            : AppTheme.textSecondary;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: onDark ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: onDark ? null : Border.all(color: AppTheme.border),
            boxShadow: onDark ? AppTheme.shadowLG : AppTheme.shadowSM,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      context
                          .read<WorkerAvailabilityBloc>()
                          .add(const ToggleAvailability());
                    },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? AppTheme.success
                                      : AppTheme.textTertiary,
                                  shape: BoxShape.circle,
                                  boxShadow: isAvailable
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.success
                                                .withValues(alpha: 0.6),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isAvailable
                                      ? l10n.worker_youAreAvailable
                                      : l10n.worker_youAreOffline,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAvailable
                                ? l10n.worker_receivingJobs
                                : l10n.worker_activateToReceive,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onDark
                                  ? AppTheme.onPrimary
                                  : AppTheme.textTertiary,
                            ),
                          )
                        : _buildCustomSwitch(isAvailable),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomSwitch(bool value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 56,
      height: 32,
      decoration: BoxDecoration(
        color: value ? AppTheme.success : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: value ? null : Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppTheme.shadowSM,
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

        return GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    value: completed.toString(),
                    label: l10n.worker_jobsCompleted,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _buildMiniStatCard(
                    value: '${earnings.toStringAsFixed(0)} \$',
                    label: l10n.worker_todayLabel,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _buildMiniStatCard(
                    value: rating > 0 ? rating.toStringAsFixed(1) : '–',
                    label: l10n.worker_ratingLabel,
                    icon: rating > 0 ? Icons.star_rounded : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStatCard({
    required String value,
    required String label,
    IconData? icon,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppTheme.warning),
              const SizedBox(width: 2),
            ],
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.4,
                color: AppTheme.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.labelSmall,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
                Text(l10n.worker_myActiveJobs, style: AppTheme.headlineMedium),
                StatusBadge(
                  label: l10n.worker_activeCount(myJobs.length),
                  color: AppTheme.statusInProgress,
                  small: true,
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
                  Text(l10n.worker_availableJobs,
                      style: AppTheme.headlineMedium),
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
                        Text(l10n.worker_availableJobs,
                            style: AppTheme.headlineMedium),
                        if (availableJobs.any((j) => j.isPriority)) ...[
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: l10n.worker_urgentCount(availableJobs
                                .where((j) => j.isPriority)
                                .length),
                            color: AppTheme.accent,
                            icon: Icons.bolt_rounded,
                            small: true,
                          ),
                        ],
                      ],
                    ),
                    if (availableJobs.isNotEmpty)
                      Text(
                        l10n.worker_jobCount(availableJobs.length),
                        style: AppTheme.bodySmall,
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

  /// Carte d'etat de la section des travaux : icone, titre, message, action.
  Widget _buildStateCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    List<Widget> extra = const [],
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall,
          ),
          ...extra,
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onAction();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(180, 44),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoEquipmentWarning() {
    final l10n = AppLocalizations.of(context)!;
    return _buildStateCard(
      icon: Icons.handyman_outlined,
      color: AppTheme.warning,
      title: l10n.worker_configureEquipment,
      message: l10n.worker_configureEquipmentMessage,
      actionLabel: l10n.worker_configure,
      onAction: () => WorkerMainDashboard.switchToTab(
        context,
        WorkerMainDashboard.profileTab,
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

        return _buildStateCard(
          icon: Icons.ac_unit_rounded,
          color: AppTheme.primary2,
          title: l10n.worker_waitingForJobs,
          message: l10n.worker_waitingSubtitle,
          extra: [
            if (hasLimitedEquipment) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.worker_addMoreEquipment,
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(l10n.worker_autoRefresh, style: AppTheme.labelSmall),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    final l10n = AppLocalizations.of(context)!;
    return _buildStateCard(
      icon: Icons.cloud_off_rounded,
      color: AppTheme.error,
      title: l10n.worker_oops,
      message: message,
      actionLabel: l10n.worker_retryLabel,
      onAction: _loadDataWithDefaultLocation,
    );
  }

  Widget _buildVerificationRequiredState() {
    final l10n = AppLocalizations.of(context)!;
    return _buildStateCard(
      icon: Icons.verified_user_outlined,
      color: AppTheme.warning,
      title: l10n.worker_verificationRequired,
      message: l10n.worker_verificationRequiredForJobs,
      actionLabel: l10n.worker_verify,
      onAction: () =>
          Navigator.of(context).pushNamed(AppRoutes.identityVerification),
    );
  }
}
