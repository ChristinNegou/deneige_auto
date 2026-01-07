import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/services/worker_stripe_service.dart';

class WorkerPaymentsTab extends StatefulWidget {
  const WorkerPaymentsTab({super.key});

  @override
  State<WorkerPaymentsTab> createState() => _WorkerPaymentsTabState();
}

class _WorkerPaymentsTabState extends State<WorkerPaymentsTab>
    with AutomaticKeepAliveClientMixin {
  late WorkerStripeService _stripeService;
  bool _isLoading = true;
  bool _hasAccount = false;
  bool _isComplete = false;
  bool _chargesEnabled = false;
  bool _payoutsEnabled = false;
  Map<String, dynamic>? _balance;
  Map<String, dynamic>? _feeConfig;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stripeService = WorkerStripeService(dioClient: sl<DioClient>());
    _loadAccountStatus();
  }

  Future<void> _loadAccountStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await _stripeService.getAccountStatus();
      final feeConfig = await _stripeService.getFeeConfig();

      setState(() {
        _hasAccount = status['hasAccount'] ?? false;
        _isComplete = status['isComplete'] ?? false;
        _chargesEnabled = status['chargesEnabled'] ?? false;
        _payoutsEnabled = status['payoutsEnabled'] ?? false;
        _feeConfig = feeConfig;
      });

      if (_hasAccount && _isComplete) {
        final balance = await _stripeService.getBalance();
        setState(() => _balance = balance);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrContinueSetup() async {
    setState(() => _isLoading = true);

    try {
      final result = await _stripeService.createConnectAccount();

      if (result['onboardingUrl'] != null) {
        final url = Uri.parse(result['onboardingUrl']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }

      await Future.delayed(const Duration(seconds: 2));
      await _loadAccountStatus();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openDashboard() async {
    setState(() => _isLoading = true);

    try {
      final dashboardUrl = await _stripeService.getDashboardLink();
      final url = Uri.parse(dashboardUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadAccountStatus,
              color: AppTheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_errorMessage != null) _buildErrorBanner(),
                        _buildStatusCard(),
                        const SizedBox(height: 20),
                        if (_hasAccount && _isComplete) ...[
                          _buildBalanceCard(),
                          const SizedBox(height: 20),
                        ],
                        _buildPayoutSchedule(),
                        const SizedBox(height: 20),
                        _buildCommissionInfo(),
                        const SizedBox(height: 20),
                        _buildHowItWorks(),
                        const SizedBox(height: 20),
                        _buildSecurityInfo(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.success, AppTheme.success.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppTheme.background,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Paiements',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _loadAccountStatus();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppTheme.success,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool isConfigured = _hasAccount && _isComplete && _payoutsEnabled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConfigured
              ? [AppTheme.success, AppTheme.success.withValues(alpha: 0.7)]
              : [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: (isConfigured ? AppTheme.success : AppTheme.primary)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Icon(
                  isConfigured
                      ? Icons.account_balance
                      : Icons.account_balance_wallet,
                  color: AppTheme.background,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfigured
                          ? 'Compte configure'
                          : 'Configurez vos paiements',
                      style: const TextStyle(
                        color: AppTheme.background,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConfigured
                          ? 'Pret a recevoir des paiements'
                          : 'Recevez vos gains directement',
                      style: TextStyle(
                        color: AppTheme.background.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isConfigured) ...[
            _buildStatusRow('Compte verifie', _isComplete),
            const SizedBox(height: 8),
            _buildStatusRow('Paiements actifs', _chargesEnabled),
            const SizedBox(height: 8),
            _buildStatusRow('Virements actifs', _payoutsEnabled),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openDashboard,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Voir mon dashboard Stripe'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.background,
                  side: const BorderSide(color: AppTheme.background, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createOrContinueSetup,
                icon: const Icon(Icons.add_card_rounded, size: 20),
                label: Text(
                  _hasAccount
                      ? 'Continuer la configuration'
                      : 'Configurer maintenant',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.background,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color:
                isActive ? AppTheme.background : AppTheme.background.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? Icons.check : Icons.close,
            size: 14,
            color: isActive ? AppTheme.success : AppTheme.background,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.background.withValues(alpha: 0.95),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final available = (_balance?['available'] ?? 0.0) as num;
    final pending = (_balance?['pending'] ?? 0.0) as num;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(Icons.account_balance_wallet,
                    color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Solde', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponible',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppTheme.textTertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${available.toStringAsFixed(2)} \$',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: AppTheme.border,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'En attente',
                        style: AppTheme.labelSmall
                            .copyWith(color: AppTheme.textTertiary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pending.toStringAsFixed(2)} \$',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutSchedule() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child:
                Icon(Icons.schedule_rounded, color: AppTheme.info, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Virements automatiques',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vos gains sont deposes sur votre compte bancaire sous 2-3 jours ouvrables',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.info),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionInfo() {
    final platformPercent =
        ((_feeConfig?['platformFeePercent'] ?? 0.25) * 100).toInt();
    final workerPercent = 100 - platformPercent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.pie_chart_outline,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Repartition des paiements', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 20),
          _buildCommissionRow(
            'Vous recevez',
            '$workerPercent%',
            AppTheme.success,
            workerPercent / 100,
          ),
          const SizedBox(height: 12),
          _buildCommissionRow(
            'Commission plateforme',
            '$platformPercent%',
            AppTheme.textTertiary,
            platformPercent / 100,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.infoLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(color: AppTheme.info.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Exemple: Pour un job a 50\$, vous recevez ${(50 * workerPercent / 100).toStringAsFixed(2)}\$',
                    style: TextStyle(fontSize: 13, color: AppTheme.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionRow(
      String label, String percent, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.bodyMedium),
            Text(
              percent,
              style: AppTheme.labelLarge
                  .copyWith(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.background,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Comment ca fonctionne', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 20),
          _buildStep(1, 'Le client paie', 'Le paiement est traite par Stripe'),
          _buildStep(2, 'Repartition automatique',
              'Votre part est calculee instantanement'),
          _buildStep(3, 'Depot sur votre compte', 'Sous 2-3 jours ouvrables'),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.background,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(Icons.verified_user_outlined,
                color: AppTheme.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiements securises',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Propulse par Stripe, leader mondial des paiements',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
