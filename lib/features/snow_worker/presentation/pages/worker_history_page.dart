import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/worker_job.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../../../../core/di/injection_container.dart';

class WorkerHistoryPage extends StatelessWidget {
  const WorkerHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WorkerJobsBloc>()..add(const LoadJobHistory()),
      child: const _WorkerHistoryView(),
    );
  }
}

class _WorkerHistoryView extends StatefulWidget {
  const _WorkerHistoryView();

  @override
  State<_WorkerHistoryView> createState() => _WorkerHistoryViewState();
}

class _WorkerHistoryViewState extends State<_WorkerHistoryView> {
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<WorkerJobsBloc>().add(const LoadMoreHistory());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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
            _buildHeader(),
            _buildFilterChips(),
            Expanded(
              child: BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
                builder: (context, state) {
                  if (state is WorkerJobsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  if (state is WorkerJobsError) {
                    return _buildErrorState(state.message);
                  }

                  if (state is JobHistoryLoaded) {
                    final jobs = _filterJobs(state.jobs);

                    if (jobs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<WorkerJobsBloc>().add(const LoadJobHistory());
                      },
                      color: AppTheme.primary,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppTheme.paddingLG),
                        itemCount: jobs.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= jobs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: AppTheme.primary),
                              ),
                            );
                          }
                          return _buildHistoryCard(jobs[index]);
                        },
                      ),
                    );
                  }

                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            'Historique',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              context.read<WorkerJobsBloc>().add(const LoadJobHistory());
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Tous'),
            const SizedBox(width: 8),
            _buildFilterChip('week', 'Cette semaine'),
            const SizedBox(width: 8),
            _buildFilterChip('month', 'Ce mois'),
            const SizedBox(width: 8),
            _buildFilterChip('tips', 'Avec pourboire'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  List<WorkerJob> _filterJobs(List<WorkerJob> jobs) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return jobs.where((j) =>
          j.completedAt != null && j.completedAt!.isAfter(weekAgo)
        ).toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return jobs.where((j) =>
          j.completedAt != null && j.completedAt!.isAfter(monthAgo)
        ).toList();
      case 'tips':
        return jobs.where((j) => j.tipAmount != null && j.tipAmount! > 0).toList();
      default:
        return jobs;
    }
  }

  Widget _buildEmptyState() {
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
            child: const Icon(Icons.history_rounded, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text('Aucun job dans l\'historique', style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Vos jobs terminés apparaîtront ici', style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<WorkerJobsBloc>().add(const LoadJobHistory());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(WorkerJob job) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'fr_FR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.completedAt != null
                    ? dateFormat.format(job.completedAt!)
                    : 'Date inconnue',
                style: AppTheme.labelSmall,
              ),
              StatusBadge(
                label: 'Terminé',
                color: AppTheme.success,
                icon: Icons.check_circle_rounded,
                small: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Client info
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Center(
                  child: Text(
                    job.client.firstName[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.client.fullName,
                      style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.displayAddress,
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppTheme.divider),

          // Vehicle & Duration
          Row(
            children: [
              Icon(Icons.directions_car_rounded, size: 16, color: AppTheme.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job.vehicle.displayName,
                  style: AppTheme.bodySmall,
                ),
              ),
              if (job.durationMinutes != null) ...[
                Icon(Icons.timer_rounded, size: 16, color: AppTheme.info),
                const SizedBox(width: 4),
                Text(
                  '${job.durationMinutes} min',
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.info),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Revenus', style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Text(
                    '${job.totalPrice.toStringAsFixed(2)} \$',
                    style: AppTheme.headlineSmall.copyWith(color: AppTheme.success),
                  ),
                  if (job.tipAmount != null && job.tipAmount! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '+${job.tipAmount!.toStringAsFixed(2)} \$ tip',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Rating if available
          if (job.rating != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Évaluation: ', style: AppTheme.labelSmall),
                ...List.generate(5, (index) {
                  return Icon(
                    index < job.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppTheme.warning,
                    size: 18,
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
