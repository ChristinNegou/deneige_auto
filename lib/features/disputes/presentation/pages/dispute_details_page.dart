import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l10n.dispute_appeal,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dispute_appealExplanation,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.dispute_appealJustificationHint,
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
              l10n.common_cancel,
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
                    content: Text(l10n.dispute_minCharsRequired),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
            ),
            child: Text(l10n.dispute_submitAppeal),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _submitAppeal(result);
    }
  }

  Future<void> _submitAppeal(String reason) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      await _disputeService.appealDispute(
        disputeId: widget.disputeId,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dispute_appealSubmitted),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadDispute();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dispute_cannotSendResponseRetry),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToAddEvidence() {
    Navigator.pushNamed(
      context,
      AppRoutes.addEvidence,
      arguments: {
        'disputeId': widget.disputeId,
        'disputeStatus': _dispute!.status.value,
      },
    ).then((result) {
      if (result == true) {
        _loadDispute();
      }
    });
  }

  void _navigateToRespond() {
    Navigator.pushNamed(
      context,
      AppRoutes.respondDispute,
      arguments: {
        'disputeId': widget.disputeId,
        'disputeType': _dispute!.type.label,
        'disputeDescription': _dispute!.description,
        'responseDeadline': _dispute!.responseDeadline?.toIso8601String(),
      },
    ).then((result) {
      if (result == true) {
        _loadDispute();
      }
    });
  }

  void _showPhotoViewer(List<DisputePhoto> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      photos[index].url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: AppTheme.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          l10n.dispute_details,
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

                            // Evidence Photos Card
                            if (_dispute!.hasEvidence) ...[
                              _buildEvidenceCard(),
                              const SizedBox(height: 16),
                            ],

                            // Response Card (from worker)
                            if (_dispute!.hasResponse) ...[
                              _buildResponseCard(),
                              const SizedBox(height: 16),
                            ],

                            // Timeline Card
                            if (_dispute!.responseDeadline != null ||
                                _dispute!.resolutionDeadline != null)
                              _buildDeadlinesCard(),

                            // AI Analysis Card (for admin)
                            if (_dispute!.hasAIAnalysis) ...[
                              const SizedBox(height: 16),
                              _buildAIAnalysisCard(),
                            ],

                            // Resolution Card
                            if (_dispute!.resolution != null) ...[
                              const SizedBox(height: 16),
                              _buildResolutionCard(),
                            ],

                            // Action Buttons
                            const SizedBox(height: 24),
                            _buildActionButtons(),

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
                    AppLocalizations.of(context)!.dispute_claimedAmountValue(
                        dispute.claimedAmount.toStringAsFixed(2)),
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
    final l10n = AppLocalizations.of(context)!;
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
                l10n.common_description,
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
            l10n.dispute_openDate,
            dateFormat.format(dispute.createdAt),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.priority_high,
            l10n.dispute_priority,
            _getPriorityLabel(dispute.priority, context),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesCard() {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.dispute_deadlines,
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
              l10n.dispute_responseExpectedBefore,
              dateFormat.format(dispute.responseDeadline!),
              dispute.responseDeadline!.isBefore(DateTime.now()),
            ),
            const SizedBox(height: 8),
          ],
          if (dispute.resolutionDeadline != null)
            _buildDeadlineRow(
              l10n.dispute_resolutionExpectedBefore,
              dateFormat.format(dispute.resolutionDeadline!),
              dispute.resolutionDeadline!.isBefore(DateTime.now()),
            ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard() {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.dispute_resolution,
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
                        l10n.dispute_decision,
                        style: TextStyle(
                          color: AppTheme.success.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _getDecisionLabel(resolution['decision'], context),
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
                  l10n.dispute_refundAmount(
                      (resolution['refundAmount'] as num).toStringAsFixed(2)),
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
              l10n.dispute_resolvedOn(
                  dateFormat.format(DateTime.parse(resolution['resolvedAt']))),
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

  Widget _buildEvidenceCard() {
    final l10n = AppLocalizations.of(context)!;
    final dispute = _dispute!;
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
              Icon(Icons.photo_library, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.dispute_evidenceCount(dispute.evidencePhotos.length),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: dispute.evidencePhotos.length,
            itemBuilder: (context, index) {
              final photo = dispute.evidencePhotos[index];
              return GestureDetector(
                onTap: () => _showPhotoViewer(dispute.evidencePhotos, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photo.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppTheme.surfaceContainer,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.surfaceContainer,
                        child: Icon(
                          Icons.broken_image,
                          color: AppTheme.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard() {
    final l10n = AppLocalizations.of(context)!;
    final dispute = _dispute!;
    final response = dispute.response!;
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
              Icon(Icons.reply, color: AppTheme.info),
              const SizedBox(width: 8),
              Text(
                l10n.dispute_respondentResponse,
                style: TextStyle(
                  color: AppTheme.textPrimary,
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
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              response['text'] ?? l10n.dispute_noResponse,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (response['submittedAt'] != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.dispute_submittedOn(
                  dateFormat.format(DateTime.parse(response['submittedAt']))),
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
          if (dispute.responsePhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.dispute_attachedPhotos,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dispute.responsePhotos.length,
                itemBuilder: (context, index) {
                  final photo = dispute.responsePhotos[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          _showPhotoViewer(dispute.responsePhotos, index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photo.url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    final l10n = AppLocalizations.of(context)!;
    final analysis = _dispute!.aiAnalysis!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.psychology, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dispute_aiAnalysis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (analysis.analyzedAt != null)
                      Text(
                        dateFormat.format(analysis.analyzedAt!),
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (analysis.confidence != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.dispute_confidencePercent(
                        (analysis.confidence! * 100).toInt()),
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Evidence Strength
          if (analysis.evidenceStrength != null) ...[
            _buildAnalysisRow(
              l10n.dispute_evidenceStrength,
              '${analysis.evidenceStrength}%',
              _getStrengthColor(analysis.evidenceStrength!),
            ),
            const SizedBox(height: 8),
          ],

          // Recommended Decision
          if (analysis.recommendedDecision != null) ...[
            _buildAnalysisRow(
              l10n.dispute_recommendedDecision,
              _getDecisionLabel(analysis.recommendedDecision, context),
              AppTheme.info,
            ),
            const SizedBox(height: 8),
          ],

          // Suggested Refund
          if (analysis.suggestedRefundPercent != null &&
              analysis.suggestedRefundPercent! > 0) ...[
            _buildAnalysisRow(
              l10n.dispute_suggestedRefund,
              '${analysis.suggestedRefundPercent}%',
              AppTheme.success,
            ),
            const SizedBox(height: 8),
          ],

          // Reasoning
          if (analysis.reasoning != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.dispute_reasoning,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              analysis.reasoning!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],

          // Risk Factors
          if (analysis.riskFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.dispute_riskFactors,
              style: TextStyle(
                color: AppTheme.warning,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: analysis.riskFactors.map((factor) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    factor,
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Key Findings
          if (analysis.keyFindings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.dispute_keyFindings,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.keyFindings
                .map((finding) => _buildKeyFindingRow(finding)),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyFindingRow(AIKeyFinding finding) {
    Color impactColor;
    IconData impactIcon;
    switch (finding.impact) {
      case 'favorable_claimant':
        impactColor = AppTheme.success;
        impactIcon = Icons.arrow_upward;
        break;
      case 'favorable_respondent':
        impactColor = AppTheme.error;
        impactIcon = Icons.arrow_downward;
        break;
      default:
        impactColor = AppTheme.textTertiary;
        impactIcon = Icons.remove;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(impactIcon, color: impactColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.category,
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  finding.finding,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStrengthColor(int strength) {
    if (strength >= 70) return AppTheme.success;
    if (strength >= 40) return AppTheme.warning;
    return AppTheme.error;
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;
    final dispute = _dispute!;
    final List<Widget> buttons = [];

    // Bouton d'ajout de preuves (si litige ouvert)
    if (dispute.isOpen) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _navigateToAddEvidence,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(l10n.dispute_addEvidence),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // Bouton de réponse (si le litige attend une réponse et l'utilisateur peut répondre)
    if (dispute.canRespond && !dispute.hasResponse) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 12));
      }
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _navigateToRespond,
            icon: Icon(Icons.reply, color: AppTheme.background),
            label: Text(l10n.dispute_respond),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // Bouton d'appel (si résolu)
    if (dispute.canAppeal) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 12));
      }
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAppealDialog();
            },
            icon: Icon(Icons.gavel, color: AppTheme.background),
            label: Text(l10n.dispute_appeal),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: buttons);
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.dispute_expired,
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

  String _getPriorityLabel(String priority, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (priority) {
      case 'low':
        return l10n.dispute_priorityLow;
      case 'medium':
        return l10n.dispute_priorityMedium;
      case 'high':
        return l10n.dispute_priorityHigh;
      case 'urgent':
        return l10n.dispute_priorityUrgent;
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

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 64),
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
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDispute,
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

  Widget _buildNotFoundState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: AppTheme.textTertiary, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.dispute_notFound,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dispute_notFoundMessage,
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
