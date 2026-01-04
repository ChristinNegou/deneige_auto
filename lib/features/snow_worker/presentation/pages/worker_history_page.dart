import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/worker_job.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../widgets/shimmer_loading.dart';

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

class _WorkerHistoryViewState extends State<_WorkerHistoryView>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();
  late AnimationController _filterAnimController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _filterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterAnimController.dispose();
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
                    return _buildSkeletonList();
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
                        HapticFeedback.mediumImpact();
                        context
                            .read<WorkerJobsBloc>()
                            .add(const LoadJobHistory());
                      },
                      color: AppTheme.primary,
                      backgroundColor: AppTheme.surface,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppTheme.paddingLG),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: jobs.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= jobs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }
                          return FadeSlideTransition(
                            index: index,
                            delay: const Duration(milliseconds: 30),
                            child: _buildHistoryCard(jobs[index]),
                          );
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHistoryCardSkeleton(),
        );
      },
    );
  }

  Widget _buildHistoryCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerLoading(width: 120, height: 14, borderRadius: 4),
              ShimmerLoading(width: 70, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const ShimmerLoading(width: 44, height: 44, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLoading(width: 140, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerLoading(width: 180, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerLoading(width: 100, height: 14, borderRadius: 4),
              ShimmerLoading(width: 80, height: 20, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
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
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique',
                  style: AppTheme.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Vos jobs termines',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<WorkerJobsBloc>().add(const LoadJobHistory());
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primary,
                size: 22,
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
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip('all', 'Tous', Icons.list_alt_rounded),
            const SizedBox(width: 10),
            _buildFilterChip('week', 'Cette semaine', Icons.date_range_rounded),
            const SizedBox(width: 10),
            _buildFilterChip('month', 'Ce mois', Icons.calendar_month_rounded),
            const SizedBox(width: 10),
            _buildFilterChip(
                'tips', 'Avec pourboire', Icons.volunteer_activism_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppTheme.shadowSM,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WorkerJob> _filterJobs(List<WorkerJob> jobs) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return jobs
            .where(
                (j) => j.completedAt != null && j.completedAt!.isAfter(weekAgo))
            .toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return jobs
            .where((j) =>
                j.completedAt != null && j.completedAt!.isAfter(monthAgo))
            .toList();
      case 'tips':
        return jobs
            .where((j) => j.tipAmount != null && j.tipAmount! > 0)
            .toList();
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 48,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun job dans l\'historique',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos jobs termines apparaitront ici',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'Retourner au dashboard',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oups!',
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.read<WorkerJobsBloc>().add(const LoadJobHistory());
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                  children: const [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Reessayer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(WorkerJob job) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'fr_FR');
    final hasTip = job.tipAmount != null && job.tipAmount! > 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Optionnellement naviguer vers les details
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: hasTip
              ? Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and status
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLG),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        job.completedAt != null
                            ? dateFormat.format(job.completedAt!)
                            : 'Date inconnue',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.success,
                          AppTheme.success.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Termine',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client info
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.15),
                              AppTheme.secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        child: Center(
                          child: Text(
                            job.client.firstName[0].toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.client.fullName,
                              style: AppTheme.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
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
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Vehicle & Duration
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_rounded,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            job.vehicle.displayName,
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (job.durationMinutes != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_rounded,
                                  size: 14,
                                  color: AppTheme.info,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${job.durationMinutes} min',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Revenus',
                        style: AppTheme.labelMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${job.totalPrice.toStringAsFixed(2)} \$',
                            style: AppTheme.headlineSmall.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasTip) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.warning,
                                    AppTheme.warning.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.warning
                                        .withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${job.tipAmount!.toStringAsFixed(2)} \$',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // Rating if available
                  if (job.rating != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Evaluation client:',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(5, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                index < job.rating!
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppTheme.warning,
                                size: 20,
                              ),
                            );
                          }),
                          const Spacer(),
                          Text(
                            '${job.rating}/5',
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
