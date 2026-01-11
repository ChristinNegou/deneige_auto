import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';

class AdminDisputesPage extends StatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  State<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends State<AdminDisputesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DisputeService _disputeService;
  List<dynamic> _disputes = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  DisputeStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _disputeService = DisputeService(dioClient: sl<DioClient>());
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _disputeService.getAllDisputes(status: _filterStatus),
        _disputeService.getDisputeStats(),
      ]);

      if (mounted) {
        setState(() {
          _disputes = results[0]['disputes'] ?? [];
          _stats = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Gestion des litiges',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Resolus'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDisputesList(
                        _disputes.where((d) => _isOpen(d['status'])).toList()),
                    _buildDisputesList(
                        _disputes.where((d) => !_isOpen(d['status'])).toList()),
                    _buildStatsTab(),
                  ],
                ),
    );
  }

  bool _isOpen(String? status) {
    return ['open', 'under_review', 'pending_response', 'appealed', 'escalated']
        .contains(status);
  }

  Widget _buildDisputesList(List<dynamic> disputes) {
    if (disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: AppTheme.textTertiary, size: 64),
            const SizedBox(height: 16),
            Text(
              'Aucun litige',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: disputes.length,
        itemBuilder: (context, index) {
          return _buildDisputeCard(disputes[index]);
        },
      ),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute) {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');
    final createdAt = DateTime.tryParse(dispute['createdAt'] ?? '');
    final type = DisputeType.fromValue(dispute['type'] ?? 'other');
    final status = DisputeStatus.fromValue(dispute['status'] ?? 'open');
    final priority = dispute['priority'] ?? 'medium';
    final claimant = dispute['claimant']?['user'];
    final respondent = dispute['respondent']?['user'];

    return GestureDetector(
      onTap: () => _showDisputeDetails(dispute),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getPriorityColor(priority).withValues(alpha: 0.3),
            width: priority == 'urgent' ? 2 : 1,
          ),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              type.label,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _buildPriorityBadge(priority),
                        ],
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(createdAt),
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Parties involved
            Row(
              children: [
                Expanded(
                  child: _buildPartyInfo(
                    'Plaignant',
                    claimant,
                    dispute['claimant']?['role'] ?? '',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    color: AppTheme.textTertiary,
                    size: 16,
                  ),
                ),
                Expanded(
                  child: _buildPartyInfo(
                    'Defenseur',
                    respondent,
                    dispute['respondent']?['role'] ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description preview
            Text(
              dispute['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                _buildStatusBadge(status),
                const Spacer(),
                if ((dispute['claimedAmount'] ?? 0) > 0) ...[
                  Text(
                    '${(dispute['claimedAmount'] as num).toStringAsFixed(2)} \$',
                    style: TextStyle(
                      color: AppTheme.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textTertiary,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyInfo(
      String label, Map<String, dynamic>? user, String role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user != null
              ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
              : 'Inconnu',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          role == 'client' ? 'Client' : 'Deneigeur',
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getPriorityLabel(priority),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DisputeStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_stats == null) {
      return Center(
        child: Text(
          'Statistiques non disponibles',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'En attente',
                  '${_stats!['pendingCount'] ?? 0}',
                  Icons.hourglass_empty,
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'En retard',
                  '${_stats!['overdueCount'] ?? 0}',
                  Icons.warning,
                  AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Temps moyen de resolution',
            '${_stats!['avgResolutionTimeHours'] ?? 0}h',
            Icons.schedule,
            AppTheme.info,
          ),
          const SizedBox(height: 24),

          // By status breakdown
          Text(
            'Par statut',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...(_stats!['byStatus'] as List<dynamic>? ?? []).map((stat) {
            final status = DisputeStatus.fromValue(stat['_id'] ?? '');
            return _buildStatRow(status.label, stat['count'] ?? 0);
          }),
          const SizedBox(height: 24),

          // By type breakdown
          Text(
            'Par type',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...(_stats!['byType'] as List<dynamic>? ?? []).map((stat) {
            final type = DisputeType.fromValue(stat['_id'] ?? '');
            return _buildStatRow(type.label, stat['count'] ?? 0);
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisputeDetails(Map<String, dynamic> dispute) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DisputeDetailsSheet(
        dispute: dispute,
        disputeService: _disputeService,
        onResolved: _loadData,
      ),
    );
  }

  Color _getStatusColor(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return AppTheme.warning;
      case DisputeStatus.underReview:
        return AppTheme.info;
      case DisputeStatus.pendingResponse:
        return AppTheme.warning;
      case DisputeStatus.resolved:
        return AppTheme.success;
      case DisputeStatus.closed:
        return AppTheme.textTertiary;
      case DisputeStatus.appealed:
        return AppTheme.primary;
      case DisputeStatus.escalated:
        return AppTheme.error;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return AppTheme.textTertiary;
      case 'medium':
        return AppTheme.info;
      case 'high':
        return AppTheme.warning;
      case 'urgent':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'BASSE';
      case 'medium':
        return 'MOYENNE';
      case 'high':
        return 'HAUTE';
      case 'urgent':
        return 'URGENT';
      default:
        return priority.toUpperCase();
    }
  }

  IconData _getTypeIcon(DisputeType type) {
    switch (type) {
      case DisputeType.noShow:
        return Icons.person_off;
      case DisputeType.incompleteWork:
        return Icons.construction;
      case DisputeType.qualityIssue:
        return Icons.thumb_down;
      case DisputeType.lateArrival:
        return Icons.schedule;
      case DisputeType.damage:
        return Icons.warning;
      case DisputeType.wrongLocation:
        return Icons.location_off;
      case DisputeType.overcharge:
        return Icons.money_off;
      case DisputeType.unprofessional:
        return Icons.report_problem;
      case DisputeType.other:
        return Icons.help_outline;
    }
  }

  Color _getTypeColor(DisputeType type) {
    switch (type) {
      case DisputeType.noShow:
      case DisputeType.damage:
      case DisputeType.wrongLocation:
      case DisputeType.overcharge:
        return AppTheme.error;
      case DisputeType.incompleteWork:
      case DisputeType.qualityIssue:
      case DisputeType.lateArrival:
      case DisputeType.unprofessional:
        return AppTheme.warning;
      case DisputeType.other:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 64),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet for dispute details and resolution
class _DisputeDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> dispute;
  final DisputeService disputeService;
  final VoidCallback onResolved;

  const _DisputeDetailsSheet({
    required this.dispute,
    required this.disputeService,
    required this.onResolved,
  });

  @override
  State<_DisputeDetailsSheet> createState() => _DisputeDetailsSheetState();
}

class _DisputeDetailsSheetState extends State<_DisputeDetailsSheet> {
  bool _isLoading = false;
  String? _selectedDecision;
  double _refundAmount = 0;
  String? _selectedWorkerPenalty;
  String? _selectedClientPenalty;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolveDispute() async {
    if (_selectedDecision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selectionnez une decision'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.disputeService.resolveDispute(
        disputeId: widget.dispute['_id'],
        decision: _selectedDecision!,
        refundAmount: _refundAmount > 0 ? _refundAmount : null,
        workerPenalty: _selectedWorkerPenalty,
        clientPenalty: _selectedClientPenalty,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onResolved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Litige resolu avec succes'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimedAmount = (widget.dispute['claimedAmount'] ?? 0).toDouble();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Resoudre le litige',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decision dropdown
                  Text(
                    'Decision',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDecision,
                        isExpanded: true,
                        hint: Text(
                          'Selectionnez une decision',
                          style: TextStyle(color: AppTheme.textTertiary),
                        ),
                        dropdownColor: AppTheme.surface,
                        items: const [
                          DropdownMenuItem(
                            value: 'favor_claimant',
                            child: Text('En faveur du plaignant'),
                          ),
                          DropdownMenuItem(
                            value: 'favor_respondent',
                            child: Text('En faveur du defenseur'),
                          ),
                          DropdownMenuItem(
                            value: 'full_refund',
                            child: Text('Remboursement complet'),
                          ),
                          DropdownMenuItem(
                            value: 'partial_refund',
                            child: Text('Remboursement partiel'),
                          ),
                          DropdownMenuItem(
                            value: 'no_action',
                            child: Text('Aucune action'),
                          ),
                          DropdownMenuItem(
                            value: 'mutual_agreement',
                            child: Text('Accord mutuel'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDecision = value;
                            if (value == 'full_refund') {
                              _refundAmount = claimedAmount;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Refund amount
                  if (_selectedDecision == 'partial_refund' ||
                      _selectedDecision == 'full_refund') ...[
                    Text(
                      'Montant du remboursement',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Montant en \$',
                        hintStyle: TextStyle(color: AppTheme.textTertiary),
                        prefixIcon:
                            Icon(Icons.attach_money, color: AppTheme.info),
                        suffixText: '/ ${claimedAmount.toStringAsFixed(2)} \$',
                        filled: true,
                        fillColor: AppTheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _refundAmount = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Worker penalty
                  Text(
                    'Penalite deneigeur (optionnel)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWorkerPenalty,
                        isExpanded: true,
                        hint: Text(
                          'Aucune penalite',
                          style: TextStyle(color: AppTheme.textTertiary),
                        ),
                        dropdownColor: AppTheme.surface,
                        items: const [
                          DropdownMenuItem(
                            value: 'none',
                            child: Text('Aucune'),
                          ),
                          DropdownMenuItem(
                            value: 'warning',
                            child: Text('Avertissement'),
                          ),
                          DropdownMenuItem(
                            value: 'suspension_3days',
                            child: Text('Suspension 3 jours'),
                          ),
                          DropdownMenuItem(
                            value: 'suspension_7days',
                            child: Text('Suspension 7 jours'),
                          ),
                          DropdownMenuItem(
                            value: 'suspension_30days',
                            child: Text('Suspension 30 jours'),
                          ),
                          DropdownMenuItem(
                            value: 'permanent_ban',
                            child: Text('Bannissement permanent'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedWorkerPenalty = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  Text(
                    'Notes (optionnel)',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Notes sur la decision...',
                      hintStyle: TextStyle(color: AppTheme.textTertiary),
                      filled: true,
                      fillColor: AppTheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.border),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resolveDispute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.background,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirmer la resolution',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
