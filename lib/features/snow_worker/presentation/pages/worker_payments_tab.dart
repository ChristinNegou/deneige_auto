import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/worker_stripe_service.dart';

/// Paiements du deneigeur : etat de son compte Stripe, solde et versements
/// recus. La configuration se fait chez Stripe ; l'ecran se met a jour au
/// retour dans l'app.
class WorkerPaymentsTab extends StatefulWidget {
  const WorkerPaymentsTab({super.key});

  @override
  State<WorkerPaymentsTab> createState() => _WorkerPaymentsTabState();
}

enum _AccountState { none, incomplete, verifying, active }

class _WorkerPaymentsTabState extends State<WorkerPaymentsTab>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final WorkerStripeService _stripe;

  bool _loading = true;
  bool _busy = false;
  String? _error;
  _AccountState _account = _AccountState.none;
  double _available = 0;
  double _pendingBalance = 0;
  List<Map<String, dynamic>> _transfers = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stripe = WorkerStripeService(dioClient: sl<DioClient>());
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Retour depuis Stripe (navigateur) : l'etat du compte a pu changer.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _load(quiet: true);
  }

  String _messageOf(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) return data['message'];
    }
    return AppLocalizations.of(context)!.paymentsW_loadError;
  }

  Future<void> _load({bool quiet = false}) async {
    if (!mounted) return;
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final status = await _stripe.getAccountStatus();
      final hasAccount = status['hasAccount'] == true;
      final complete = status['isComplete'] == true;
      final payouts = status['payoutsEnabled'] == true;
      final charges = status['chargesEnabled'] == true;

      var account = _AccountState.none;
      if (hasAccount && payouts && charges) {
        account = _AccountState.active;
      } else if (hasAccount && (complete || charges)) {
        account = _AccountState.verifying;
      } else if (hasAccount) {
        account = _AccountState.incomplete;
      }

      var available = 0.0;
      var pending = 0.0;
      var transfers = <Map<String, dynamic>>[];
      if (account == _AccountState.active) {
        final results = await Future.wait([
          _stripe.getBalance(),
          _stripe.getPayoutHistory(),
        ]);
        final balance = results[0] as Map<String, dynamic>;
        available = (balance['available'] as num?)?.toDouble() ?? 0;
        pending = (balance['pending'] as num?)?.toDouble() ?? 0;
        transfers = results[1] as List<Map<String, dynamic>>;
      }

      if (!mounted) return;
      setState(() {
        _account = account;
        _available = available;
        _pendingBalance = pending;
        _transfers = transfers;
        _error = null;
      });
    } catch (e) {
      if (mounted && !quiet) setState(() => _error = _messageOf(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(Future<String?> Function() getUrl) async {
    setState(() => _busy = true);
    try {
      final url = await getUrl();
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageOf(e)), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setup() => _openUrl(() async =>
      (await _stripe.createConnectAccount())['onboardingUrl'] as String?);

  void _openStripe() => _openUrl(_stripe.getDashboardLink);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(l10n.worker_payments, style: AppTheme.headlineLarge),
            const SizedBox(height: 16),
            if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else ...[
              if (_account == _AccountState.active) ...[
                _buildBalance(l10n),
                const SizedBox(height: 16),
              ],
              _buildAccountCard(l10n),
              if (_account == _AccountState.active) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(l10n.paymentsW_transfers,
                      style: AppTheme.headlineSmall),
                ),
                _buildTransfers(l10n),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalance(AppLocalizations l10n) {
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
          Text(l10n.paymentsW_available,
              style: AppTheme.labelMedium
                  .copyWith(color: onPrimary.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Text(
            formatMoney(context, _available),
            style: TextStyle(
              color: onPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (_pendingBalance > 0) ...[
            const SizedBox(height: 4),
            Text(l10n.paymentsW_pending(formatMoney(context, _pendingBalance)),
                style: AppTheme.bodyMedium
                    .copyWith(color: onPrimary.withValues(alpha: 0.8))),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountCard(AppLocalizations l10n) {
    final (title, text) = switch (_account) {
      _AccountState.active => (
          l10n.paymentsW_activeTitle,
          l10n.paymentsW_activeText
        ),
      _AccountState.verifying => (
          l10n.paymentsW_pendingTitle,
          l10n.paymentsW_pendingText
        ),
      _ => (l10n.paymentsW_setupTitle, l10n.paymentsW_setupText),
    };

    final Widget action = switch (_account) {
      _AccountState.none => FilledButton(
          onPressed: _busy ? null : _setup,
          child: Text(l10n.paymentsW_setupButton),
        ),
      _AccountState.incomplete => FilledButton(
          onPressed: _busy ? null : _setup,
          child: Text(l10n.paymentsW_continueButton),
        ),
      _ => OutlinedButton.icon(
          onPressed: _busy ? null : _openStripe,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(l10n.paymentsW_openStripe),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(text, style: AppTheme.bodySmall),
          const SizedBox(height: 16),
          action,
        ],
      ),
    );
  }

  Widget _buildTransfers(AppLocalizations l10n) {
    if (_transfers.isEmpty) {
      return Text(l10n.paymentsW_noTransfers, style: AppTheme.bodySmall);
    }
    final locale = Localizations.localeOf(context).toString();
    final shown = _transfers.take(20).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      toBeginningOfSentenceCase(DateFormat.yMMMd(locale).format(
                          DateTime.tryParse('${shown[i]['createdAt']}')
                                  ?.toLocal() ??
                              DateTime.now()))!,
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                  if (shown[i]['status'] == 'reversed')
                    Text(l10n.paymentsW_reversed,
                        style: AppTheme.labelMedium
                            .copyWith(color: AppTheme.textTertiary))
                  else
                    Text(
                      formatMoney(context,
                          (shown[i]['amount'] as num?)?.toDouble() ?? 0),
                      style: AppTheme.labelLarge.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTheme.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
            child: Text(AppLocalizations.of(context)!.common_retry),
          ),
        ],
      ),
    );
  }
}
