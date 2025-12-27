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

class _SnowWorkerDashboardView extends StatelessWidget {
  const _SnowWorkerDashboardView();

  @override
  Widget build(BuildContext context) {
    // Configurer la barre de statut
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<WorkerJobsBloc>().add(const LoadMyJobs());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primary,
          child: CustomScrollView(
            slivers: [
              // Header compact
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              // Contenu
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.paddingLG),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsSection(context),
                    const SizedBox(height: 20),
                    _buildCurrentJobSection(context),
                    const SizedBox(height: 20),
                    _buildQuickActions(context),
                    const SizedBox(height: 100),
                  ]),
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
          // Avatar
          Container(
            width: 44,
            height: 44,
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
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String name = 'Déneigeur';
                    if (state is AuthAuthenticated) {
                      name = state.user.firstName ?? 'Déneigeur';
                    }
                    return Text(
                      'Bonjour, $name',
                      style: AppTheme.headlineSmall,
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  'Prêt à travailler ?',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          _buildStatusBadge(context),
          const SizedBox(width: 8),
          // Notifications
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
              j.status == JobStatus.enRoute
            );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isWorking
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.textTertiary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isWorking ? AppTheme.success : AppTheme.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isWorking ? 'En service' : 'Disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isWorking ? AppTheme.success : AppTheme.textTertiary,
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
      onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: AppTheme.shadowSM,
        ),
        child: const Icon(
          Icons.notifications_outlined,
          color: AppTheme.textSecondary,
          size: 20,
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
          todayJobs = state.myJobs.where((j) =>
            j.departureTime.day == today.day &&
            j.departureTime.month == today.month &&
            j.departureTime.year == today.year
          ).length;
          completedJobs = state.myJobs.where((j) => j.status == JobStatus.completed).length;
          pendingJobs = state.myJobs.where((j) =>
            j.status == JobStatus.pending || j.status == JobStatus.assigned
          ).length;
          earnings = state.myJobs
              .where((j) => j.status == JobStatus.completed)
              .fold(0.0, (sum, j) => sum + j.totalPrice);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.today_rounded,
                    iconColor: AppTheme.primary,
                    label: 'Aujourd\'hui',
                    value: '$todayJobs',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.attach_money_rounded,
                    iconColor: AppTheme.success,
                    label: 'Revenus',
                    value: '${earnings.toStringAsFixed(0)}\$',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppTheme.secondary,
                    label: 'Complétés',
                    value: '$completedJobs',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_rounded,
                    iconColor: AppTheme.warning,
                    label: 'En attente',
                    value: '$pendingJobs',
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
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Row(
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
                Text(
                  label,
                  style: AppTheme.labelSmall,
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
          final activeJob = state.myJobs.where((j) =>
            j.status == JobStatus.inProgress ||
            j.status == JobStatus.enRoute ||
            j.status == JobStatus.assigned
          ).toList();

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
                      style: AppTheme.headlineSmall,
                    ),
                    StatusBadge(
                      label: _getStatusLabel(job.status),
                      color: _getStatusColor(job.status),
                      icon: _getStatusIcon(job.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.workerJobDetails,
                      arguments: job.id,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(job.status),
                          _getStatusColor(job.status).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(job.status).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                job.vehicle.licensePlate ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${job.vehicle.make} ${job.vehicle.model}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.displayAddress,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildJobInfoChip(
                              Icons.schedule_rounded,
                              _formatTime(job.departureTime),
                            ),
                            const SizedBox(width: 8),
                            _buildJobInfoChip(
                              Icons.attach_money_rounded,
                              '${job.totalPrice.toStringAsFixed(0)}\$',
                            ),
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

        // Pas de job en cours
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: AppTheme.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Icon(
                  Icons.inbox_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun job en cours',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Consultez la liste des jobs disponibles',
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.jobsList);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                  ),
                  child: const Text(
                    'Voir les jobs',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
          style: AppTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          icon: Icons.list_alt_rounded,
          iconColor: AppTheme.primary,
          title: 'Tous les jobs',
          subtitle: 'Jobs disponibles et assignés',
          onTap: () => Navigator.pushNamed(context, AppRoutes.jobsList),
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          context,
          icon: Icons.history_rounded,
          iconColor: AppTheme.success,
          title: 'Historique',
          subtitle: 'Jobs complétés',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Fonctionnalité à venir'),
                backgroundColor: AppTheme.textSecondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          context,
          icon: Icons.calendar_month_rounded,
          iconColor: AppTheme.secondary,
          title: 'Mon planning',
          subtitle: 'Voir mon emploi du temps',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Fonctionnalité à venir'),
                backgroundColor: AppTheme.textSecondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          context,
          icon: Icons.person_outline_rounded,
          iconColor: AppTheme.warning,
          title: 'Mon profil',
          subtitle: 'Paramètres et informations',
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 20,
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
        return 'Assigné';
      case JobStatus.enRoute:
        return 'En route';
      case JobStatus.inProgress:
        return 'En cours';
      case JobStatus.completed:
        return 'Terminé';
      case JobStatus.pending:
        return 'En attente';
      case JobStatus.cancelled:
        return 'Annulé';
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
