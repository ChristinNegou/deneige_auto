import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';

class DisputeDetailsPage extends StatefulWidget {
  final String disputeId;

  const DisputeDetailsPage({
    super.key,
    required this.disputeId,
  });

  @override
  State<DisputeDetailsPage> createState() => _DisputeDetailsPageState();
}

class _DisputeDetailsPageState extends State<DisputeDetailsPage> {
  late DisputeService _disputeService;
  Dispute? _dispute;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _disputeService = DisputeService(dioClient: sl<DioClient>());
    _loadDispute();
  }

  Future<void> _loadDispute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dispute = await _disputeService.getDisputeDetails(widget.disputeId);
      if (mounted) {
        setState(() {
          _dispute = dispute;
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

  Future<void> _showAppealDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Faire appel',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expliquez pourquoi vous contestez cette decision (minimum 50 caracteres):',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Votre justification...',
                hintStyle: TextStyle(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length >= 50) {
                Navigator.pop(context, controller.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Minimum 50 caracteres requis'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
            ),
            child: const Text('Soumettre l\'appel'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _submitAppeal(result);
    }
  }

  Future<void> _submitAppeal(String reason) async {
    setState(() => _isLoading = true);

    try {
      await _disputeService.appealDispute(
        disputeId: widget.disputeId,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appel soumis avec succes'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadDispute();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Impossible d\'envoyer la réponse. Veuillez réessayer.'),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Détails du litige',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _dispute == null
                  ? _buildNotFoundState()
                  : RefreshIndicator(
                      onRefresh: _loadDispute,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Card
                            _buildStatusCard(),
                            const SizedBox(height: 16),

                            // Details Card
                            _buildDetailsCard(),
                            const SizedBox(height: 16),

                            // Timeline Card
                            if (_dispute!.responseDeadline != null ||
                                _dispute!.resolutionDeadline != null)
                              _buildDeadlinesCard(),

                            // Resolution Card
                            if (_dispute!.resolution != null) ...[
                              const SizedBox(height: 16),
                              _buildResolutionCard(),
                            ],

                            // Appeal Button
                            if (_dispute!.canAppeal) ...[
                              const SizedBox(height: 24),
                              _buildAppealButton(),
                            ],

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatusCard() {
    final dispute = _dispute!;
    final statusColor = _getStatusColor(dispute.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor,
            statusColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(dispute.type),
                  color: AppTheme.background,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dispute.type.label,
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dispute.status.label,
                      style: TextStyle(
                        color: AppTheme.background.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dispute.claimedAmount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money,
                    color: AppTheme.background,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Montant reclame: ${dispute.claimedAmount.toStringAsFixed(2)} \$',
                    style: TextStyle(
                      color: AppTheme.background,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final dispute = _dispute!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppTheme.info),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dispute.description,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Divider(height: 32, color: AppTheme.border),
          _buildInfoRow(
            Icons.calendar_today,
            'Date d\'ouverture',
            dateFormat.format(dispute.createdAt),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.priority_high,
            'Priorite',
            _getPriorityLabel(dispute.priority),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesCard() {
    final dispute = _dispute!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.warning),
              const SizedBox(width: 8),
              Text(
                'Delais',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dispute.responseDeadline != null) ...[
            _buildDeadlineRow(
              'Reponse attendue avant',
              dateFormat.format(dispute.responseDeadline!),
              dispute.responseDeadline!.isBefore(DateTime.now()),
            ),
            const SizedBox(height: 8),
          ],
          if (dispute.resolutionDeadline != null)
            _buildDeadlineRow(
              'Résolution attendue avant',
              dateFormat.format(dispute.resolutionDeadline!),
              dispute.resolutionDeadline!.isBefore(DateTime.now()),
            ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard() {
    final dispute = _dispute!;
    final resolution = dispute.resolution!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: AppTheme.success),
              const SizedBox(width: 8),
              Text(
                'Résolution',
                style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getDecisionIcon(resolution['decision']),
                  color: AppTheme.success,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Décision',
                        style: TextStyle(
                          color: AppTheme.success.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _getDecisionLabel(resolution['decision']),
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (resolution['refundAmount'] != null &&
              resolution['refundAmount'] > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.payments, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Remboursement: ${(resolution['refundAmount'] as num).toStringAsFixed(2)} \$',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (resolution['notes'] != null) ...[
            const SizedBox(height: 12),
            Text(
              resolution['notes'],
              style: TextStyle(
                color: AppTheme.success.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
          if (resolution['resolvedAt'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Résolu le ${dateFormat.format(DateTime.parse(resolution['resolvedAt']))}',
              style: TextStyle(
                color: AppTheme.success.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppealButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAppealDialog();
        },
        icon: Icon(Icons.gavel, color: AppTheme.background),
        label: const Text('Faire appel de la decision'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.background,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.textSecondary, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeadlineRow(String label, String value, bool isOverdue) {
    return Row(
      children: [
        Icon(
          isOverdue ? Icons.warning : Icons.access_time,
          color: isOverdue ? AppTheme.error : AppTheme.warning,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.warning.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: isOverdue ? AppTheme.error : AppTheme.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (isOverdue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'EXPIRE',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
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

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'Basse';
      case 'medium':
        return 'Moyenne';
      case 'high':
        return 'Haute';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }

  IconData _getDecisionIcon(String? decision) {
    switch (decision) {
      case 'favor_claimant':
      case 'full_refund':
        return Icons.check_circle;
      case 'favor_respondent':
        return Icons.cancel;
      case 'partial_refund':
        return Icons.remove_circle;
      case 'mutual_agreement':
        return Icons.handshake;
      default:
        return Icons.gavel;
    }
  }

  String _getDecisionLabel(String? decision) {
    switch (decision) {
      case 'favor_claimant':
        return 'En votre faveur';
      case 'favor_respondent':
        return 'En faveur du defenseur';
      case 'partial_refund':
        return 'Remboursement partiel';
      case 'full_refund':
        return 'Remboursement complet';
      case 'no_action':
        return 'Aucune action';
      case 'mutual_agreement':
        return 'Accord mutuel';
      default:
        return decision ?? 'Non specifie';
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDispute,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.background,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: AppTheme.textTertiary, size: 64),
            const SizedBox(height: 16),
            Text(
              'Litige introuvable',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ce litige n\'existe pas ou a ete supprime.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
