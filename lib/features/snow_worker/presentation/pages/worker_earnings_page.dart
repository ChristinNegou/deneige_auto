import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';

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
    // Show confetti for milestone earnings (every $50)
    if (!_hasShownConfetti && todayEarnings >= 50 && todayEarnings % 50 < 10) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
      _hasShownConfetti = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes revenus'),
        backgroundColor: Colors.green[600],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Jour'),
            Tab(text: 'Semaine'),
            Tab(text: 'Mois'),
          ],
        ),
      ),
      body: Stack(
        children: [
          BlocBuilder<WorkerStatsBloc, WorkerStatsState>(
            builder: (context, state) {
              if (state is WorkerStatsLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        'Chargement des statistiques...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (state is WorkerStatsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<WorkerStatsBloc>().add(const LoadStats());
                          context.read<WorkerStatsBloc>().add(const LoadEarnings());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
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
                Colors.green,
                Colors.greenAccent,
                Colors.lightGreen,
                Colors.yellow,
                Colors.amber,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: "Aujourd'hui",
            amount: stats.today.earnings,
            jobsCount: stats.today.completed,
            tips: stats.today.tips,
          ),
          const SizedBox(height: 24),
          _buildTodayStatsGrid(stats.today),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWeekTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: 'Cette semaine',
            amount: stats.week.earnings,
            jobsCount: stats.week.completed,
            tips: stats.week.tips,
          ),
          const SizedBox(height: 24),
          _buildPeriodStatsRow(stats.week),
          const SizedBox(height: 24),
          if (earnings != null) _buildWeeklyChart(earnings),
        ],
      ),
    );
  }

  Widget _buildMonthTab(WorkerStats stats, EarningsBreakdown? earnings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsSummaryCard(
            title: 'Ce mois',
            amount: stats.month.earnings,
            jobsCount: stats.month.completed,
            tips: stats.month.tips,
          ),
          const SizedBox(height: 24),
          _buildPeriodStatsRow(stats.month),
          const SizedBox(height: 24),
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
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.green[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Daily goal progress indicator
              if (title == "Aujourd'hui") ...[
                _buildDailyGoalProgress(animatedAmount),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      ' \$',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.check_circle_outline,
                      label: 'Jobs',
                      value: animatedJobs.toString(),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSummaryItem(
                      icon: Icons.favorite_outline,
                      label: 'Pourboires',
                      value: '${animatedTips.toStringAsFixed(0)} \$',
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSummaryItem(
                      icon: Icons.trending_up,
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
    const double dailyGoal = 100.0; // Objectif journalier par défaut
    final progress = (currentAmount / dailyGoal).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Objectif: ${dailyGoal.toInt()}\$',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
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
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.amber : Colors.white,
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
                Icon(Icons.emoji_events, color: Colors.amber[300], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Objectif atteint!',
                  style: TextStyle(
                    color: Colors.amber[300],
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
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
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
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'En cours',
            value: stats.inProgress.toString(),
            icon: Icons.engineering,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Assignés',
            value: stats.assigned.toString(),
            icon: Icons.assignment,
            color: Colors.blue,
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
            title: 'Jobs terminés',
            value: stats.completed.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Revenus',
            value: '${stats.earnings.toStringAsFixed(0)}\$',
            icon: Icons.attach_money,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Pourboires',
            value: '${stats.tips.toStringAsFixed(0)}\$',
            icon: Icons.volunteer_activism,
            color: Colors.amber,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(EarningsBreakdown earnings) {
    if (earnings.daily.isEmpty) return const SizedBox.shrink();

    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final maxEarning = earnings.daily.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    final maxHeight = maxEarning > 0 ? maxEarning : 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenus par jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
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
                final height = maxHeight > 0 ? (earning / maxHeight) * 120 : 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (earning > 0)
                      Text(
                        '${earning.toInt()}\$',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height.clamp(4.0, 120.0),
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques globales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildAllTimeRow('Total jobs', allTime.completed.toString()),
          _buildAllTimeRow('Revenus totaux', '${allTime.earnings.toStringAsFixed(2)} \$'),
          _buildAllTimeRow('Pourboires totaux', '${allTime.tips.toStringAsFixed(2)} \$'),
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
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
