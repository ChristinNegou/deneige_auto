import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildFilterChips(l10n),
            Expanded(
              child: BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
                builder: (context, state) {
                  if (state is WorkerJobsLoading) {
                    return _buildSkeletonList();
                  }

                  if (state is WorkerJobsError) {
                    return _buildErrorState(state.message, l10n);
                  }

                  if (state is JobHistoryLoaded) {
                    final jobs = _filterJobs(state.jobs);

                    if (jobs.isEmpty) {
                      return _buildEmptyState(l10n);
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
                            child: _buildHistoryCard(jobs[index], l10n),
                          );
                        },
                      ),
                    );
                  }

                  return _buildEmptyState(l10n);
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.worker_history, style: AppTheme.headlineMedium),
                Text(l10n.worker_yourCompletedJobs, style: AppTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<WorkerJobsBloc>().add(const LoadJobHistory());
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip(
                'all', l10n.worker_filterAll, Icons.list_alt_rounded),
            const SizedBox(width: 10),
            _buildFilterChip(
                'week', l10n.worker_filterThisWeek, Icons.date_range_rounded),
            const SizedBox(width: 10),
            _buildFilterChip('month', l10n.worker_filterThisMonth,
                Icons.calendar_month_rounded),
            const SizedBox(width: 10),
            _buildFilterChip('tips', l10n.worker_filterWithTip,
                Icons.volunteer_activism_rounded),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.onPrimary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.onPrimary : AppTheme.textPrimary,
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIllustration(
            type: IllustrationType.emptyWorkerHistory,
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.worker_noHistory,
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.worker_completedJobsAppearHere,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(minimumSize: const Size(200, 44)),
            child: Text(l10n.worker_returnToDashboard),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.worker_oops,
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
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<WorkerJobsBloc>().add(const LoadJobHistory());
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(WorkerJob job, AppLocalizations l10n) {
    final dateFormat = DateFormat(
        'd MMM yyyy, HH:mm',
        Localizations.localeOf(context).languageCode == 'en'
            ? 'en_CA'
            : 'fr_CA');
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
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and status
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                            : l10n.worker_dateUnknown,
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(
                    label: l10n.worker_completedStatus,
                    color: AppTheme.statusCompleted,
                    small: true,
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
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            job.client.firstName[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
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
                              style: AppTheme.headlineSmall,
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
                          Icons.directions_car_filled_outlined,
                          size: 18,
                          color: AppTheme.textSecondary,
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
                              color: AppTheme.surface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${job.durationMinutes} min',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
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
                        l10n.worker_revenueLabel,
                        style: AppTheme.labelMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${job.totalPrice.toStringAsFixed(2)} \$',
                            style: AppTheme.headlineMedium.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          if (hasTip) ...[
                            const SizedBox(width: 10),
                            StatusBadge(
                              label: '+${job.tipAmount!.toStringAsFixed(2)} \$',
                              color: AppTheme.success,
                              icon: Icons.favorite_rounded,
                              small: true,
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
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Row(
                        children: [
                          Text(
                            l10n.worker_clientRating,
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
