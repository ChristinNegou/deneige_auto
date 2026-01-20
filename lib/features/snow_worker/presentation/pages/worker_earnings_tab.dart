import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const Text(
            'Mes revenus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _loadData();
              _animationController.reset();
              _animationController.forward();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppTheme.textSecondary,
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textTertiary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Jour'),
          Tab(text: 'Semaine'),
          Tab(text: 'Mois'),
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
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: "Aujourd'hui",
            amount: stats.today.earnings,
            jobsCount: stats.today.completed,
            tips: stats.today.tips,
            showGoal: true,
          ),
          const SizedBox(height: 20),
          _buildTodayStatsGrid(stats.today),
          const SizedBox(height: 20),
          _buildHistoryButton(),
        ],
      ),
    );
  }

  Widget _buildWeekTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: 'Cette semaine',
            amount: stats.week.earnings,
            jobsCount: stats.week.completed,
            tips: stats.week.tips,
          ),
          const SizedBox(height: 20),
          _buildPeriodStatsRow(stats.week),
          const SizedBox(height: 20),
          if (earnings != null) _buildWeeklyChart(earnings),
        ],
      ),
    );
  }

  Widget _buildMonthTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: 'Ce mois',
            amount: stats.month.earnings,
            jobsCount: stats.month.completed,
            tips: stats.month.tips,
          ),
          const SizedBox(height: 20),
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
        final animatedAmount = amount * _countAnimation.value;
        final animatedTips = tips * _countAnimation.value;
        final animatedJobs = (jobsCount * _countAnimation.value).round();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              if (showGoal) ...[
                _buildDailyGoalProgress(animatedAmount),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    animatedAmount.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      ' \$',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Jobs',
                      value: animatedJobs.toString(),
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppTheme.border,
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Pourboires',
                      value: '${animatedTips.toStringAsFixed(0)} \$',
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppTheme.border,
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Moyenne',
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
    const double dailyGoal = 100.0;
    final progress = (currentAmount / dailyGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Objectif: ${dailyGoal.toInt()}\$',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color:
                      progress >= 1.0 ? AppTheme.success : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.success : AppTheme.textPrimary,
              ),
              minHeight: 5,
            ),
          ),
          if (progress >= 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Objectif atteint!',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatsGrid(TodayStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Termines',
            value: stats.completed.toString(),
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'En cours',
            value: stats.inProgress.toString(),
            icon: Icons.engineering_rounded,
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Assignes',
            value: stats.assigned.toString(),
            icon: Icons.assignment_rounded,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodStatsRow(PeriodStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Jobs',
            value: stats.completed.toString(),
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Revenus',
            value: '${stats.earnings.toStringAsFixed(0)}\$',
            icon: Icons.attach_money_rounded,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Tips',
            value: '${stats.tips.toStringAsFixed(0)}\$',
            icon: Icons.volunteer_activism_rounded,
            color: AppTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, AppRoutes.workerHistory);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.history_rounded,
                color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historique des jobs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Voir tous vos jobs termines',
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

    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final maxEarning =
        earnings.daily.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    final maxHeight = maxEarning > 0 ? maxEarning : 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenus par jour',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
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
                        color: AppTheme.textPrimary.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques globales',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildAllTimeRow('Total jobs', allTime.completed.toString()),
          _buildAllTimeRow(
              'Revenus totaux', '${allTime.earnings.toStringAsFixed(2)} \$'),
          _buildAllTimeRow(
              'Pourboires totaux', '${allTime.tips.toStringAsFixed(2)} \$'),
          _buildAllTimeRow(
            'Note moyenne',
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
