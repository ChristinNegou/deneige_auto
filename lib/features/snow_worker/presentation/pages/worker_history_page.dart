import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/worker_job.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../widgets/shimmer_loading.dart';

enum _Filter { all, completed, cancelled }

/// Historique des deneigements termines et annules, groupes par mois avec
/// ce que le deneigeur y a gagne.
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
  _Filter _filter = _Filter.all;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent * 0.9) {
        context.read<WorkerJobsBloc>().add(const LoadMoreHistory());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Date de fin : fin du travail, ou heure prevue pour une annulation.
  DateTime _dateOf(WorkerJob job) =>
      (job.completedAt ?? job.departureTime).toLocal();

  List<WorkerJob> _filtered(List<WorkerJob> jobs) => switch (_filter) {
        _Filter.all => jobs,
        _Filter.completed =>
          jobs.where((j) => j.status == JobStatus.completed).toList(),
        _Filter.cancelled =>
          jobs.where((j) => j.status == JobStatus.cancelled).toList(),
      };

  double _earned(WorkerJob job) => job.status == JobStatus.completed
      ? job.workerEarnings + (job.tipAmount ?? 0)
      : 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.worker_history, style: AppTheme.labelLarge),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                for (final (filter, label) in [
                  (_Filter.all, l10n.worker_filterAll),
                  (_Filter.completed, l10n.historyW_completed),
                  (_Filter.cancelled, l10n.historyW_cancelled),
                ]) ...[
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == filter,
                    showCheckmark: false,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    labelStyle: AppTheme.labelMedium.copyWith(
                      color: _filter == filter
                          ? AppTheme.onPrimary
                          : AppTheme.textPrimary,
                    ),
                    side: BorderSide(
                        color: _filter == filter
                            ? AppTheme.primary
                            : AppTheme.border),
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<WorkerJobsBloc, WorkerJobsState>(
              builder: (context, state) {
                if (state is WorkerJobsError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<WorkerJobsBloc>()
                        .add(const LoadJobHistory()),
                  );
                }
                if (state is! JobHistoryLoaded) return const _Skeleton();

                final jobs = _filtered(state.jobs);
                if (jobs.isEmpty) return _EmptyView();

                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () async => context
                      .read<WorkerJobsBloc>()
                      .add(const LoadJobHistory()),
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      ..._buildMonths(jobs),
                      if (state.hasMore)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppTheme.primary),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Un titre par mois (avec le total gagne), puis ses deneigements.
  List<Widget> _buildMonths(List<WorkerJob> jobs) {
    final locale = Localizations.localeOf(context).toString();
    final months = <String, List<WorkerJob>>{};
    for (final job in jobs) {
      final key = DateFormat('yyyy-MM').format(_dateOf(job));
      months.putIfAbsent(key, () => []).add(job);
    }

    return [
      for (final entry in months.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  toBeginningOfSentenceCase(DateFormat.yMMMM(locale)
                      .format(_dateOf(entry.value.first)))!,
                  style: AppTheme.headlineSmall,
                ),
              ),
              Text(
                formatMoney(context,
                    entry.value.fold(0.0, (sum, j) => sum + _earned(j))),
                style: AppTheme.labelLarge.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < entry.value.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppTheme.divider),
                _HistoryRow(
                  job: entry.value[i],
                  date: _dateOf(entry.value[i]),
                  earned: _earned(entry.value[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    ];
  }
}

class _HistoryRow extends StatelessWidget {
  final WorkerJob job;
  final DateTime date;
  final double earned;

  const _HistoryRow({
    required this.job,
    required this.date,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final cancelled = job.status == JobStatus.cancelled;
    final tip = job.tipAmount ?? 0;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${toBeginningOfSentenceCase(DateFormat.MMMEd(locale).format(date))}, '
                  '${DateFormat.Hm(locale).format(date)}',
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(job.displayAddress,
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(job.vehicle.displayName, style: AppTheme.bodySmall),
                if (job.rating != null && job.rating! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var s = 1; s <= 5; s++)
                        Icon(
                          s <= job.rating!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 15,
                          color: AppTheme.warning,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (cancelled)
                Text(l10n.historyW_cancelledLabel,
                    style: AppTheme.labelMedium
                        .copyWith(color: AppTheme.textTertiary))
              else
                Text(
                  formatMoney(context, earned),
                  style: AppTheme.headlineSmall.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              if (!cancelled && tip > 0)
                Text(l10n.historyW_tip(formatMoney(context, tip)),
                    style: AppTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (var i = 0; i < 5; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerLoading(
                width: double.infinity, height: 72, borderRadius: 16),
          ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: [
        const SizedBox(height: 60),
        AppIllustration(
            type: IllustrationType.emptyWorkerHistory, width: 140, height: 140),
        const SizedBox(height: 20),
        Text(l10n.worker_noHistory,
            style: AppTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(l10n.worker_completedJobsAppearHere,
            style: AppTheme.bodySmall, textAlign: TextAlign.center),
      ],
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
              child: Text(AppLocalizations.of(context)!.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}
