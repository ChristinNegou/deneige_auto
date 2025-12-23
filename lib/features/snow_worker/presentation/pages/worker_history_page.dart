import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/worker_job.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../../../../core/di/injection_container.dart';

class WorkerHistoryPage extends StatelessWidget {
  const WorkerHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WorkerJobsBloc>()..add(const LoadJobHistory()),
      child: const _WorkerHistoryView(),
    );
  }
}

class _WorkerHistoryView extends StatefulWidget {
  const _WorkerHistoryView();

  @override
  State<_WorkerHistoryView> createState() => _WorkerHistoryViewState();
}

class _WorkerHistoryViewState extends State<_WorkerHistoryView> {
  String _selectedFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<WorkerJobsBloc>().add(const LoadMoreHistory());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: Colors.orange[600],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tous'),
                  const SizedBox(width: 8),
                  _buildFilterChip('week', 'Cette semaine'),
                  const SizedBox(width: 8),
                  _buildFilterChip('month', 'Ce mois'),
                  const SizedBox(width: 8),
                  _buildFilterChip('tips', 'Avec pourboire'),
                ],
              ),
            ),
          ),

          // Jobs List
          Expanded(
            child: BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
              builder: (context, state) {
                if (state is WorkerJobsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is WorkerJobsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<WorkerJobsBloc>().add(const LoadJobHistory());
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is JobHistoryLoaded) {
                  final jobs = _filterJobs(state.jobs);

                  if (jobs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<WorkerJobsBloc>().add(const LoadJobHistory());
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: jobs.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= jobs.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildHistoryCard(jobs[index]);
                      },
                    ),
                  );
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.orange[200],
      checkmarkColor: Colors.orange[800],
    );
  }

  List<WorkerJob> _filterJobs(List<WorkerJob> jobs) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return jobs.where((j) =>
          j.completedAt != null && j.completedAt!.isAfter(weekAgo)
        ).toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return jobs.where((j) =>
          j.completedAt != null && j.completedAt!.isAfter(monthAgo)
        ).toList();
      case 'tips':
        return jobs.where((j) => j.tipAmount != null && j.tipAmount! > 0).toList();
      default:
        return jobs;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun job dans l\'historique',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos jobs terminés apparaîtront ici',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(WorkerJob job) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'fr_FR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header with date and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.completedAt != null
                    ? dateFormat.format(job.completedAt!)
                    : 'Date inconnue',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Terminé',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Client info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange[100],
                child: Text(
                  job.client.firstName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.orange[700],
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
                      job.client.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      job.displayAddress,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Vehicle & Duration
          Row(
            children: [
              Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                job.vehicle.displayName,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const Spacer(),
              if (job.durationMinutes != null) ...[
                Icon(Icons.timer, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  '${job.durationMinutes} min',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenus',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Text(
                    '${job.totalPrice.toStringAsFixed(2)} \$',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  if (job.tipAmount != null && job.tipAmount! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Text(
                        '+${job.tipAmount!.toStringAsFixed(2)} \$ tip',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Rating if available
          if (job.rating != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Évaluation: '),
                ...List.generate(5, (index) {
                  return Icon(
                    index < job.rating! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
