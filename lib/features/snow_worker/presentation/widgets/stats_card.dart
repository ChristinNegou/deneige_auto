import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final int completed;
  final int inProgress;
  final double earnings;
  final double rating;

  const StatsRow({
    super.key,
    required this.completed,
    required this.inProgress,
    required this.earnings,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              title: l10n.worker_statsCompleted,
              value: completed.toString(),
              icon: Icons.check_circle,
              color: AppTheme.success,
              subtitle: l10n.worker_statsToday,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: l10n.worker_statsInProgress,
              value: inProgress.toString(),
              icon: Icons.engineering,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: l10n.worker_statsRevenue,
              value: '${earnings.toStringAsFixed(0)}\$',
              icon: Icons.attach_money,
              color: AppTheme.info,
              subtitle: l10n.worker_statsToday,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: l10n.worker_statsRating,
              value: rating > 0 ? rating.toStringAsFixed(1) : '-',
              icon: Icons.star,
              color: AppTheme.statusEnRoute,
            ),
          ),
        ],
      ),
    );
  }
}
