import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/worker_stats.dart';
import '../bloc/worker_stats_bloc.dart';

enum _Period { today, last7, month }

/// Revenus du deneigeur : ce qu'il a gagne (sa part + pourboires) sur la
/// periode choisie, ses gains jour par jour et ses totaux depuis le debut.
class WorkerEarningsTab extends StatefulWidget {
  const WorkerEarningsTab({super.key});

  @override
  State<WorkerEarningsTab> createState() => _WorkerEarningsTabState();
}

class _WorkerEarningsTabState extends State<WorkerEarningsTab>
    with AutomaticKeepAliveClientMixin {
  _Period _period = _Period.today;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<WorkerStatsBloc>()
      ..add(const LoadStats())
      ..add(const LoadEarnings());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: BlocBuilder<WorkerStatsBloc, WorkerStatsState>(
        builder: (context, state) {
          if (state is WorkerStatsError) {
            return _ErrorView(message: state.message, onRetry: _loadData);
          }
          if (state is! WorkerStatsLoaded) {
            return Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text(l10n.earnings_myEarnings, style: AppTheme.headlineLarge),
                const SizedBox(height: 16),
                _PeriodSelector(
                  value: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 16),
                _buildHero(l10n, state.stats, state.earnings),
                const SizedBox(height: 8),
                Text(l10n.earningsT_share, style: AppTheme.bodySmall),
                if (_period == _Period.today)
                  ..._buildTodayExtras(l10n, state.stats.today),
                if (_period == _Period.last7 && state.earnings != null) ...[
                  const SizedBox(height: 20),
                  _DailyChart(earnings: state.earnings!),
                ],
                if (_period == _Period.month) ...[
                  const SizedBox(height: 20),
                  _buildAllTime(l10n, state.stats.allTime),
                ],
                const SizedBox(height: 20),
                _HistoryLink(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Panneau bleu nuit : le total gagne (part + pourboires) sur la periode.
  Widget _buildHero(
      AppLocalizations l10n, WorkerStats stats, EarningsBreakdown? earnings) {
    late final String label;
    late final double pay;
    late final double tips;
    late final int jobs;
    switch (_period) {
      case _Period.today:
        label = l10n.earningsT_today;
        pay = stats.today.earnings;
        tips = stats.today.tips;
        jobs = stats.today.completed;
      case _Period.last7:
        label = l10n.earningsT_last7;
        pay = earnings?.summary.totalEarnings ?? stats.week.earnings;
        tips = earnings?.summary.totalTips ?? stats.week.tips;
        jobs = earnings?.summary.totalJobs ?? stats.week.completed;
      case _Period.month:
        label = l10n.earningsT_month;
        pay = stats.month.earnings;
        tips = stats.month.tips;
        jobs = stats.month.completed;
    }

    final onPrimary = AppTheme.onPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.labelMedium
                  .copyWith(color: onPrimary.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Text(
            formatMoney(context, pay + tips),
            style: TextStyle(
              color: onPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tips > 0
                ? '${l10n.earningsT_jobs(jobs)}, ${l10n.earningsT_tipsIncluded(formatMoney(context, tips))}'
                : l10n.earningsT_jobs(jobs),
            style: AppTheme.bodyMedium
                .copyWith(color: onPrimary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTodayExtras(AppLocalizations l10n, TodayStats today) {
    final lines = [
      if (today.inProgress > 0) l10n.earningsT_ongoing(today.inProgress),
      if (today.assigned > 0) l10n.earningsT_toDo(today.assigned),
    ];
    if (lines.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(line, style: AppTheme.bodyMedium),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _buildAllTime(AppLocalizations l10n, AllTimeStats allTime) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textSecondary))),
              Text(value,
                  style: AppTheme.labelLarge.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.earningsT_allTime, style: AppTheme.headlineSmall),
          const SizedBox(height: 6),
          row(l10n.earnings_totalJobs, '${allTime.completed}'),
          row(l10n.earnings_totalEarnings,
              formatMoney(context, allTime.earnings + allTime.tips)),
          row(l10n.earnings_totalTips, formatMoney(context, allTime.tips)),
          row(
            l10n.earnings_averageRating,
            allTime.averageRating > 0
                ? '${allTime.averageRating.toStringAsFixed(1)} / 5 (${allTime.totalRatings})'
                : l10n.earningsT_noRating,
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _Period value;
  final ValueChanged<_Period> onChanged;
  const _PeriodSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      _Period.today: l10n.earningsT_today,
      _Period.last7: l10n.earningsT_last7,
      _Period.month: l10n.earningsT_month,
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          for (final period in _Period.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        period == value ? AppTheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[period]!,
                    style: AppTheme.labelMedium.copyWith(
                      color: period == value
                          ? AppTheme.textPrimary
                          : AppTheme.textTertiary,
                      fontWeight:
                          period == value ? FontWeight.w800 : FontWeight.w600,
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

/// Gains des 7 derniers jours, une barre par jour (les jours sans gain
/// restent visibles). Toucher une barre affiche son montant.
class _DailyChart extends StatefulWidget {
  final EarningsBreakdown earnings;
  const _DailyChart({required this.earnings});

  @override
  State<_DailyChart> createState() => _DailyChartState();
}

class _DailyChartState extends State<_DailyChart> {
  int _selected = 6; // aujourd'hui

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final byDate = {
      for (final d in widget.earnings.daily) d.date.substring(0, 10): d
    };
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final date = DateTime(today.year, today.month, today.day - 6 + i);
      final key = DateFormat('yyyy-MM-dd').format(date);
      return (date, byDate[key]?.total ?? 0.0, byDate[key]?.jobsCount ?? 0);
    });
    final max = days.map((d) => d.$2).fold<double>(0, (a, b) => b > a ? b : a);
    final selected = days[_selected];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.earningsT_perDay, style: AppTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${toBeginningOfSentenceCase(DateFormat.MMMEd(locale).format(selected.$1))} : '
            '${formatMoney(context, selected.$2)}, ${l10n.earningsT_jobs(selected.$3)}',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: max > 0
                                  ? (days[i].$2 / max * 96).clamp(3.0, 96.0)
                                  : 3,
                              decoration: BoxDecoration(
                                color: i == _selected
                                    ? AppTheme.primary
                                    : AppTheme.primary.withValues(alpha: 0.35),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat.E(locale)
                                  .format(days[i].$1)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: AppTheme.labelSmall.copyWith(
                                color: i == _selected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: () => Navigator.pushNamed(context, AppRoutes.workerHistory),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: AppTheme.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.earnings_jobHistory, style: AppTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(l10n.earnings_viewAllJobs, style: AppTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: child,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 40, color: AppTheme.textTertiary),
            const SizedBox(height: 12),
            Text(message,
                style: AppTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
              child: Text(AppLocalizations.of(context)!.earnings_retry),
            ),
          ],
        ),
      ),
    );
  }
}
