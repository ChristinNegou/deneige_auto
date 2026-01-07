import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/worker_stats_bloc.dart';
import '../../domain/entities/worker_stats.dart';
import '../../../../core/di/injection_container.dart';

class WorkerEarningsPage extends StatelessWidget {
  const WorkerEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WorkerStatsBloc>()
        ..add(const LoadStats())
        ..add(const LoadEarnings()),
      child: const _WorkerEarningsView(),
    );
  }
}

class _WorkerEarningsView extends StatefulWidget {
  const _WorkerEarningsView();

  @override
  State<_WorkerEarningsView> createState() => _WorkerEarningsViewState();
}

class _WorkerEarningsViewState extends State<_WorkerEarningsView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _countAnimation;
  late ConfettiController _confettiController;
  bool _hasShownConfetti = false;

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
    _animationController.forward();
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
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
                          child: CircularProgressIndicator(
                              color: AppTheme.primary),
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
            // Confetti overlay
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
            'Mes revenus',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              context.read<WorkerStatsBloc>().add(const LoadStats());
              context.read<WorkerStatsBloc>().add(const LoadEarnings());
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.success,
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
          color: AppTheme.success,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        labelColor: AppTheme.background,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppTheme.background.withValues(alpha: 0),
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
            onPressed: () {
              context.read<WorkerStatsBloc>().add(const LoadStats());
              context.read<WorkerStatsBloc>().add(const LoadEarnings());
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
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
          ),
          const SizedBox(height: 20),
          _buildTodayStatsGrid(stats.today),
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
  }) {
    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        final animatedAmount = amount * _countAnimation.value;
        final animatedTips = tips * _countAnimation.value;
        final animatedJobs = (jobsCount * _countAnimation.value).round();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.success, Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              if (title == "Aujourd'hui") ...[
                _buildDailyGoalProgress(animatedAmount),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.background.withValues(alpha: 0.9),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animatedAmount.toStringAsFixed(2),
                    style: TextStyle(
                      color: AppTheme.background,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      ' \$',
                      style: TextStyle(
                        color: AppTheme.background.withValues(alpha: 0.7),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Jobs',
                      value: animatedJobs.toString(),
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: AppTheme.background.withValues(alpha: 0.3),
                    ),
                    _buildSummaryItem(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Pourboires',
                      value: '${animatedTips.toStringAsFixed(0)} \$',
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: AppTheme.background.withValues(alpha: 0.3),
                    ),
                    _buildSummaryItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Moyenne',
                      value: jobsCount > 0
                          ? '${(amount / jobsCount).toStringAsFixed(0)} \$'
                          : '0 \$',
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

  Widget _buildDailyGoalProgress(double currentAmount) {
    const double dailyGoal = 100.0;
    final progress = (currentAmount / dailyGoal).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Objectif: ${dailyGoal.toInt()}\$',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.background.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppTheme.warning : AppTheme.background,
            ),
            minHeight: 6,
          ),
        ),
        if (progress >= 1.0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: AppTheme.warning, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Objectif atteint!',
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
        Icon(icon, color: AppTheme.background, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.background,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.background.withValues(alpha: 0.8),
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
            title: 'Terminés',
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
            title: 'Assignés',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenus par jour', style: AppTheme.headlineSmall),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final earning = index < earnings.daily.length
                    ? earnings.daily[index].total
                    : 0.0;
                final height =
                    maxHeight > 0 ? (earning / maxHeight) * 120 : 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (earning > 0)
                      Text(
                        '${earning.toInt()}\$',
                        style: AppTheme.labelSmall.copyWith(fontSize: 10),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height.clamp(4.0, 120.0),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(days[index], style: AppTheme.labelSmall),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Statistiques globales', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySmall),
          Text(value,
              style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
