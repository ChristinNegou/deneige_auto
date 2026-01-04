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
                backgroundColor: Colors.green,
              ),
            );
            context.read<AdminBloc>().add(ClearError());
          }
          if (state.errorMessage != null &&
              state.actionStatus == AdminStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
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
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade300),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      size: 35, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Administration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Deneige Auto',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
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
        color: isLogout ? Colors.red : (isSelected ? AppTheme.primary : null),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : (isSelected ? AppTheme.primary : null),
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
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsers),
              ),
              _buildQuickActionButton(
                context,
                icon: Icons.event_note,
                label: 'Réservations',
                color: Colors.purple,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminReservations),
              ),
              _buildQuickActionButton(
                context,
                icon: Icons.notifications_active,
                label: 'Notifier',
                color: Colors.orange,
                onTap: () => _showBroadcastDialog(context),
              ),
              _buildQuickActionButton(
                context,
                icon: Icons.analytics,
                label: 'Rapports',
                color: Colors.indigo,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminReports),
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
              color: Colors.grey.shade700,
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
          Colors.blue,
          subtitle:
              '${stats.users.clients} clients, ${stats.users.workers} déneigeurs',
          onTap: () => Navigator.pushNamed(context, AppRoutes.adminUsers),
        ),
        _buildStatCard(
          context,
          'Réservations',
          stats.reservations.total.toString(),
          Icons.calendar_today,
          Colors.purple,
          subtitle: '${stats.reservations.today} aujourd\'hui',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.adminReservations),
        ),
        _buildStatCard(
          context,
          'En attente',
          stats.reservations.pending.toString(),
          Icons.pending_actions,
          Colors.orange,
          subtitle: 'À traiter',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.adminReservations),
        ),
        _buildStatCard(
          context,
          'Taux de complétion',
          '${stats.reservations.completionRate.toStringAsFixed(0)}%',
          Icons.check_circle,
          Colors.green,
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
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(AdminStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_money, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Revenus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRevenueItem(
                  'Commission plateforme', stats.revenue.platformFees, false),
              _buildRevenueItem('Pourboires', stats.revenue.tips, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String label, double amount, bool isMain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} \$',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMain ? 28 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTopWorkersCard(BuildContext context, AdminStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
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
                        style: const TextStyle(
                          color: Colors.white,
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
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
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
        return Colors.amber;
      case 1:
        return Colors.grey.shade400;
      case 2:
        return Colors.brown.shade300;
      default:
        return Colors.grey.shade300;
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
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange),
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
                  value: selectedRole,
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
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs'),
                      backgroundColor: Colors.red,
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
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
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
              style: TextStyle(color: Colors.grey.shade600),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
