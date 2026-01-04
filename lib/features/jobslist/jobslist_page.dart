import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/injection_container.dart';
import '../snow_worker/presentation/bloc/worker_jobs_bloc.dart';
import '../snow_worker/domain/entities/worker_job.dart';

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableJobsList(),
                  _buildMyJobsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.shadowSM,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Jobs',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              context.read<WorkerJobsBloc>()
                ..add(const LoadMyJobs())
                ..add(const LoadAvailableJobs(
                    latitude: 45.5017, longitude: -73.5673, radiusKm: 50));
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Disponibles'),
          Tab(text: 'Mes jobs'),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsList() {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        if (state is WorkerJobsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (state is WorkerJobsLoaded) {
          if (state.availableJobs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.inbox_rounded,
              title: 'Aucun job disponible',
              subtitle: 'Les nouveaux jobs apparaîtront ici',
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
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        return _buildEmptyState(
          icon: Icons.work_outline_rounded,
          title: 'Chargement...',
          subtitle: '',
        );
      },
    );
  }

  Widget _buildMyJobsList() {
    return BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
      builder: (context, state) {
        if (state is WorkerJobsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (state is WorkerJobsLoaded) {
          if (state.myJobs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Aucun job assigné',
              subtitle: 'Acceptez des jobs disponibles pour les voir ici',
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
          title: 'Chargement...',
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
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.workerJobDetails,
          arguments: job.id,
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
                  label: _getStatusLabel(job.status),
                  color: _getStatusColor(job.status),
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.divider),
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
                  '${job.totalPrice.toStringAsFixed(0)}\$',
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
                    child: const Text(
                      'Accepter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Icon(
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

  String _getStatusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'En attente';
      case JobStatus.assigned:
        return 'Assigné';
      case JobStatus.enRoute:
        return 'En route';
      case JobStatus.inProgress:
        return 'En cours';
      case JobStatus.completed:
        return 'Terminé';
      case JobStatus.cancelled:
        return 'Annulé';
    }
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return AppTheme.warning;
      case JobStatus.assigned:
        return AppTheme.primary;
      case JobStatus.enRoute:
        return AppTheme.secondary;
      case JobStatus.inProgress:
        return AppTheme.success;
      case JobStatus.completed:
        return const Color(0xFF059669);
      case JobStatus.cancelled:
        return AppTheme.textTertiary;
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
