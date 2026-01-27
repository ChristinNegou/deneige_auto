import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/photo_analysis.dart';

/// Widget pour afficher les résultats d'analyse de photos IA
class PhotoAnalysisCard extends StatelessWidget {
  final PhotoAnalysis analysis;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const PhotoAnalysisCard({
    super.key,
    required this.analysis,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  Color get _scoreColor {
    // Si photo suspecte ou pas de véhicule, toujours rouge
    if (analysis.isSuspiciousPhoto || !analysis.vehicleDetected) {
      return AppTheme.error;
    }
    if (analysis.overallScore >= 80) return AppTheme.success;
    if (analysis.overallScore >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
        border: Border.all(
          color: _scoreColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec score
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Score circulaire
                  _buildScoreCircle(),
                  const SizedBox(width: 16),
                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.smart_toy,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)!.ai_analysisLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis.scoreLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: _scoreColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge type véhicule
                  if (analysis.vehicleDetected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            analysis.vehicleTypeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Alerte critique
                  if (analysis.hasCriticalIssues) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error,
                            size: 12,
                            color: AppTheme.error,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            AppLocalizations.of(context)!.ai_alert,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else if (analysis.hasIssues) ...[
                    // Indicateur d'issues (warning)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 12,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${analysis.issues.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Flèche expand
                  if (onToggleExpand != null)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.textTertiary,
                    ),
                ],
              ),
            ),
          ),

          // Contenu détaillé
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alerte critique si photo suspecte ou pas de véhicule
                  if (analysis.hasCriticalIssues) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error,
                                size: 18,
                                color: AppTheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.ai_criticalIssue,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (analysis.isSuspiciousPhoto)
                            Text(
                              AppLocalizations.of(context)!
                                  .ai_suspiciousPhotoFraud,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.error,
                              ),
                            ),
                          if (!analysis.vehicleDetected)
                            Text(
                              AppLocalizations.of(context)!
                                  .ai_noVehicleDetectedBullet,
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

                  // Info véhicule et neige
                  Row(
                    children: [
                      // Type véhicule
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.directions_car,
                                      size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)!.ai_vehicle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                analysis.vehicleDetected
                                    ? analysis.vehicleTypeLabel
                                    : AppLocalizations.of(context)!
                                        .ai_notDetected,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: analysis.vehicleDetected
                                      ? AppTheme.primary
                                      : AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Profondeur neige
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.ac_unit,
                                      size: 16, color: AppTheme.info),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .ai_estimatedSnow,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                analysis.estimatedSnowDepthCm != null
                                    ? '~${analysis.estimatedSnowDepthCm} cm'
                                    : 'N/A',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scores détaillés
                  Row(
                    children: [
                      Expanded(
                        child: _buildScoreItem(
                          AppLocalizations.of(context)!.ai_quality,
                          analysis.qualityScore,
                          Icons.high_quality,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildScoreItem(
                          AppLocalizations.of(context)!.ai_completeness,
                          analysis.completenessScore,
                          Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),

                  // Résumé IA
                  if (analysis.summary.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.summarize,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context)!.ai_summary,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            analysis.summary,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Issues détectées
                  if (analysis.hasIssues) ...[
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.ai_issuesDetected,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...analysis.issuesLabels.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
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
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Infos photos analysées
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 14,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!
                            .ai_photosAnalyzed(analysis.photosAnalyzed.total),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppLocalizations.of(context)!
                            .ai_analyzedOn(_formatDate(analysis.analyzedAt)),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            value: analysis.overallScore / 100,
            strokeWidth: 4,
            backgroundColor: _scoreColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
          ),
        ),
        Text(
          '${analysis.overallScore}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _scoreColor,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreItem(String label, int score, IconData icon) {
    final color = score >= 80
        ? AppTheme.success
        : (score >= 60 ? AppTheme.warning : AppTheme.error);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Widget compact pour afficher le score d'analyse
class PhotoAnalysisBadge extends StatelessWidget {
  final int score;
  final VoidCallback? onTap;

  const PhotoAnalysisBadge({
    super.key,
    required this.score,
    this.onTap,
  });

  Color get _color {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 14, color: _color),
            const SizedBox(width: 6),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
