import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
                                color: AppTheme.background,
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.background,
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.background,
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
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.shadowSM,
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
              boxShadow: AppTheme.shadowSM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getWeatherIcon(state.weather!.condition),
                  size: 18,
                  color: AppTheme.primary,
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
            title = 'Verification en cours';
            subtitle =
                'Vos documents sont en cours d\'analyse. Vous serez notifie une fois la verification terminee.';
            break;
          case 'rejected':
            icon = Icons.cancel_outlined;
            color = AppTheme.error;
            title = 'Verification refusee';
            subtitle = rejectionReason ??
                'Vos documents n\'ont pas ete approuves. Veuillez resoumettre des documents valides.';
            showButton = true;
            break;
          case 'expired':
            icon = Icons.timer_off_outlined;
            color = AppTheme.warning;
            title = 'Verification expiree';
            subtitle =
                'Votre verification a expire. Veuillez resoumettre vos documents.';
            showButton = true;
            break;
          default: // not_submitted
            icon = Icons.verified_user_outlined;
            color = AppTheme.primary;
            title = 'Verification requise';
            subtitle =
                'Verifiez votre identite pour pouvoir accepter des jobs de deneigement.';
            showButton = true;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: showButton
                  ? () => Navigator.pushNamed(
                      context, AppRoutes.identityVerification)
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Text(
                          status == 'not_submitted'
                              ? 'Verifier'
                              : 'Resoumettre',
                          style: const TextStyle(
                            color: AppTheme.background,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
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
                    activeThumbColor: AppTheme.background,
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

  Widget _buildQuickStats() {
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
                label: 'Jobs termines',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                icon: Icons.attach_money_rounded,
                iconColor: AppTheme.primary,
                value: '${earnings.toStringAsFixed(0)}\$',
                label: "Aujourd'hui",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStatCard(
                icon: Icons.star_rounded,
                iconColor: AppTheme.warning,
                value: rating > 0 ? rating.toStringAsFixed(1) : '-',
                label: 'Note',
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
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
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
                    gradient: const LinearGradient(
                      colors: [AppTheme.secondary, AppTheme.primary],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '${myJobs.length} actif${myJobs.length > 1 ? 's' : ''}',
                    style: const TextStyle(
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
                                        alpha: 0.7 +
                                            (_pulseController.value * 0.3),
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.warning
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bolt,
                                      color: AppTheme.background,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${availableJobs.where((j) => j.isPriority).length} urgent',
                                      style: const TextStyle(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: const Icon(
              Icons.build_rounded,
              size: 36,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Configurez votre équipement',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Pour voir les jobs disponibles, vous devez d\'abord indiquer les équipements que vous possédez dans "Mon équipement".',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les jobs sont filtrés selon votre équipement.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              // Basculer vers l'onglet Profil (index 3)
              WorkerMainDashboard.switchToTab(
                context,
                WorkerMainDashboard.profileTab,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.warning, Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warning.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.build_rounded,
                    color: AppTheme.background,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Configurer mon équipement',
                    style: TextStyle(
                      color: AppTheme.background,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  Widget _buildEmptyState() {
    return BlocBuilder<WorkerAvailabilityBloc, WorkerAvailabilityState>(
      builder: (context, state) {
        // Determiner le nombre d'equipements coches
        int equipmentCount = 0;
        if (state is WorkerAvailabilityLoaded && state.profile != null) {
          equipmentCount = state.profile!.equipmentList.length;
        }

        // Message contextuel selon l'equipement (afficher si 1-3 equipements)
        final bool hasLimitedEquipment =
            equipmentCount > 0 && equipmentCount < 4;

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Container(
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
              // Message contextuel si equipement limite
              if (hasLimitedEquipment) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border:
                        Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: AppTheme.info,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Astuce pour plus de jobs',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vous avez $equipmentCount equipement${equipmentCount > 1 ? 's' : ''} coche${equipmentCount > 1 ? 's' : ''}. Plus vous cochez d\'equipements, plus vous recevrez de jobs.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          WorkerMainDashboard.switchToTab(
                            context,
                            WorkerMainDashboard.profileTab,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.info,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.build_rounded,
                                color: AppTheme.background,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ajouter des equipements',
                                style: TextStyle(
                                  color: AppTheme.background,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border:
                      Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
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
      },
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
              child: const Row(
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

  Widget _buildVerificationRequiredState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 36,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vérification requise',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vous devez faire vérifier votre identité avant de pouvoir voir et accepter des jobs de déneigement.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pushNamed(AppRoutes.identityVerification);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: AppTheme.background, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Vérifier mon identité',
                    style: TextStyle(
                      color: AppTheme.background,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
}
