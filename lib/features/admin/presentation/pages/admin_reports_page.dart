import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/admin_stats.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AdminBloc>().add(LoadDashboardStats());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports & Statistiques'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Revenus', icon: Icon(Icons.attach_money)),
            Tab(text: 'Activité', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminBloc>().add(LoadDashboardStats()),
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.statsStatus == AdminStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.statsStatus == AdminStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(state.errorMessage ?? 'Une erreur est survenue'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AdminBloc>().add(LoadDashboardStats()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state.stats == null) {
            return const Center(child: Text('Aucune donnée disponible'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRevenueTab(state.stats!),
              _buildActivityTab(state.stats!),
              _buildPerformanceTab(state.stats!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRevenueTab(AdminStats stats) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main revenue card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Revenu Total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(stats.revenue.total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRevenueSubItem(
                      'Ce mois',
                      currencyFormat.format(stats.revenue.thisMonth),
                      Icons.calendar_today,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white30,
                    ),
                    _buildRevenueSubItem(
                      'Commission',
                      currencyFormat.format(stats.revenue.platformFees),
                      Icons.percent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Revenue breakdown
          const Text(
            'Répartition des revenus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRevenueBreakdownCard(stats.revenue),
          const SizedBox(height: 24),

          // Revenue distribution visual
          const Text(
            'Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRevenueDistributionChart(stats.revenue),
          const SizedBox(height: 24),

          // Monthly comparison
          const Text(
            'Comparaison mensuelle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMonthlyComparisonCard(stats.revenue),
        ],
      ),
    );
  }

  Widget _buildRevenueSubItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdownCard(RevenueStats revenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBreakdownRow(
            'Revenus bruts',
            revenue.total,
            Colors.green,
            Icons.trending_up,
          ),
          const Divider(height: 24),
          _buildBreakdownRow(
            'Commission plateforme',
            revenue.platformFees,
            AppTheme.primary,
            Icons.business,
          ),
          const Divider(height: 24),
          _buildBreakdownRow(
            'Paiement déneigeurs',
            revenue.workerPayouts,
            Colors.blue,
            Icons.people,
          ),
          const Divider(height: 24),
          _buildBreakdownRow(
            'Pourboires',
            revenue.tips,
            Colors.amber.shade700,
            Icons.volunteer_activism,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
      String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} \$',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueDistributionChart(RevenueStats revenue) {
    final total = revenue.platformFees + revenue.workerPayouts + revenue.tips;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Pas de données disponibles'),
        ),
      );
    }

    final platformPercent = (revenue.platformFees / total * 100);
    final workerPercent = (revenue.workerPayouts / total * 100);
    final tipsPercent = (revenue.tips / total * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: platformPercent.round(),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                flex: workerPercent.round(),
                child: Container(
                  height: 24,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                flex: tipsPercent.round() > 0 ? tipsPercent.round() : 1,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                'Plateforme',
                '${platformPercent.toStringAsFixed(1)}%',
                AppTheme.primary,
              ),
              _buildLegendItem(
                'Déneigeurs',
                '${workerPercent.toStringAsFixed(1)}%',
                Colors.blue,
              ),
              _buildLegendItem(
                'Pourboires',
                '${tipsPercent.toStringAsFixed(1)}%',
                Colors.amber.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyComparisonCard(RevenueStats revenue) {
    final monthlyCommission = revenue.monthlyPlatformFees;
    final monthlyTotal = revenue.thisMonth;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildComparisonItem(
                  'Revenu ce mois',
                  monthlyTotal,
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildComparisonItem(
                  'Commission ce mois',
                  monthlyCommission,
                  Icons.business,
                  AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
      String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(2)} \$',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(AdminStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  'Total Réservations',
                  stats.reservations.total.toString(),
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'Aujourd\'hui',
                  stats.reservations.today.toString(),
                  Icons.today,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  'Ce mois',
                  stats.reservations.thisMonth.toString(),
                  Icons.date_range,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'En attente',
                  stats.reservations.pending.toString(),
                  Icons.pending,
                  Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status breakdown
          const Text(
            'Répartition par statut',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusBreakdown(stats.reservations),
          const SizedBox(height: 24),

          // User statistics
          const Text(
            'Statistiques utilisateurs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildUserStatsCard(stats.users),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(ReservationStats reservations) {
    final total = reservations.total.toDouble();
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Pas de données disponibles'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatusRow(
            'Terminées',
            reservations.completed,
            total,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'En attente',
            reservations.pending,
            total,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'Annulées',
            reservations.cancelled,
            total,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, double total, Color color) {
    final percent = (count / total * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$count (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatsCard(UserStats users) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildUserStatItem(
                'Total',
                users.total.toString(),
                Icons.people,
                Colors.purple,
              ),
              _buildUserStatItem(
                'Clients',
                users.clients.toString(),
                Icons.person,
                Colors.teal,
              ),
              _buildUserStatItem(
                'Déneigeurs',
                users.workers.toString(),
                Icons.ac_unit,
                Colors.blue,
              ),
              _buildUserStatItem(
                'Actifs',
                users.activeWorkers.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab(AdminStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion rate highlight
          _buildCompletionRateCard(stats.reservations.completionRate),
          const SizedBox(height: 24),

          // Top workers
          const Text(
            'Top Déneigeurs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTopWorkersSection(stats.topWorkers),
          const SizedBox(height: 24),

          // Performance metrics
          const Text(
            'Métriques clés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricsCard(stats),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard(double rate) {
    final color = rate >= 80
        ? Colors.green
        : rate >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed, color: color, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Taux de Complétion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    rate >= 80
                        ? 'Excellent'
                        : rate >= 60
                            ? 'Bon'
                            : 'À améliorer',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopWorkersSection(List<TopWorker> workers) {
    if (workers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Aucun déneigeur pour le moment'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(workers.length, (index) {
          final worker = workers[index];
          final medalColor = index == 0
              ? Colors.amber
              : index == 1
                  ? Colors.grey.shade400
                  : index == 2
                      ? Colors.brown.shade300
                      : Colors.grey.shade300;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: medalColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${worker.jobsCompleted} jobs - ${worker.totalEarnings.toStringAsFixed(0)}\$',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        worker.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMetricsCard(AdminStats stats) {
    final avgRevenuePerReservation = stats.reservations.completed > 0
        ? stats.revenue.total / stats.reservations.completed
        : 0.0;
    final clientToWorkerRatio = stats.users.workers > 0
        ? stats.users.clients / stats.users.workers
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMetricRow(
            'Revenu moyen par réservation',
            '${avgRevenuePerReservation.toStringAsFixed(2)} \$',
            Icons.receipt_long,
            Colors.green,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Ratio clients/déneigeurs',
            '${clientToWorkerRatio.toStringAsFixed(1)}:1',
            Icons.people,
            Colors.blue,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Déneigeurs actifs',
            '${stats.users.activeWorkers}/${stats.users.workers}',
            Icons.work,
            Colors.orange,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Réservations annulées',
            '${stats.reservations.cancelled}',
            Icons.cancel,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
