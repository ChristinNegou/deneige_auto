import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/stripe_reconciliation.dart';
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
    // Charger automatiquement les données Stripe
    context.read<AdminBloc>().add(LoadStripeReconciliation());
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
            onPressed: () =>
                context.read<AdminBloc>().add(LoadDashboardStats()),
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
                  Icon(Icons.error_outline, size: 64, color: AppTheme.error),
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
              _buildRevenueTab(state.stats!, state),
              _buildActivityTab(state.stats!),
              _buildPerformanceTab(state.stats!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRevenueTab(AdminStats stats, AdminState state) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final reconciliation = state.reconciliation;
    final isLoadingStripe = state.reconciliationStatus == AdminStatus.loading;

    // Utiliser les données Stripe si disponibles, sinon local
    final stripeRevenue = reconciliation?.stripe.chargesTotal ?? 0.0;
    final stripeTransfers = reconciliation?.stripe.transfersTotal ?? 0.0;
    final stripeFees = reconciliation?.stripe.feesTotal ?? 0.0;
    final stripeRefunds = reconciliation?.stripe.refundsTotal ?? 0.0;
    final stripeNetRevenue = stripeRevenue - stripeRefunds;
    final platformCommission = stripeRevenue > 0
        ? stripeRevenue - stripeTransfers - stripeFees
        : stats.revenue.platformFeesNet;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main revenue card - STRIPE DATA
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary2,
                  AppTheme.primary2.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: AppTheme.background.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Revenus Stripe',
                      style: TextStyle(
                        color: AppTheme.background.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoadingStripe)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(
                      color: AppTheme.background,
                    ),
                  )
                else if (reconciliation != null)
                  Column(
                    children: [
                      Text(
                        currencyFormat.format(stripeNetRevenue),
                        style: TextStyle(
                          color: AppTheme.background,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(30 derniers jours)',
                        style: TextStyle(
                          color: AppTheme.background.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Chargement...',
                    style: TextStyle(
                      color: AppTheme.background.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                const SizedBox(height: 16),
                if (reconciliation != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRevenueSubItem(
                        'Commission',
                        currencyFormat.format(platformCommission),
                        Icons.business,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.background.withValues(alpha: 0.3),
                      ),
                      _buildRevenueSubItem(
                        'Frais Stripe',
                        currencyFormat.format(stripeFees),
                        Icons.credit_card,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stripe Balance Card
          if (reconciliation?.stripe.balance != null)
            _buildStripeBalanceCard(reconciliation!.stripe.balance!),
          const SizedBox(height: 24),

          // Stripe Revenue breakdown
          if (reconciliation != null) ...[
            const Text(
              'Détails Stripe (30 jours)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStripeBreakdownCard(reconciliation),
            const SizedBox(height: 24),
          ],

          // Comparaison avec données locales
          const Text(
            'Comparaison Local vs Stripe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (reconciliation != null)
            _buildComparisonCard(
                reconciliation, reconciliation.hasDiscrepancies)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Chargement des données...'),
              ),
            ),
          const SizedBox(height: 24),

          // Sync section if discrepancies
          if (reconciliation != null && reconciliation.hasDiscrepancies) ...[
            _buildSyncSection(state),
            const SizedBox(height: 24),
          ],

          // Sync result if any
          if (state.syncResult != null &&
              state.syncStatus == AdminStatus.success) ...[
            _buildSyncResultCard(state.syncResult!),
            const SizedBox(height: 24),
          ],

          // Problematic reservations if any
          if (reconciliation != null &&
              reconciliation.problematicReservations.isNotEmpty) ...[
            _buildProblematicReservationsCard(
                reconciliation.problematicReservations),
            const SizedBox(height: 24),
          ],

          // Refresh button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoadingStripe
                  ? null
                  : () =>
                      context.read<AdminBloc>().add(LoadStripeReconciliation()),
              icon: isLoadingStripe
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Actualiser les données Stripe'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripeBreakdownCard(StripeReconciliation reconciliation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBreakdownRow(
            'Paiements reçus',
            reconciliation.stripe.chargesTotal,
            AppTheme.success,
            Icons.arrow_downward,
          ),
          const Divider(height: 24),
          _buildBreakdownRow(
            'Remboursements',
            reconciliation.stripe.refundsTotal,
            AppTheme.error,
            Icons.arrow_upward,
          ),
          const Divider(height: 24),
          _buildBreakdownRow(
            'Transferts déneigeurs',
            reconciliation.stripe.transfersTotal,
            AppTheme.info,
            Icons.people,
          ),
          const Divider(height: 24),
          _buildBreakdownRow(
            'Frais Stripe',
            reconciliation.stripe.feesTotal,
            AppTheme.warning,
            Icons.credit_card,
          ),
          const Divider(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.account_balance_wallet, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Revenu net plateforme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(reconciliation.stripe.chargesTotal - reconciliation.stripe.refundsTotal - reconciliation.stripe.transfersTotal - reconciliation.stripe.feesTotal).toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection(AdminState state) {
    final isSyncing = state.syncStatus == AdminStatus.loading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppTheme.warning, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Écarts détectés',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Des différences ont été détectées entre les données locales et Stripe.',
                      style: TextStyle(
                        color: AppTheme.warning.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSyncing
                  ? null
                  : () => context.read<AdminBloc>().add(SyncWithStripe()),
              icon: isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(isSyncing
                  ? 'Synchronisation...'
                  : 'Synchroniser avec Stripe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSubItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.background.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.background,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.background.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
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
                  AppTheme.primary2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'Aujourd\'hui',
                  stats.reservations.today.toString(),
                  Icons.today,
                  AppTheme.warning,
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
                  AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'En attente',
                  stats.reservations.pending.toString(),
                  Icons.pending,
                  AppTheme.warning,
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
              color: AppTheme.textSecondary,
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
          color: AppTheme.surfaceContainer,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
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
            AppTheme.success,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'En attente',
            reservations.pending,
            total,
            AppTheme.warning,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'Annulées',
            reservations.cancelled,
            total,
            AppTheme.error,
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
            backgroundColor: AppTheme.surfaceContainer,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
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
                AppTheme.primary2,
              ),
              _buildUserStatItem(
                'Clients',
                users.clients.toString(),
                Icons.person,
                AppTheme.info,
              ),
              _buildUserStatItem(
                'Déneigeurs',
                users.workers.toString(),
                Icons.ac_unit,
                AppTheme.info,
              ),
              _buildUserStatItem(
                'Actifs',
                users.activeWorkers.toString(),
                Icons.check_circle,
                AppTheme.success,
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
            color: AppTheme.textSecondary,
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
        ? AppTheme.success
        : rate >= 60
            ? AppTheme.warning
            : AppTheme.error;

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
                  backgroundColor: AppTheme.surfaceContainer,
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
                      color: AppTheme.textSecondary,
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
          color: AppTheme.surfaceContainer,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(workers.length, (index) {
          final worker = workers[index];
          final medalColor = index == 0
              ? AppTheme.warning
              : index == 1
                  ? AppTheme.textSecondary
                  : index == 2
                      ? AppTheme.warning.withValues(alpha: 0.6)
                      : AppTheme.textTertiary;

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
                      style: TextStyle(
                        color: AppTheme.background,
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
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: AppTheme.warning, size: 18),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
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
            AppTheme.success,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Ratio clients/déneigeurs',
            '${clientToWorkerRatio.toStringAsFixed(1)}:1',
            Icons.people,
            AppTheme.info,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Déneigeurs actifs',
            '${stats.users.activeWorkers}/${stats.users.workers}',
            Icons.work,
            AppTheme.warning,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            'Réservations annulées',
            '${stats.reservations.cancelled}',
            Icons.cancel,
            AppTheme.error,
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

  Widget _buildStripeBalanceCard(StripeBalance balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary2,
            AppTheme.primary2.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: AppTheme.background, size: 20),
              const SizedBox(width: 8),
              Text(
                'Solde Stripe',
                style: TextStyle(
                  color: AppTheme.background.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponible',
                      style: TextStyle(
                        color: AppTheme.background.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${balance.available.toStringAsFixed(2)} \$',
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.background.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En attente',
                      style: TextStyle(
                        color: AppTheme.background.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${balance.pending.toStringAsFixed(2)} \$',
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
      StripeReconciliation reconciliation, bool hasDiscrepancies) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparaison Local vs Stripe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(
            'Revenus',
            reconciliation.discrepancies.revenue.local,
            reconciliation.discrepancies.revenue.stripe,
            reconciliation.discrepancies.revenue.difference,
          ),
          const Divider(height: 24),
          _buildComparisonRow(
            'Paiements déneigeurs',
            reconciliation.discrepancies.workerPayouts.local,
            reconciliation.discrepancies.workerPayouts.stripe,
            reconciliation.discrepancies.workerPayouts.difference,
          ),
          const Divider(height: 24),
          _buildComparisonRow(
            'Frais Stripe',
            reconciliation.discrepancies.stripeFees.local,
            reconciliation.discrepancies.stripeFees.stripe,
            reconciliation.discrepancies.stripeFees.difference,
          ),
          const Divider(height: 24),
          _buildComparisonRowInt(
            'Nb. transactions',
            reconciliation.discrepancies.transactionCount.local,
            reconciliation.discrepancies.transactionCount.stripe,
            reconciliation.discrepancies.transactionCount.difference,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
      String label, double local, double stripe, double difference) {
    final hasDiscrepancy = difference.abs() > 0.01;
    final differenceColor = hasDiscrepancy
        ? (difference > 0 ? AppTheme.success : AppTheme.error)
        : AppTheme.textSecondary;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Local',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
              ),
              Text(
                '${local.toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Stripe',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
              ),
              Text(
                '${stripe.toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Écart',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
              ),
              Text(
                '${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontSize: 13,
                  color: differenceColor,
                  fontWeight:
                      hasDiscrepancy ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRowInt(
      String label, int local, int stripe, int difference) {
    final hasDiscrepancy = difference != 0;
    final differenceColor = hasDiscrepancy
        ? (difference > 0 ? AppTheme.success : AppTheme.error)
        : AppTheme.textSecondary;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Local',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
              ),
              Text(
                '$local',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Stripe',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
              ),
              Text(
                '$stripe',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Écart',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
              ),
              Text(
                '${difference >= 0 ? '+' : ''}$difference',
                style: TextStyle(
                  fontSize: 13,
                  color: differenceColor,
                  fontWeight:
                      hasDiscrepancy ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProblematicReservationsCard(
      List<ProblematicReservation> reservations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem, color: AppTheme.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Réservations à vérifier (${reservations.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reservations.take(5).map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.id.substring(0, 8),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${r.totalPrice.toStringAsFixed(2)} \$',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(r.status),
                    const Spacer(),
                    _buildPaymentStatusChip(r.paymentStatus),
                  ],
                ),
              )),
          if (reservations.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${reservations.length - 5} autres réservations',
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = AppTheme.success;
        label = 'Terminé';
        break;
      case 'pending':
        color = AppTheme.warning;
        label = 'En attente';
        break;
      case 'cancelled':
        color = AppTheme.error;
        label = 'Annulé';
        break;
      default:
        color = AppTheme.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPaymentStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'paid':
        color = AppTheme.success;
        label = 'Payé';
        break;
      case 'pending':
        color = AppTheme.warning;
        label = 'En attente';
        break;
      case 'failed':
        color = AppTheme.error;
        label = 'Échoué';
        break;
      case 'refunded':
        color = AppTheme.info;
        label = 'Remboursé';
        break;
      default:
        color = AppTheme.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSyncResultCard(StripeSyncResult result) {
    final hasErrors = result.results.errors.isNotEmpty;
    final totalUpdates = result.totalUpdates;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasErrors ? AppTheme.warningLight : AppTheme.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasErrors
              ? AppTheme.warning.withValues(alpha: 0.3)
              : AppTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.warning,
                color: result.success ? AppTheme.success : AppTheme.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Résultat de la synchronisation',
                  style: TextStyle(
                    color: result.success ? AppTheme.success : AppTheme.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.message,
            style: TextStyle(
              color: result.success
                  ? AppTheme.success.withValues(alpha: 0.9)
                  : AppTheme.warning.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSyncStatItem(
                  'Paiements',
                  result.results.paymentsUpdated.toString(),
                  Icons.payment,
                  AppTheme.primary,
                ),
                _buildSyncStatItem(
                  'Remboursements',
                  result.results.refundsRecorded.toString(),
                  Icons.money_off,
                  AppTheme.info,
                ),
                _buildSyncStatItem(
                  'Transferts',
                  result.results.transfersUpdated.toString(),
                  Icons.swap_horiz,
                  AppTheme.warning,
                ),
              ],
            ),
          ),
          if (totalUpdates > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Total: $totalUpdates mise(s) à jour',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          // Errors if any
          if (hasErrors) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Erreurs (${result.results.errors.length})',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...result.results.errors.take(3).map((error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $error',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 12,
                          ),
                        ),
                      )),
                  if (result.results.errors.length > 3)
                    Text(
                      '+ ${result.results.errors.length - 3} autres erreurs',
                      style: TextStyle(
                        color: AppTheme.error.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
          // Details if any
          if (result.results.details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Détails des modifications (${result.results.details.length})',
                style: const TextStyle(fontSize: 14),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              children: result.results.details.take(5).map((detail) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _buildDetailTypeIcon(detail.type),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.reservationId.length > 20
                                  ? '${detail.reservationId.substring(0, 20)}...'
                                  : detail.reservationId,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              detail.message,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTypeIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'payment':
        icon = Icons.payment;
        color = AppTheme.primary;
        break;
      case 'refund':
        icon = Icons.money_off;
        color = AppTheme.info;
        break;
      case 'transfer':
        icon = Icons.swap_horiz;
        color = AppTheme.warning;
        break;
      default:
        icon = Icons.sync;
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
