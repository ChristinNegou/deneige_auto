import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/photo_analysis.dart';
import '../bloc/ai_features_bloc.dart';
import '../bloc/ai_features_event.dart';
import '../bloc/ai_features_state.dart';

/// Dialog qui affiche l'analyse IA de la photo apres upload
class AIPhotoFeedbackDialog extends StatelessWidget {
  final String reservationId;
  final VoidCallback onDismiss;
  final VoidCallback? onRetake;

  const AIPhotoFeedbackDialog({
    super.key,
    required this.reservationId,
    required this.onDismiss,
    this.onRetake,
  });

  static void show(
    BuildContext context, {
    required String reservationId,
    required VoidCallback onDismiss,
    VoidCallback? onRetake,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) =>
            sl<AIFeaturesBloc>()..add(AnalyzePhotosEvent(reservationId)),
        child: AIPhotoFeedbackDialog(
          reservationId: reservationId,
          onDismiss: onDismiss,
          onRetake: onRetake,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIFeaturesBloc, AIFeaturesState>(
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: state.isAnalyzingPhotos
                ? _buildLoadingState(context)
                : state.photoAnalysisError != null
                    ? _buildErrorState(context, state.photoAnalysisError!)
                    : state.photoAnalysis != null
                        ? _buildResultState(context, state.photoAnalysis!)
                        : _buildLoadingState(context),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.ai_analysisInProgress,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.ai_qualityVerification,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warning,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.ai_analysisUnavailable,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.ai_verificationLater,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.reservation_continue),
          ),
        ),
      ],
    );
  }

  Widget _buildResultState(BuildContext context, PhotoAnalysis analysis) {
    final scoreColor = _getScoreColor(analysis.overallScore);
    final isGoodScore = analysis.overallScore >= 70;
    final hasCriticalAlert =
        analysis.isSuspiciousPhoto || !analysis.vehicleDetected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Alerte critique si photo suspecte ou pas de véhicule
        if (hasCriticalAlert) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: AppTheme.error.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: AppTheme.error,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.ai_photoAlert,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (analysis.isSuspiciousPhoto)
                  Text(
                    AppLocalizations.of(context)!.ai_suspiciousPhoto,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.error,
                    ),
                  ),
                if (!analysis.vehicleDetected)
                  Text(
                    AppLocalizations.of(context)!.ai_noVehicleDetected,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.error,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Score circle
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: analysis.overallScore / 100,
                strokeWidth: 8,
                backgroundColor: scoreColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${analysis.overallScore}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Score label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGoodScore ? Icons.check_circle : Icons.info_outline,
                color: scoreColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                analysis.scoreLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Info véhicule détecté et neige
        if (analysis.vehicleDetected) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Badge type véhicule
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      analysis.vehicleTypeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge profondeur neige si disponible
              if (analysis.estimatedSnowDepthCm != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: AppTheme.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ac_unit,
                        size: 14,
                        color: AppTheme.info,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.ai_snowDepth(
                            analysis.estimatedSnowDepthCm!.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.info,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Summary
        if (analysis.summary.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    analysis.summary,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Issues if any
        if (analysis.hasIssues) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber,
                        size: 16, color: AppTheme.warning),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.ai_improvementPoints,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...analysis.issuesLabels.take(3).map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                issue,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Action buttons
        Row(
          children: [
            if (onRetake != null && !isGoodScore) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetake!();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.warning),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.ai_retakePhoto,
                    style: TextStyle(color: AppTheme.warning),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isGoodScore ? AppTheme.success : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: Text(isGoodScore
                    ? AppLocalizations.of(context)!.ai_perfect
                    : AppLocalizations.of(context)!.reservation_continue),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }
}
