import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../bloc/worker_stats_bloc.dart';
import '../../domain/entities/worker_stats.dart';

class WorkerEarningsTab extends StatefulWidget {
  const WorkerEarningsTab({super.key});

  @override
  State<WorkerEarningsTab> createState() => _WorkerEarningsTabState();
}

class _WorkerEarningsTabState extends State<WorkerEarningsTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _countAnimation;
  late ConfettiController _confettiController;
  bool _hasShownConfetti = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _countAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _animationController.forward();
    });
  }

  void _loadData() {
    context.read<WorkerStatsBloc>().add(const LoadStats());
    context.read<WorkerStatsBloc>().add(const LoadEarnings());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _checkMilestone(double todayEarnings) {
    if (!_hasShownConfetti && todayEarnings >= 50 && todayEarnings % 50 < 10) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
      _hasShownConfetti = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: BlocBuilder<WorkerStatsBloc, WorkerStatsState>(
                  builder: (context, state) {
                    if (state is WorkerStatsLoading) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.primary),
                      );
                    }

                    if (state is WorkerStatsError) {
                      return _buildErrorState(state.message);
                    }

                    if (state is WorkerStatsLoaded) {
                      _checkMilestone(state.stats.today.earnings);
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDayTab(state.stats, state.earnings),
                          _buildWeekTab(state.stats, state.earnings),
                          _buildMonthTab(state.stats, state.earnings),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppTheme.success,
                AppTheme.primary,
                AppTheme.warning,
                AppTheme.secondary,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      child: Row(
        children: [
          Text(l10n.earnings_myEarnings, style: AppTheme.headlineLarge),
          const Spacer(),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadData();
              _animationController.reset();
              _animationController.forward();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          boxShadow: AppTheme.shadowSM,
        ),
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textTertiary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: l10n.earnings_day),
          Tab(text: l10n.earnings_week),
          Tab(text: l10n.earnings_month),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 40, color: AppTheme.textTertiary),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadData,
            style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.earnings_retry),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: AppLocalizations.of(context)!.earnings_today,
            amount: stats.today.earnings,
            jobsCount: stats.today.completed,
            tips: stats.today.tips,
            showGoal: true,
          ),
          const SizedBox(height: 12),
          _buildTodayStatsGrid(stats.today),
          const SizedBox(height: 20),
          _buildHistoryButton(),
        ],
      ),
    );
  }

  Widget _buildWeekTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: AppLocalizations.of(context)!.earnings_thisWeek,
            amount: stats.week.earnings,
            jobsCount: stats.week.completed,
            tips: stats.week.tips,
          ),
          const SizedBox(height: 12),
          _buildPeriodStatsRow(stats.week),
          const SizedBox(height: 20),
          if (earnings != null) _buildWeeklyChart(earnings),
        ],
      ),
    );
  }

  Widget _buildMonthTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: AppLocalizations.of(context)!.earnings_thisMonth,
            amount: stats.month.earnings,
            jobsCount: stats.month.completed,
            tips: stats.month.tips,
          ),
          const SizedBox(height: 12),
          _buildPeriodStatsRow(stats.month),
          const SizedBox(height: 20),
          _buildAllTimeStats(stats.allTime),
        ],
      ),
    );
  }

  Widget _buildEarningsSummaryCard({
    required String title,
    required double amount,
    required int jobsCount,
    required double tips,
    bool showGoal = false,
  }) {
    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        final l10n = AppLocalizations.of(context)!;
        final animatedAmount = amount * _countAnimation.value;
        final animatedTips = tips * _countAnimation.value;
        final animatedJobs = (jobsCount * _countAnimation.value).round();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: AppTheme.shadowLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showGoal) ...[
                _buildDailyGoalProgress(animatedAmount),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.onPrimary.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    animatedAmount.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppTheme.onPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      ' \$',
                      style: TextStyle(
                        color: AppTheme.onPrimary.withValues(alpha: 0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: l10n.earnings_jobs,
                      value: animatedJobs.toString(),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: AppTheme.onPrimary.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.volunteer_activism_rounded,
                      label: l10n.earnings_tips,
                      value: '${animatedTips.toStringAsFixed(0)} \$',
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: AppTheme.onPrimary.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.trending_up_rounded,
                      label: l10n.earnings_average,
                      value: jobsCount > 0
                          ? '${(amount / jobsCount).toStringAsFixed(0)} \$'
                          : '0 \$',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyGoalProgress(double currentAmount) {
    final l10n = AppLocalizations.of(context)!;
    const double dailyGoal = 100.0;
    final progress = (currentAmount / dailyGoal).clamp(0.0, 1.0);
    final reached = progress >= 1.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              reached
                  ? l10n.earnings_goalReached
                  : l10n.earnings_goalAmount(dailyGoal.toInt()),
              style: TextStyle(
                color: AppTheme.onPrimary.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).toInt()} %',
              style: const TextStyle(
                color: AppTheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.onPrimary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
              reached ? AppTheme.success : AppTheme.accent,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.onPrimary.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatsGrid(TodayStats stats) {
    final l10n = AppLocalizations.of(context)!;
    return _buildStatsCard([
      (l10n.earnings_completed, stats.completed.toString()),
      (l10n.earnings_inProgress, stats.inProgress.toString()),
      (l10n.earnings_assigned, stats.assigned.toString()),
    ]);
  }

  Widget _buildPeriodStatsRow(PeriodStats stats) {
    final l10n = AppLocalizations.of(context)!;
    return _buildStatsCard([
      (l10n.earnings_jobs, stats.completed.toString()),
      (l10n.earnings_earnings, '${stats.earnings.toStringAsFixed(0)} \$'),
      (l10n.earnings_tipsShort, '${stats.tips.toStringAsFixed(0)} \$'),
    ]);
  }

  Widget _buildStatsCard(List<(String, String)> items) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      items[i].$2,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppTheme.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$1,
                      style: AppTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, AppRoutes.workerHistory);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded,
                color: AppTheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.earnings_jobHistory, style: AppTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    l10n.earnings_viewAllJobs,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(EarningsBreakdown earnings) {
    if (earnings.daily.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final days = [
      l10n.earnings_dayMon,
      l10n.earnings_dayTue,
      l10n.earnings_dayWed,
      l10n.earnings_dayThu,
      l10n.earnings_dayFri,
      l10n.earnings_daySat,
      l10n.earnings_daySun
    ];
    final maxEarning =
        earnings.daily.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    final maxHeight = maxEarning > 0 ? maxEarning : 100.0;

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
          Text(l10n.earnings_earningsPerDay, style: AppTheme.headlineSmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final earning = index < earnings.daily.length
                    ? earnings.daily[index].total
                    : 0.0;
                final height =
                    maxHeight > 0 ? (earning / maxHeight) * 100 : 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (earning > 0)
                      Text(
                        '${earning.toInt()}\$',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: height.clamp(4.0, 100.0),
                      decoration: BoxDecoration(
                        color: earning == maxEarning && earning > 0
                            ? AppTheme.accent
                            : AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeStats(AllTimeStats allTime) {
    final l10n = AppLocalizations.of(context)!;
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
          Text(l10n.earnings_overallStats, style: AppTheme.headlineSmall),
          const SizedBox(height: 14),
          _buildAllTimeRow(
              l10n.earnings_totalJobs, allTime.completed.toString()),
          _buildAllTimeRow(l10n.earnings_totalEarnings,
              '${allTime.earnings.toStringAsFixed(2)} \$'),
          _buildAllTimeRow(
              l10n.earnings_totalTips, '${allTime.tips.toStringAsFixed(2)} \$'),
          _buildAllTimeRow(
            l10n.earnings_averageRating,
            allTime.averageRating > 0
                ? '${allTime.averageRating.toStringAsFixed(1)} ★ (${allTime.totalRatings})'
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
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
}
