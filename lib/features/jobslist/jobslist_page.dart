import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/injection_container.dart';
import '../../l10n/app_localizations.dart';
import '../snow_worker/presentation/bloc/worker_jobs_bloc.dart';
import '../snow_worker/domain/entities/worker_job.dart';
import '../../core/utils/money.dart';

class JobsListPage extends StatelessWidget {
  const JobsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WorkerJobsBloc>()
        ..add(const LoadMyJobs())
        ..add(const LoadAvailableJobs(
            latitude: 45.5017, longitude: -73.5673, radiusKm: 50)),
      child: const JobsListView(),
    );
  }
}

class JobsListView extends StatefulWidget {
  const JobsListView({super.key});

  @override
  State<JobsListView> createState() => _JobsListViewState();
}

class _JobsListViewState extends State<JobsListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            _buildTabBar(l10n),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableJobsList(l10n),
                  _buildMyJobsList(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 16),
          Text(
            l10n.worker_jobs,
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              context.read<WorkerJobsBloc>()
                ..add(const LoadMyJobs())
                ..add(const LoadAvailableJobs(
                    latitude: 45.5017, longitude: -73.5673, radiusKm: 50));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.shadowSM,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        labelColor: AppTheme.onPrimary,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: l10n.worker_jobsAvailable),
          Tab(text: l10n.worker_jobsMyJobs),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsList(AppLocalizations l10n) {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        if (state is WorkerJobsLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (state is WorkerJobsLoaded) {
          if (state.availableJobs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.inbox_rounded,
              title: l10n.worker_noJobs,
              subtitle: l10n.worker_noJobsSubtitle,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WorkerJobsBloc>().add(const LoadAvailableJobs(
                  latitude: 45.5017, longitude: -73.5673, radiusKm: 50));
            },
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingLG),
              itemCount: state.availableJobs.length,
              itemBuilder: (context, index) {
                return _buildJobCard(context, state.availableJobs[index],
                    isAvailable: true);
              },
            ),
          );
        }

        if (state is WorkerJobsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text(state.message, style: AppTheme.bodySmall),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<WorkerJobsBloc>().add(const LoadAvailableJobs(
                        latitude: 45.5017, longitude: -73.5673, radiusKm: 50));
                  },
                  child: Text(l10n.common_retry),
                ),
              ],
            ),
          );
        }

        return _buildEmptyState(
          icon: Icons.work_outline_rounded,
          title: l10n.common_loading,
          subtitle: '',
        );
      },
    );
  }

  Widget _buildMyJobsList(AppLocalizations l10n) {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        if (state is WorkerJobsLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (state is WorkerJobsLoaded) {
          if (state.myJobs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.assignment_outlined,
              title: l10n.worker_noAssignedJobs,
              subtitle: l10n.worker_noAssignedSubtitle,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WorkerJobsBloc>().add(const LoadMyJobs());
            },
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingLG),
              itemCount: state.myJobs.length,
              itemBuilder: (context, index) {
                return _buildJobCard(context, state.myJobs[index],
                    isAvailable: false);
              },
            ),
          );
        }

        return _buildEmptyState(
          icon: Icons.work_outline_rounded,
          title: l10n.common_loading,
          subtitle: '',
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(icon, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, WorkerJob job,
      {required bool isAvailable}) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.workerJobDetails,
          arguments: job,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: isAvailable
              ? Border.all(
                  color: AppTheme.success.withValues(alpha: 0.3), width: 1.5)
              : null,
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
                    color: _getStatusColor(job.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    _getStatusIcon(job.status),
                    color: _getStatusColor(job.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${job.vehicle.make} ${job.vehicle.model}',
                        style: AppTheme.labelLarge
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.displayAddress,
                              style: AppTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: _getStatusLabel(job.status, l10n),
                  color: _getStatusColor(job.status),
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildInfoChip(
                  Icons.schedule_rounded,
                  _formatTime(job.departureTime),
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.attach_money_rounded,
                  formatMoney(context, job.workerEarnings, decimals: 0),
                ),
                if (job.vehicle.licensePlate != null) ...[
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.directions_car_outlined,
                    job.vehicle.licensePlate!,
                  ),
                ],
                const Spacer(),
                if (isAvailable)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      l10n.worker_accept,
                      style: TextStyle(
                        color: AppTheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTheme.labelSmall.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getStatusLabel(JobStatus status, AppLocalizations l10n) {
    switch (status) {
      case JobStatus.pending:
        return l10n.reservation_shortPending;
      case JobStatus.assigned:
        return l10n.reservation_shortAssigned;
      case JobStatus.enRoute:
        return l10n.reservation_shortEnRoute;
      case JobStatus.inProgress:
        return l10n.reservation_shortInProgress;
      case JobStatus.completed:
        return l10n.reservation_shortCompleted;
      case JobStatus.cancelled:
        return l10n.reservation_shortCancelled;
    }
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return AppTheme.statusPending;
      case JobStatus.assigned:
        return AppTheme.statusAssigned;
      case JobStatus.enRoute:
        return AppTheme.statusEnRoute;
      case JobStatus.inProgress:
        return AppTheme.statusInProgress;
      case JobStatus.completed:
        return AppTheme.statusCompleted;
      case JobStatus.cancelled:
        return AppTheme.statusCancelled;
    }
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return Icons.pending_rounded;
      case JobStatus.assigned:
        return Icons.assignment_turned_in_rounded;
      case JobStatus.enRoute:
        return Icons.directions_car_rounded;
      case JobStatus.inProgress:
        return Icons.build_rounded;
      case JobStatus.completed:
        return Icons.check_circle_rounded;
      case JobStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}
