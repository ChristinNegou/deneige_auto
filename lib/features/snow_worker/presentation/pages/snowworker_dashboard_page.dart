import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../../domain/entities/worker_job.dart';
import '../../../../core/di/injection_container.dart';
import '../widgets/shimmer_loading.dart';

class SnowWorkerDashboardPage extends StatelessWidget {
  const SnowWorkerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WorkerJobsBloc>()..add(const LoadMyJobs()),
      child: const _SnowWorkerDashboardView(),
    );
  }
}

class _SnowWorkerDashboardView extends StatefulWidget {
  const _SnowWorkerDashboardView();

  @override
  State<_SnowWorkerDashboardView> createState() =>
      _SnowWorkerDashboardViewState();
}

class _SnowWorkerDashboardViewState extends State<_SnowWorkerDashboardView>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    _refreshController.repeat();

    context.read<WorkerJobsBloc>().add(const LoadMyJobs());
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      _refreshController.stop();
      _refreshController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          strokeWidth: 2.5,
          displacement: 60,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.paddingLG),
                sliver: BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
                  builder: (context, state) {
                    if (state is WorkerJobsLoading) {
                      return const SliverToBoxAdapter(
                        child: DashboardSkeleton(),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        FadeSlideTransition(
                          index: 0,
                          child: _buildStatsSection(context),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideTransition(
                          index: 1,
                          child: _buildCurrentJobSection(context),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideTransition(
                          index: 2,
                          child: _buildQuickActions(context),
                        ),
                        const SizedBox(height: 100),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          // Avatar avec animation
          Hero(
            tag: 'worker_avatar',
            child: Container(
              width: 48,
              height: 48,
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
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String name = 'Deneigeur';
                    if (state is AuthAuthenticated) {
                      name = state.user.firstName ?? 'Deneigeur';
                    }
                    return Text(
                      'Bonjour, $name',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pret a travailler',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusBadge(context),
          const SizedBox(width: 10),
          _buildNotificationButton(context),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        final bool isWorking = state is WorkerJobsLoaded &&
            state.myJobs.any((j) =>
                j.status == JobStatus.inProgress ||
                j.status == JobStatus.enRoute);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isWorking
                ? LinearGradient(
                    colors: [
                      AppTheme.success,
                      AppTheme.success.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: isWorking ? null : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow: [
              BoxShadow(
                color: isWorking
                    ? AppTheme.success.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseAnimation(
                animate: isWorking,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isWorking ? AppTheme.background : AppTheme.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isWorking ? 'En service' : 'Disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isWorking ? AppTheme.background : AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, AppRoutes.notifications);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.notifications_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
            // Badge de notification (optionnel)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        int todayJobs = 0;
        int completedJobs = 0;
        int pendingJobs = 0;
        double earnings = 0;

        if (state is WorkerJobsLoaded) {
          final today = DateTime.now();
          todayJobs = state.myJobs
              .where((j) =>
                  j.departureTime.day == today.day &&
                  j.departureTime.month == today.month &&
                  j.departureTime.year == today.year)
              .length;
          completedJobs =
              state.myJobs.where((j) => j.status == JobStatus.completed).length;
          pendingJobs = state.myJobs
              .where((j) =>
                  j.status == JobStatus.pending ||
                  j.status == JobStatus.assigned)
              .length;
          earnings = state.myJobs
              .where((j) => j.status == JobStatus.completed)
              .fold(0.0, (sum, j) => sum + j.totalPrice);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Statistiques',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.textPrimary,
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
                          'Voir tout',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedStatCard(
                    icon: Icons.today_rounded,
                    iconColor: AppTheme.primary,
                    label: 'Aujourd\'hui',
                    value: todayJobs.toDouble(),
                    suffix: '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnimatedStatCard(
                    icon: Icons.attach_money_rounded,
                    iconColor: AppTheme.success,
                    label: 'Revenus',
                    value: earnings,
                    suffix: '\$',
                    isMonetary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedStatCard(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppTheme.secondary,
                    label: 'Completes',
                    value: completedJobs.toDouble(),
                    suffix: '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnimatedStatCard(
                    icon: Icons.pending_rounded,
                    iconColor: AppTheme.warning,
                    label: 'En attente',
                    value: pendingJobs.toDouble(),
                    suffix: '',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double value,
    required String suffix,
    bool isMonetary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: AppTheme.border.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: iconColor.withValues(alpha: 0.1),
          width: 1,
        ),
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
                AnimatedCounter(
                  value: value,
                  suffix: suffix,
                  decimals: isMonetary ? 0 : 0,
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

  Widget _buildCurrentJobSection(BuildContext context) {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        if (state is WorkerJobsLoaded) {
          final activeJob = state.myJobs
              .where((j) =>
                  j.status == JobStatus.inProgress ||
                  j.status == JobStatus.enRoute ||
                  j.status == JobStatus.assigned)
              .toList();

          if (activeJob.isNotEmpty) {
            final job = activeJob.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Job en cours',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _buildAnimatedStatusBadge(job.status),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (job.status == JobStatus.assigned ||
                        job.status == JobStatus.enRoute ||
                        job.status == JobStatus.inProgress) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.workerActiveJob,
                        arguments: job,
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.workerJobDetails,
                        arguments: job,
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(job.status),
                          _getStatusColor(job.status).withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(job.status)
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimary.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                job.vehicle.licensePlate ?? 'N/A',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimary.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSM),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: AppTheme.textPrimary,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${job.vehicle.make} ${job.vehicle.model}',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: AppTheme.textPrimary.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                job.displayAddress,
                                style: TextStyle(
                                  color: AppTheme.textPrimary.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildJobInfoChip(
                              Icons.schedule_rounded,
                              _formatTime(job.departureTime),
                            ),
                            const SizedBox(width: 10),
                            _buildJobInfoChip(
                              Icons.attach_money_rounded,
                              '${job.totalPrice.toStringAsFixed(0)}\$',
                            ),
                            if (job.distanceKm != null) ...[
                              const SizedBox(width: 10),
                              _buildJobInfoChip(
                                Icons.directions_car_rounded,
                                '${job.distanceKm!.toStringAsFixed(1)} km',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }

        // Pas de job en cours - design ameliore
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: AppTheme.border,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.border.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryLight,
                      AppTheme.primaryLight.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Icon(
                  Icons.inbox_rounded,
                  color: AppTheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun job en cours',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Consultez la liste des jobs disponibles',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pushNamed(context, AppRoutes.jobsList);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded, color: AppTheme.background, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Voir les jobs disponibles',
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
      },
    );
  }

  Widget _buildAnimatedStatusBadge(JobStatus status) {
    final color = _getStatusColor(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseAnimation(
            animate:
                status == JobStatus.inProgress || status == JobStatus.enRoute,
            child: Icon(_getStatusIcon(status), color: color, size: 14),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textPrimary, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _buildActionTile(
          context,
          icon: Icons.list_alt_rounded,
          iconGradient: [AppTheme.primary, AppTheme.secondary],
          title: 'Tous les jobs',
          subtitle: 'Jobs disponibles et assignes',
          onTap: () => Navigator.pushNamed(context, AppRoutes.jobsList),
          index: 0,
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          context,
          icon: Icons.history_rounded,
          iconGradient: [AppTheme.success, const Color(0xFF059669)],
          title: 'Historique',
          subtitle: 'Jobs completes',
          onTap: () => Navigator.pushNamed(context, AppRoutes.workerHistory),
          index: 1,
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          context,
          icon: Icons.account_balance_wallet_rounded,
          iconGradient: [AppTheme.warning, const Color(0xFFFF9500)],
          title: 'Mes revenus',
          subtitle: 'Statistiques et paiements',
          onTap: () => Navigator.pushNamed(context, AppRoutes.workerEarnings),
          index: 2,
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          context,
          icon: Icons.settings_rounded,
          iconGradient: [AppTheme.textSecondary, AppTheme.textTertiary],
          title: 'Parametres',
          subtitle: 'Compte et preferences',
          onTap: () => Navigator.pushNamed(context, AppRoutes.workerSettings),
          index: 3,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: [
            BoxShadow(
              color: AppTheme.border.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconGradient[0].withValues(alpha: 0.15),
                    iconGradient[1].withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(icon, color: iconGradient[0], size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getStatusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Assigne';
      case JobStatus.enRoute:
        return 'En route';
      case JobStatus.inProgress:
        return 'En cours';
      case JobStatus.completed:
        return 'Termine';
      case JobStatus.pending:
        return 'En attente';
      case JobStatus.cancelled:
        return 'Annule';
    }
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return AppTheme.primary;
      case JobStatus.enRoute:
        return AppTheme.secondary;
      case JobStatus.inProgress:
        return AppTheme.success;
      case JobStatus.completed:
        return const Color(0xFF059669);
      case JobStatus.pending:
        return AppTheme.warning;
      case JobStatus.cancelled:
        return AppTheme.textTertiary;
    }
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return Icons.assignment_turned_in_rounded;
      case JobStatus.enRoute:
        return Icons.directions_car_rounded;
      case JobStatus.inProgress:
        return Icons.build_rounded;
      case JobStatus.completed:
        return Icons.check_circle_rounded;
      case JobStatus.pending:
        return Icons.pending_rounded;
      case JobStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}
