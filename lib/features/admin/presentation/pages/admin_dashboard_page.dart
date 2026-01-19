import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/admin_stats.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import 'admin_disputes_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<AdminBloc>().add(LoadDashboardStats()),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppTheme.success,
              ),
            );
            context.read<AdminBloc>().add(ClearError());
          }
          if (state.errorMessage != null &&
              state.actionStatus == AdminStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.error,
              ),
            );
            context.read<AdminBloc>().add(ClearError());
          }
        },
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
                  Text(state.errorMessage ?? 'Erreur de chargement'),
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
            return const Center(child: Text('Aucune donnée'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminBloc>().add(LoadDashboardStats());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildStatsGrid(context, state.stats!),
                  const SizedBox(height: 24),
                  _buildSupportStatsCard(context, state.stats!),
                  const SizedBox(height: 24),
                  _buildRevenueCard(state.stats!),
                  const SizedBox(height: 24),
                  _buildTopWorkersCard(context, state.stats!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withValues(alpha: 0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.admin_panel_settings,
                      size: 35, color: AppTheme.background),
                ),
                const SizedBox(height: 12),
                Text(
                  'Administration',
                  style: TextStyle(
                    color: AppTheme.background,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Deneige Auto',
                  style: TextStyle(
                    color: AppTheme.background.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            isSelected: true,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Utilisateurs',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminUsers);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today,
            title: 'Réservations',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminReservations);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.ac_unit,
            title: 'Déneigeurs',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminWorkers);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.verified_user,
            title: 'Vérifications',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminVerifications);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Comptes Stripe',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminStripeAccounts);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.notifications,
            title: 'Envoyer notification',
            onTap: () {
              Navigator.pop(context);
              _showBroadcastDialog(context);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart,
            title: 'Rapports',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminReports);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.support_agent,
            title: 'Support',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminSupport);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.gavel,
            title: 'Litiges',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDisputesPage()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.smart_toy,
            title: 'Intelligence IA',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminAI);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout_rounded,
            title: 'Déconnexion',
            isLogout: true,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            isLogout ? AppTheme.error : (isSelected ? AppTheme.primary : null),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout
              ? AppTheme.error
              : (isSelected ? AppTheme.primary : null),
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
            'Actions rapides',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                context,
                icon: Icons.person_add,
                label: 'Utilisateurs',
                color: AppTheme.info,
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsers),
              ),
              _buildQuickActionButton(
                context,
                icon: Icons.event_note,
                label: 'Réservations',
                color: AppTheme.primary2,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminReservations),
              ),
              _buildQuickActionButton(
                context,
                icon: Icons.notifications_active,
                label: 'Notifier',
                color: AppTheme.warning,
                onTap: () => _showBroadcastDialog(context),
              ),
              _buildQuickActionButton(
                context,
                icon: Icons.support_agent,
                label: 'Support',
                color: AppTheme.success,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminSupport),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Utilisateurs',
          stats.users.total.toString(),
          Icons.people,
          AppTheme.info,
          subtitle:
              '${stats.users.clients} clients, ${stats.users.workers} déneigeurs',
          onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsers),
        ),
        _buildStatCard(
          context,
          'Réservations',
          stats.reservations.total.toString(),
          Icons.calendar_today,
          AppTheme.primary2,
          subtitle: '${stats.reservations.today} aujourd\'hui',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.adminReservations),
        ),
        _buildStatCard(
          context,
          'En attente',
          stats.reservations.pending.toString(),
          Icons.pending_actions,
          AppTheme.warning,
          subtitle: 'À traiter',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.adminReservations),
        ),
        _buildStatCard(
          context,
          'Taux de complétion',
          '${stats.reservations.completionRate.toStringAsFixed(0)}%',
          Icons.check_circle,
          AppTheme.success,
          subtitle: '${stats.reservations.completed} terminées',
          onTap: () => Navigator.pushNamed(context, AppRoutes.adminReports),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportStatsCard(BuildContext context, AdminStats stats) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.adminSupport),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.support_agent,
                          color: AppTheme.info, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (stats.support.pending > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.priority_high,
                            color: AppTheme.background, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.support.pending} en attente',
                          style: TextStyle(
                            color: AppTheme.background,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSupportStatItem(
                    'Total',
                    stats.support.total.toString(),
                    Icons.inbox,
                    AppTheme.textSecondary,
                  ),
                ),
                Expanded(
                  child: _buildSupportStatItem(
                    'En attente',
                    stats.support.pending.toString(),
                    Icons.pending_actions,
                    AppTheme.warning,
                  ),
                ),
                Expanded(
                  child: _buildSupportStatItem(
                    'En cours',
                    stats.support.inProgress.toString(),
                    Icons.hourglass_top,
                    AppTheme.info,
                  ),
                ),
                Expanded(
                  child: _buildSupportStatItem(
                    'Résolues',
                    stats.support.resolved.toString(),
                    Icons.check_circle,
                    AppTheme.success,
                  ),
                ),
              ],
            ),
            if (stats.support.todayNew > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.new_releases, color: AppTheme.info, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${stats.support.todayNew} nouvelle(s) demande(s) aujourd\'hui',
                      style: TextStyle(
                        color: AppTheme.info,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildSupportStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRevenueCard(AdminStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary2, AppTheme.primary2.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppTheme.background),
              const SizedBox(width: 8),
              Text(
                'Revenus',
                style: TextStyle(
                  color: AppTheme.background,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stats.revenue.reservationCount} réservations',
                  style: TextStyle(
                    color: AppTheme.background,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRevenueItem('Total', stats.revenue.total, true),
              _buildRevenueItem('Ce mois', stats.revenue.thisMonth, false),
            ],
          ),
          Divider(
              color: AppTheme.background.withValues(alpha: 0.24), height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRevenueItem('Commission brute (25%)',
                  stats.revenue.platformFeesGross, false),
              _buildRevenueItem('Frais Stripe', stats.revenue.stripeFees, false,
                  isNegative: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRevenueItem(
                  'Commission nette', stats.revenue.platformFeesNet, false,
                  isHighlighted: true),
              _buildRevenueItem('Pourboires', stats.revenue.tips, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String label, double amount, bool isMain,
      {bool isNegative = false, bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.background.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNegative)
              Text(
                '-',
                style: TextStyle(
                  color: AppTheme.background.withValues(alpha: 0.7),
                  fontSize: isMain ? 28 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              '${amount.toStringAsFixed(2)} \$',
              style: TextStyle(
                color: isHighlighted ? AppTheme.success : AppTheme.background,
                fontSize: isMain ? 28 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopWorkersCard(BuildContext context, AdminStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: AppTheme.warning),
                  SizedBox(width: 8),
                  Text(
                    'Top Déneigeurs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.adminWorkers),
                child: const Text('Voir tous'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats.topWorkers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Aucun déneigeur pour le moment')),
            )
          else
            ...List.generate(stats.topWorkers.length, (index) {
              final worker = stats.topWorkers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getMedalColor(index),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppTheme.background,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${worker.jobsCompleted} jobs - ${worker.totalEarnings.toStringAsFixed(0)}\$',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 16, color: AppTheme.warning),
                          const SizedBox(width: 4),
                          Text(
                            worker.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return AppTheme.warning;
      case 1:
        return AppTheme.textSecondary;
      case 2:
        return AppTheme.warning.withValues(alpha: 0.6);
      default:
        return AppTheme.textTertiary;
    }
  }

  void _showBroadcastDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String? selectedRole;
    final adminBloc = context.read<AdminBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: AppTheme.warning),
              SizedBox(width: 12),
              Text('Envoyer une notification'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.message),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Destinataires',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.people),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: null, child: Text('Tous les utilisateurs')),
                    DropdownMenuItem(
                        value: 'client', child: Text('Clients uniquement')),
                    DropdownMenuItem(
                        value: 'snowWorker',
                        child: Text('Déneigeurs uniquement')),
                  ],
                  onChanged: (value) => setState(() => selectedRole = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Envoyer'),
              onPressed: () {
                if (titleController.text.isEmpty ||
                    messageController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Veuillez remplir tous les champs'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }

                adminBloc.add(BroadcastNotification(
                  title: titleController.text,
                  message: messageController.text,
                  targetRole: selectedRole,
                ));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion Admin'),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter du panneau d\'administration ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Déclencher la déconnexion via AuthBloc
              context.read<AuthBloc>().add(LogoutRequested());
              // Naviguer vers la page de sélection de compte
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.accountType,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
