import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/admin_user.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchController = TextEditingController();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminBloc>().add(LoadUsers(
                  role: _selectedRole,
                  search: _searchController.text.isNotEmpty
                      ? _searchController.text
                      : null,
                )),
          ),
        ],
      ),
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
          return Column(
            children: [
              _buildFilters(context),
              Expanded(child: _buildUsersList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<AdminBloc>()
                            .add(LoadUsers(role: _selectedRole));
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onSubmitted: (value) {
              context.read<AdminBloc>().add(LoadUsers(
                    role: _selectedRole,
                    search: value.isNotEmpty ? value : null,
                  ));
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'Tous', null),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Clients', 'client'),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Déneigeurs', 'snowWorker'),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Admins', 'admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String? role) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedRole = selected ? role : null);
        context.read<AdminBloc>().add(LoadUsers(
              role: selected ? role : null,
              search: _searchController.text.isNotEmpty
                  ? _searchController.text
                  : null,
            ));
      },
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primary,
    );
  }

  Widget _buildUsersList(BuildContext context, AdminState state) {
    if (state.usersStatus == AdminStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.usersStatus == AdminStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? 'Une erreur est survenue'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AdminBloc>().add(LoadUsers()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun utilisateur trouvé'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(LoadUsers(
              role: _selectedRole,
              search: _searchController.text.isNotEmpty
                  ? _searchController.text
                  : null,
            ));
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                return _buildUserCard(context, user);
              },
            ),
          ),
          if (state.usersTotalPages > 1) _buildPagination(context, state),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AdminUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showUserDetails(context, user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    _getRoleColor(user.role).withValues(alpha: 0.2),
                child: Text(
                  user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildRoleBadge(user.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (user.isSuspended) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.block,
                                    size: 14, color: Colors.red.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Suspendu',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (user.role == 'snowWorker' &&
                            user.workerProfile != null) ...[
                          Icon(Icons.star,
                              size: 14, color: Colors.amber.shade600),
                          const SizedBox(width: 2),
                          Text(
                            user.workerProfile!.averageRating
                                .toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${user.workerProfile!.totalJobsCompleted} jobs',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showUserActions(context, user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final color = _getRoleColor(role);
    String label;
    switch (role) {
      case 'admin':
        label = 'Admin';
        break;
      case 'snowWorker':
        label = 'Déneigeur';
        break;
      default:
        label = 'Client';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'snowWorker':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  Widget _buildPagination(BuildContext context, AdminState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.usersPage > 1
                ? () {
                    context.read<AdminBloc>().add(LoadUsers(
                          page: state.usersPage - 1,
                          role: _selectedRole,
                          search: _searchController.text.isNotEmpty
                              ? _searchController.text
                              : null,
                        ));
                  }
                : null,
          ),
          Text(
            'Page ${state.usersPage} / ${state.usersTotalPages}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.usersPage < state.usersTotalPages
                ? () {
                    context.read<AdminBloc>().add(LoadUsers(
                          page: state.usersPage + 1,
                          role: _selectedRole,
                          search: _searchController.text.isNotEmpty
                              ? _searchController.text
                              : null,
                        ));
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, AdminUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          _getRoleColor(user.role).withValues(alpha: 0.2),
                      child: Text(
                        user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildRoleBadge(user.role),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(Icons.email, 'Email', user.email),
                if (user.phoneNumber != null)
                  _buildDetailRow(Icons.phone, 'Téléphone', user.phoneNumber!),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Inscrit le',
                  _formatDate(user.createdAt),
                ),
                if (user.isSuspended) ...[
                  const Divider(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.block, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Compte suspendu',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (user.suspensionReason != null) ...[
                          const SizedBox(height: 8),
                          Text('Raison: ${user.suspensionReason}'),
                        ],
                        if (user.suspendedUntil != null) ...[
                          const SizedBox(height: 4),
                          Text(
                              'Jusqu\'au: ${_formatDate(user.suspendedUntil!)}'),
                        ],
                      ],
                    ),
                  ),
                ],
                if (user.role == 'snowWorker' &&
                    user.workerProfile != null) ...[
                  const Divider(height: 32),
                  const Text(
                    'Statistiques Déneigeur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          'Jobs terminés',
                          user.workerProfile!.totalJobsCompleted.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          'Note moyenne',
                          user.workerProfile!.averageRating.toStringAsFixed(1),
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          'Gains totaux',
                          '${user.workerProfile!.totalEarnings.toStringAsFixed(0)} \$',
                          Icons.attach_money,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          'Avertissements',
                          user.workerProfile!.warningCount.toString(),
                          Icons.warning,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
                if (user.role == 'client') ...[
                  const Divider(height: 32),
                  const Text(
                    'Statistiques Client',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          'Réservations',
                          user.reservationsCount.toString(),
                          Icons.calendar_today,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          'Total dépensé',
                          '${user.totalSpent.toStringAsFixed(0)} \$',
                          Icons.attach_money,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
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
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showUserActions(BuildContext context, AdminUser user) {
    final adminBloc = context.read<AdminBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!user.isSuspended)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Suspendre l\'utilisateur'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSuspendDialog(context, user);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Lever la suspension'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  adminBloc.add(UnsuspendUser(user.id));
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Voir les détails'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showUserDetails(context, user);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, AdminUser user) {
    final reasonController = TextEditingController();
    int selectedDays = 7;
    final adminBloc = context.read<AdminBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Suspendre l\'utilisateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vous allez suspendre ${user.fullName}'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDays,
                decoration: const InputDecoration(
                  labelText: 'Durée',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 jour')),
                  DropdownMenuItem(value: 3, child: Text('3 jours')),
                  DropdownMenuItem(value: 7, child: Text('7 jours')),
                  DropdownMenuItem(value: 14, child: Text('14 jours')),
                  DropdownMenuItem(value: 30, child: Text('30 jours')),
                  DropdownMenuItem(value: 365, child: Text('1 an')),
                ],
                onChanged: (value) => setState(() => selectedDays = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                adminBloc.add(SuspendUser(
                  userId: user.id,
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : null,
                  days: selectedDays,
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Suspendre'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
