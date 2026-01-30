import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';
import 'dispute_details_page.dart';

class MyDisputesPage extends StatefulWidget {
  const MyDisputesPage({super.key});

  @override
  State<MyDisputesPage> createState() => _MyDisputesPageState();
}

class _MyDisputesPageState extends State<MyDisputesPage> {
  late DisputeService _disputeService;
  List<Dispute> _disputes = [];
  bool _isLoading = true;
  String? _errorMessage;
  DisputeStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _disputeService = DisputeService(dioClient: sl<DioClient>());
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final disputes = await _disputeService.getMyDisputes(
        status: _filterStatus,
      );
      if (mounted) {
        setState(() {
          _disputes = disputes;
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          l10n.dispute_myDisputes,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadDisputes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(l10n.dispute_filterAll, null),
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.dispute_filterOpen, DisputeStatus.open),
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.dispute_filterUnderReview,
                      DisputeStatus.underReview),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      l10n.dispute_filterResolved, DisputeStatus.resolved),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : _disputes.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadDisputes,
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _disputes.length,
                              itemBuilder: (context, index) {
                                return _buildDisputeCard(_disputes[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DisputeStatus? status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
        _loadDisputes();
      },
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppTheme.surfaceContainer,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.border,
      ),
    );
  }

  Widget _buildDisputeCard(Dispute dispute) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisputeDetailsPage(disputeId: dispute.id),
          ),
        ).then((_) => _loadDisputes());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(dispute.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(dispute.type),
                    color: _getTypeColor(dispute.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dispute.type.label,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(dispute.createdAt),
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(dispute.status),
              ],
            ),
            const SizedBox(height: 12),

            // Description preview
            Text(
              dispute.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),

            // Amount claimed
            if (dispute.claimedAmount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.infoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: AppTheme.info,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.dispute_claimedAmountValue(
                          dispute.claimedAmount.toStringAsFixed(2)),
                      style: TextStyle(
                        color: AppTheme.info,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Resolution info if resolved
            if (dispute.status == DisputeStatus.resolved &&
                dispute.resolution != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gavel,
                      color: AppTheme.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.dispute_decisionLabel(_getDecisionLabel(
                            dispute.resolution!['decision'], context)),
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Arrow indicator
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  l10n.dispute_viewDetails,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.primary,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DisputeStatus status) {
    Color color;
    String label = status.label;

    switch (status) {
      case DisputeStatus.open:
        color = AppTheme.warning;
        break;
      case DisputeStatus.underReview:
        color = AppTheme.info;
        break;
      case DisputeStatus.pendingResponse:
        color = AppTheme.warning;
        break;
      case DisputeStatus.resolved:
        color = AppTheme.success;
        break;
      case DisputeStatus.closed:
        color = AppTheme.textTertiary;
        break;
      case DisputeStatus.appealed:
        color = AppTheme.primary;
        break;
      case DisputeStatus.escalated:
        color = AppTheme.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
        return AppTheme.error;
      case DisputeType.incompleteWork:
        return AppTheme.warning;
      case DisputeType.qualityIssue:
        return AppTheme.warning;
      case DisputeType.lateArrival:
        return AppTheme.warning;
      case DisputeType.damage:
        return AppTheme.error;
      case DisputeType.wrongLocation:
        return AppTheme.error;
      case DisputeType.overcharge:
        return AppTheme.error;
      case DisputeType.unprofessional:
        return AppTheme.warning;
      case DisputeType.other:
        return AppTheme.textSecondary;
    }
  }

  String _getDecisionLabel(String? decision, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (decision) {
      case 'favor_claimant':
        return l10n.dispute_decisionFavorClaimant;
      case 'favor_respondent':
        return l10n.dispute_decisionFavorRespondent;
      case 'partial_refund':
        return l10n.dispute_decisionPartialRefund;
      case 'full_refund':
        return l10n.dispute_decisionFullRefund;
      case 'no_action':
        return l10n.dispute_decisionNoAction;
      case 'mutual_agreement':
        return l10n.dispute_decisionMutualAgreement;
      default:
        return decision ?? l10n.common_notSpecified;
    }
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIllustration(
              type: IllustrationType.emptyDisputes,
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.dispute_noDisputes,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dispute_noDisputesMessage,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.common_error,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? l10n.common_errorOccurred,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDisputes,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.common_retry),
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
}
