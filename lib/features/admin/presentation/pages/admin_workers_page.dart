import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/admin_user.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminWorkersPage extends StatefulWidget {
  const AdminWorkersPage({super.key});

  @override
  State<AdminWorkersPage> createState() => _AdminWorkersPageState();
}

class _AdminWorkersPageState extends State<AdminWorkersPage> {
  final _searchController = TextEditingController();
  String _sortBy = 'rating';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadUsers(role: 'snowWorker'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminUser> _sortWorkers(List<AdminUser> workers) {
    final sorted = List<AdminUser>.from(workers);
    switch (_sortBy) {
      case 'rating':
        sorted.sort((a, b) => (b.workerProfile?.averageRating ?? 0)
            .compareTo(a.workerProfile?.averageRating ?? 0));
        break;
      case 'jobs':
        sorted.sort((a, b) => (b.workerProfile?.totalJobsCompleted ?? 0)
            .compareTo(a.workerProfile?.totalJobsCompleted ?? 0));
        break;
      case 'earnings':
        sorted.sort((a, b) => (b.workerProfile?.totalEarnings ?? 0)
            .compareTo(a.workerProfile?.totalEarnings ?? 0));
        break;
      case 'name':
        sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des déneigeurs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier par',
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rating',
                child: Row(
                  children: [
                    if (_sortBy == 'rating') const Icon(Icons.check, size: 18),
                    if (_sortBy == 'rating') const SizedBox(width: 8),
                    const Text('Note'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'jobs',
                child: Row(
                  children: [
                    if (_sortBy == 'jobs') const Icon(Icons.check, size: 18),
                    if (_sortBy == 'jobs') const SizedBox(width: 8),
                    const Text('Nombre de jobs'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'earnings',
                child: Row(
                  children: [
                    if (_sortBy == 'earnings')
                      const Icon(Icons.check, size: 18),
                    if (_sortBy == 'earnings') const SizedBox(width: 8),
                    const Text('Gains'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    if (_sortBy == 'name') const Icon(Icons.check, size: 18),
                    if (_sortBy == 'name') const SizedBox(width: 8),
                    const Text('Nom'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminBloc>().add(LoadUsers(
                  role: 'snowWorker',
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
              _buildSearchBar(context),
              _buildStatsHeader(context, state),
              Expanded(child: _buildWorkersList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un déneigeur...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<AdminBloc>()
                        .add(LoadUsers(role: 'snowWorker'));
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
                role: 'snowWorker',
                search: value.isNotEmpty ? value : null,
              ));
        },
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, AdminState state) {
    final workers = state.users.where((u) => u.role == 'snowWorker').toList();
    final activeCount = workers
        .where((w) => w.workerProfile?.isAvailable == true && !w.isSuspended)
        .length;
    final verifiedCount =
        workers.where((w) => w.workerProfile?.isVerified == true).length;
    final totalEarnings = workers.fold<double>(
        0, (sum, w) => sum + (w.workerProfile?.totalEarnings ?? 0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', workers.length.toString(), Icons.people),
          _buildStatItem('Actifs', activeCount.toString(), Icons.check_circle),
          _buildStatItem('Vérifiés', verifiedCount.toString(), Icons.verified),
          _buildStatItem(
            'Gains totaux',
            '${(totalEarnings / 1000).toStringAsFixed(1)}k\$',
            Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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

  Widget _buildWorkersList(BuildContext context, AdminState state) {
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
              onPressed: () =>
                  context.read<AdminBloc>().add(LoadUsers(role: 'snowWorker')),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final workers =
        _sortWorkers(state.users.where((u) => u.role == 'snowWorker').toList());

    if (workers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ac_unit, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun déneigeur trouvé'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(LoadUsers(
              role: 'snowWorker',
              search: _searchController.text.isNotEmpty
                  ? _searchController.text
                  : null,
            ));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return _buildWorkerCard(context, worker, index);
        },
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context, AdminUser worker, int index) {
    final profile = worker.workerProfile;
    final isActive = profile?.isAvailable == true && !worker.isSuspended;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showWorkerDetails(context, worker),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            _getRankColor(index).withValues(alpha: 0.2),
                        child: Text(
                          worker.firstName.isNotEmpty
                              ? worker.firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: _getRankColor(index),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      if (index < 3)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getRankColor(index),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
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
                                worker.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (profile?.isVerified == true)
                              Icon(Icons.verified,
                                  color: Colors.blue.shade600, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Disponible' : 'Indisponible',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (worker.isSuspended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Suspendu',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWorkerStat(
                    Icons.star,
                    Colors.amber,
                    profile?.averageRating.toStringAsFixed(1) ?? '0.0',
                    'Note',
                  ),
                  _buildWorkerStat(
                    Icons.work,
                    Colors.blue,
                    profile?.totalJobsCompleted.toString() ?? '0',
                    'Jobs',
                  ),
                  _buildWorkerStat(
                    Icons.attach_money,
                    Colors.green,
                    '${(profile?.totalEarnings ?? 0).toStringAsFixed(0)}\$',
                    'Gains',
                  ),
                  _buildWorkerStat(
                    Icons.warning,
                    Colors.orange,
                    profile?.warningCount.toString() ?? '0',
                    'Avert.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerStat(
      IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
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

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber.shade700;
      case 1:
        return Colors.grey.shade500;
      case 2:
        return Colors.brown.shade400;
      default:
        return AppTheme.primary;
    }
  }

  void _showWorkerDetails(BuildContext context, AdminUser worker) {
    final profile = worker.workerProfile;
    final adminBloc = context.read<AdminBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
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
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          worker.firstName.isNotEmpty
                              ? worker.firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            worker.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (profile?.isVerified == true) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.verified, color: Colors.blue.shade600),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            profile?.averageRating.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' (${profile?.totalRatingsCount ?? 0} avis)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailStatCard(
                        'Jobs terminés',
                        profile?.totalJobsCompleted.toString() ?? '0',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailStatCard(
                        'Gains totaux',
                        '${profile?.totalEarnings.toStringAsFixed(0) ?? 0}\$',
                        Icons.attach_money,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailStatCard(
                        'Avertissements',
                        profile?.warningCount.toString() ?? '0',
                        Icons.warning,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailStatCard(
                        'Statut',
                        profile?.isAvailable == true
                            ? 'Disponible'
                            : 'Indisponible',
                        profile?.isAvailable == true
                            ? Icons.check_circle
                            : Icons.cancel,
                        profile?.isAvailable == true
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Informations de contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildContactRow(Icons.email, worker.email),
                if (worker.phoneNumber != null)
                  _buildContactRow(Icons.phone, worker.phoneNumber!),
                _buildContactRow(
                  Icons.calendar_today,
                  'Inscrit le ${_formatDate(worker.createdAt)}',
                ),
                if (worker.isSuspended) ...[
                  const SizedBox(height: 24),
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
                        if (worker.suspensionReason != null) ...[
                          const SizedBox(height: 8),
                          Text('Raison: ${worker.suspensionReason}'),
                        ],
                        if (worker.suspendedUntil != null) ...[
                          const SizedBox(height: 4),
                          Text(
                              'Jusqu\'au: ${_formatDate(worker.suspendedUntil!)}'),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: worker.isSuspended
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Lever la suspension'),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            adminBloc.add(UnsuspendUser(worker.id));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.block),
                          label: const Text('Suspendre le déneigeur'),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showSuspendDialog(context, worker);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, AdminUser worker) {
    final reasonController = TextEditingController();
    int selectedDays = 7;
    final adminBloc = context.read<AdminBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Suspendre le déneigeur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vous allez suspendre ${worker.fullName}'),
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
                  userId: worker.id,
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
