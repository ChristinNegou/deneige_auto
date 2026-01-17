import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../ai_features/domain/entities/ai_status.dart';
import '../../../ai_features/domain/entities/demand_prediction.dart';
import '../../../ai_features/domain/entities/dispute_analysis.dart';
import '../../../ai_features/presentation/bloc/ai_features_bloc.dart';
import '../../../ai_features/presentation/bloc/ai_features_event.dart';
import '../../../ai_features/presentation/bloc/ai_features_state.dart';

class AdminAIPage extends StatelessWidget {
  const AdminAIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AIFeaturesBloc>()
        ..add(const GetAIStatusEvent())
        ..add(const PredictDemandAllEvent())
        ..add(const GetMatchingStatsEvent())
        ..add(const GetPendingDisputesEvent()),
      child: const _AdminAIPageContent(),
    );
  }
}

class _AdminAIPageContent extends StatelessWidget {
  const _AdminAIPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy, size: 24),
            const SizedBox(width: 8),
            const Text('Intelligence Artificielle'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AIFeaturesBloc>()
                ..add(const GetAIStatusEvent())
                ..add(const PredictDemandAllEvent())
                ..add(const GetMatchingStatsEvent())
                ..add(const GetPendingDisputesEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<AIFeaturesBloc, AIFeaturesState>(
        builder: (context, state) {
          if (state.isLoadingStatus && state.aiStatus == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AIFeaturesBloc>()
                ..add(const GetAIStatusEvent())
                ..add(const PredictDemandAllEvent())
                ..add(const GetMatchingStatsEvent())
                ..add(const GetPendingDisputesEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.aiStatus != null) _buildStatusCard(state.aiStatus!),
                  const SizedBox(height: 16),
                  _buildServicesGrid(context, state),
                  const SizedBox(height: 24),
                  if (state.matchingStats != null)
                    _buildMatchingStatsCard(state.matchingStats!),
                  const SizedBox(height: 16),
                  if (state.demandPredictions != null &&
                      state.demandPredictions!.isNotEmpty)
                    _buildDemandPredictionsCard(state.demandPredictions!),
                  const SizedBox(height: 16),
                  if (state.pendingDisputes != null &&
                      state.pendingDisputes!.isNotEmpty)
                    _buildPendingDisputesCard(context, state.pendingDisputes!),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(AIStatus status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  Icons.smart_toy,
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
                      'Statut IA',
                      style: TextStyle(
                        color: AppTheme.background.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      status.allServicesActive
                          ? 'Tous les services actifs'
                          : '${status.activeServicesCount}/5 services actifs',
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status.allServicesActive
                      ? AppTheme.success
                      : AppTheme.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status.allServicesActive
                          ? Icons.check_circle
                          : Icons.warning,
                      color: AppTheme.background,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.allServicesActive ? 'OK' : 'Partiel',
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
          const SizedBox(height: 16),
          Text(
            'Modele: ${status.modelVersion.isNotEmpty ? status.modelVersion : "Claude"}',
            style: TextStyle(
              color: AppTheme.background.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context, AIFeaturesState state) {
    final status = state.aiStatus;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildServiceCard(
          'Estimation Prix',
          Icons.calculate_outlined,
          status?.pricingEnabled ?? false,
          AppTheme.success,
        ),
        _buildServiceCard(
          'Analyse Photos',
          Icons.photo_camera_outlined,
          status?.photoAnalysisEnabled ?? false,
          AppTheme.info,
        ),
        _buildServiceCard(
          'Smart Matching',
          Icons.connect_without_contact,
          status?.smartMatchingEnabled ?? false,
          AppTheme.warning,
        ),
        _buildServiceCard(
          'Prediction Demande',
          Icons.trending_up,
          status?.demandPredictionEnabled ?? false,
          AppTheme.primary2,
        ),
        _buildServiceCard(
          'Analyse Litiges',
          Icons.gavel,
          status?.disputeAnalysisEnabled ?? false,
          AppTheme.error,
        ),
        _buildServiceCard(
          'Chat IA',
          Icons.chat_bubble_outline,
          true,
          AppTheme.secondary,
        ),
      ],
    );
  }

  Widget _buildServiceCard(
      String name, IconData icon, bool enabled, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            enabled ? color.withValues(alpha: 0.1) : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.3) : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      enabled ? color.withValues(alpha: 0.2) : AppTheme.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : AppTheme.textTertiary,
                  size: 20,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: enabled ? AppTheme.success : AppTheme.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled ? AppTheme.textPrimary : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingStatsCard(MatchingStats stats) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.connect_without_contact,
                    color: AppTheme.warning, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Smart Matching',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  stats.totalMatches.toString(),
                  Icons.numbers,
                  AppTheme.textSecondary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Reussis',
                  stats.successfulMatches.toString(),
                  Icons.check_circle,
                  AppTheme.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Score moyen',
                  stats.averageScore.toStringAsFixed(0),
                  Icons.star,
                  AppTheme.warning,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Acceptation',
                  '${(stats.acceptanceRate * 100).toStringAsFixed(0)}%',
                  Icons.thumb_up,
                  AppTheme.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
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

  Widget _buildDemandPredictionsCard(List<DemandPrediction> predictions) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary2.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.trending_up, color: AppTheme.primary2, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Predictions de Demande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...predictions
              .take(5)
              .map((prediction) => _buildPredictionItem(prediction)),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(DemandPrediction prediction) {
    final demandColor = _getDemandColor(prediction.predictedDemand);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: demandColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                prediction.weatherIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.zone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${prediction.snowDepthForecast ?? 0}cm de neige prevus',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: demandColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prediction.predictedDemand.icon,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  prediction.predictedDemand.label,
                  style: TextStyle(
                    color: demandColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDemandColor(DemandLevel level) {
    switch (level) {
      case DemandLevel.low:
        return AppTheme.success;
      case DemandLevel.medium:
        return AppTheme.warning;
      case DemandLevel.high:
        return AppTheme.primary2;
      case DemandLevel.urgent:
        return AppTheme.error;
    }
  }

  Widget _buildPendingDisputesCard(
      BuildContext context, List<Map<String, dynamic>> disputes) {
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.gavel, color: AppTheme.error, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Litiges en attente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${disputes.length}',
                  style: TextStyle(
                    color: AppTheme.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...disputes
              .take(3)
              .map((dispute) => _buildDisputeItem(context, dispute)),
          if (disputes.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to disputes page
                  },
                  child: Text(
                    'Voir ${disputes.length - 3} autres litiges',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisputeItem(BuildContext context, Map<String, dynamic> dispute) {
    return InkWell(
      onTap: () =>
          _showDisputeAnalysisDialog(context, dispute['_id'] as String? ?? ''),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.errorLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.report_problem, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dispute['type']?.toString() ?? 'Litige',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    dispute['description']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.smart_toy,
              color: AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDisputeAnalysisDialog(BuildContext context, String disputeId) {
    if (disputeId.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) =>
            sl<AIFeaturesBloc>()..add(AnalyzeDisputeEvent(disputeId)),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.smart_toy, color: AppTheme.primary),
              const SizedBox(width: 12),
              const Text('Analyse IA'),
            ],
          ),
          content: BlocBuilder<AIFeaturesBloc, AIFeaturesState>(
            builder: (context, state) {
              if (state.isAnalyzingDispute) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state.disputeAnalysisError != null) {
                return Text(
                  'Erreur: ${state.disputeAnalysisError}',
                  style: TextStyle(color: AppTheme.error),
                );
              }

              if (state.disputeAnalysis == null) {
                return const Text('Aucune analyse disponible');
              }

              final analysis = state.disputeAnalysis!;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnalysisScore(analysis),
                    const SizedBox(height: 16),
                    _buildAnalysisRecommendation(analysis),
                    if (analysis.reasoning != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        analysis.reasoning!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisScore(DisputeAnalysis analysis) {
    final scoreColor = _getScoreColor(analysis.evidenceStrength);
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: analysis.evidenceStrength / 100,
                strokeWidth: 6,
                backgroundColor: scoreColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(scoreColor),
              ),
            ),
            Text(
              '${analysis.evidenceStrength}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Force des preuves',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                analysis.evidenceLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisRecommendation(DisputeAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommandation IA',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            analysis.decisionLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          if (analysis.suggestedRefundPercent > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Remboursement suggere: ${analysis.suggestedRefundPercent}%',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }
}
