import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/worker_stripe_service.dart';

class WorkerPaymentSetupPage extends StatefulWidget {
  const WorkerPaymentSetupPage({super.key});

  @override
  State<WorkerPaymentSetupPage> createState() => _WorkerPaymentSetupPageState();
}

class _WorkerPaymentSetupPageState extends State<WorkerPaymentSetupPage>
    with WidgetsBindingObserver {
  late WorkerStripeService _stripeService;
  bool _isLoading = true;
  bool _hasAccount = false;
  bool _isComplete = false;
  bool _chargesEnabled = false;
  bool _payoutsEnabled = false;
  Map<String, dynamic>? _balance;
  Map<String, dynamic>? _feeConfig;
  List<Map<String, dynamic>> _bankAccounts = [];
  String? _errorMessage;
  bool _waitingForStripeReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stripeService = WorkerStripeService(dioClient: sl<DioClient>());
    _loadAccountStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quand l'utilisateur revient dans l'app après Stripe, rafraîchir le statut
    if (state == AppLifecycleState.resumed && _waitingForStripeReturn) {
      _waitingForStripeReturn = false;
      _loadAccountStatus();
    }
  }

  Future<void> _loadAccountStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await _stripeService.getAccountStatus();
      debugPrint('=== PAYMENT PAGE: Account Status: $status ===');
      final feeConfig = await _stripeService.getFeeConfig();

      if (!mounted) return;
      setState(() {
        _hasAccount = status['hasAccount'] ?? false;
        _isComplete = status['isComplete'] ?? false;
        _chargesEnabled = status['chargesEnabled'] ?? false;
        _payoutsEnabled = status['payoutsEnabled'] ?? false;
        _feeConfig = feeConfig;
      });

      debugPrint(
          '=== PAYMENT PAGE: hasAccount: $_hasAccount, isComplete: $_isComplete, chargesEnabled: $_chargesEnabled, payoutsEnabled: $_payoutsEnabled ===');

      if (_hasAccount && _isComplete) {
        final balance = await _stripeService.getBalance();
        final bankAccounts = await _stripeService.listBankAccounts();
        if (!mounted) return;
        setState(() {
          _balance = balance;
          _bankAccounts = bankAccounts;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createOrContinueSetup() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('=== Calling createConnectAccount ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.worker_connectingToStripe),
            backgroundColor: AppTheme.info,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      final result = await _stripeService.createConnectAccount();
      debugPrint('=== Result: $result ===');

      if (result['onboardingUrl'] != null) {
        final url = Uri.parse(result['onboardingUrl']);
        debugPrint('=== Opening URL: $url ===');
        if (await canLaunchUrl(url)) {
          // Marquer qu'on attend le retour de Stripe
          _waitingForStripeReturn = true;
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.worker_cannotOpenStripeLink),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      } else if (result['isComplete'] == true) {
        // Le compte est deja configure, rafraichir le statut
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .worker_accountAlreadyConfigured),
              backgroundColor: AppTheme.success,
            ),
          );
        }
        await _loadAccountStatus();
      } else {
        // Pas d'URL mais pas complet non plus - afficher le resultat
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.worker_stripeResponse(
                  result
                      .toString()
                      .substring(0, result.toString().length.clamp(0, 100)))),
              backgroundColor: AppTheme.warning,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('=== Error: $e ===');
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .clientHome_errorPrefix(e.toString())),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final dashboardUrl = await _stripeService.getDashboardLink();
      final url = Uri.parse(dashboardUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .clientHome_errorPrefix(e.toString())),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.worker_payments),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          // Debug: afficher le statut actuel
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'v4 | C:${_chargesEnabled ? "1" : "0"} P:${_payoutsEnabled ? "1" : "0"}',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAccountStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) _buildErrorBanner(),
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    if (_hasAccount && _chargesEnabled && _payoutsEnabled) ...[
                      _buildBalanceCard(),
                      const SizedBox(height: 20),
                      _buildBankAccountsCard(),
                      const SizedBox(height: 20),
                    ],
                    // Montrer les exigences si les virements ne sont pas encore activés
                    if (!_payoutsEnabled && !_chargesEnabled) ...[
                      _buildIdentityRequirements(),
                      const SizedBox(height: 20),
                    ],
                    _buildCommissionInfo(),
                    const SizedBox(height: 20),
                    _buildHowItWorks(),
                    const SizedBox(height: 20),
                    _buildSecurityInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(fontSize: 13, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    // Compte entièrement configuré: paiements et virements actifs
    final bool isConfigured = _hasAccount && _payoutsEnabled && _chargesEnabled;
    // En attente de vérification: compte créé avec charges OU details soumis, mais virements pas encore actifs
    final bool isPendingVerification =
        _hasAccount && (_isComplete || _chargesEnabled) && !_payoutsEnabled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConfigured
              ? [AppTheme.success, AppTheme.success.withValues(alpha: 0.7)]
              : isPendingVerification
                  ? [AppTheme.warning, AppTheme.warning.withValues(alpha: 0.7)]
                  : [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConfigured
                      ? Icons.account_balance
                      : isPendingVerification
                          ? Icons.hourglass_top
                          : Icons.account_balance_wallet,
                  color: AppTheme.background,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfigured
                          ? AppLocalizations.of(context)!
                              .worker_accountConfigured
                          : isPendingVerification
                              ? AppLocalizations.of(context)!
                                  .worker_verificationInProgress
                              : AppLocalizations.of(context)!
                                  .worker_configurePayments,
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConfigured
                          ? AppLocalizations.of(context)!.worker_readyToReceive
                          : isPendingVerification
                              ? AppLocalizations.of(context)!
                                  .worker_stripeVerifying
                              : AppLocalizations.of(context)!
                                  .worker_receiveEarningsDirectly,
                      style: TextStyle(
                        color: AppTheme.background.withValues(alpha: 0.8),
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
            _buildStatusRow(
                AppLocalizations.of(context)!.worker_accountVerified,
                _isComplete),
            const SizedBox(height: 8),
            _buildStatusRow(AppLocalizations.of(context)!.worker_paymentsActive,
                _chargesEnabled),
            const SizedBox(height: 8),
            _buildStatusRow(AppLocalizations.of(context)!.worker_payoutsActive,
                _payoutsEnabled),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openDashboard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.background,
                  side: BorderSide(color: AppTheme.background),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.worker_viewStripeDashboard,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else if (isPendingVerification) ...[
            _buildStatusRow(
                AppLocalizations.of(context)!.worker_documentsSubmitted,
                _isComplete),
            const SizedBox(height: 8),
            _buildStatusRow(AppLocalizations.of(context)!.worker_paymentsActive,
                _chargesEnabled),
            const SizedBox(height: 8),
            _buildStatusRow(AppLocalizations.of(context)!.worker_payoutsActive,
                _payoutsEnabled),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.background, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.worker_verificationTimeInfo,
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openDashboard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.background,
                  side: BorderSide(color: AppTheme.background),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.worker_viewStatusOnStripe,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createOrContinueSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.background,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _hasAccount
                      ? AppLocalizations.of(context)!.worker_continueSetup
                      : AppLocalizations.of(context)!.worker_configureNow,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
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
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.background
                : AppTheme.background.withValues(alpha: 0.3),
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
            color: AppTheme.background.withValues(alpha: 0.9),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.worker_balance,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.worker_available,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${available.toStringAsFixed(2)} \$',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: AppTheme.border,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.reservation_shortPending,
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pending.toStringAsFixed(2)} \$',
                        style: TextStyle(
                          fontSize: 24,
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
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.worker_fundsDepositedInfo,
            style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  void _navigateToBankAccounts() {
    Navigator.pushNamed(context, '/snow-worker/bank-accounts').then((_) {
      _loadAccountStatus();
    });
  }

  Widget _buildBankAccountsCard() {
    // Trouver le compte par défaut
    final defaultAccount = _bankAccounts.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => _bankAccounts.isNotEmpty ? _bankAccounts.first : {},
    );

    final hasAccounts = _bankAccounts.isNotEmpty;
    final bankName = defaultAccount['bankName'] ?? 'Banque';
    final last4 = defaultAccount['last4'] ?? '****';
    final status = defaultAccount['status'] ?? 'new';
    final currency =
        (defaultAccount['currency'] ?? 'cad').toString().toUpperCase();
    final bool isVerified = status == 'verified' || status == 'new';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.worker_bankAccounts,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!
                          .worker_accountsConfiguredCount(_bankAccounts.length),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _navigateToBankAccounts,
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (hasAccounts) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _navigateToBankAccounts,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                bankName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.worker_primary,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '•••• $last4',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Text(
                                  currency,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isVerified ? Icons.verified : Icons.pending,
                                size: 14,
                                color: isVerified
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _navigateToBankAccounts,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppTheme.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!
                            .worker_noBankAccountWarning,
                        style: TextStyle(fontSize: 13, color: AppTheme.warning),
                      ),
                    ),
                    Icon(Icons.add_circle_outline, color: AppTheme.warning),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _navigateToBankAccounts,
              icon: Icon(Icons.settings, size: 18, color: AppTheme.primary),
              label: Text(
                AppLocalizations.of(context)!.worker_manageBankAccounts,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.worker_paymentDistribution,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCommissionRow(
            AppLocalizations.of(context)!.worker_youReceive,
            '$workerPercent%',
            AppTheme.success,
            workerPercent / 100,
          ),
          const SizedBox(height: 12),
          _buildCommissionRow(
            AppLocalizations.of(context)!.worker_platformCommission,
            '$platformPercent%',
            AppTheme.textTertiary,
            platformPercent / 100,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.worker_paymentExample(
                        (50 * workerPercent / 100).toStringAsFixed(2)),
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
            Text(label,
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            Text(
              percent,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.worker_howItWorks,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildStep(1, AppLocalizations.of(context)!.worker_step1ClientPays,
              AppLocalizations.of(context)!.worker_step1Subtitle),
          _buildStep(
              2,
              AppLocalizations.of(context)!.worker_step2AutoDistribution,
              AppLocalizations.of(context)!.worker_step2Subtitle),
          _buildStep(
              3,
              AppLocalizations.of(context)!.worker_step3DepositToAccount,
              AppLocalizations.of(context)!.worker_step3Subtitle),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: AppTheme.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.worker_securePayments,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.worker_poweredByStripeLeader,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.success.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.badge_outlined,
                    color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.worker_documentsRequired,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.worker_identityVerificationInfo,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildRequirementItem(
            Icons.credit_card,
            AppLocalizations.of(context)!.worker_photoId,
            AppLocalizations.of(context)!.worker_photoIdDesc,
          ),
          const SizedBox(height: 12),
          _buildRequirementItem(
            Icons.home_outlined,
            AppLocalizations.of(context)!.worker_proofOfAddress,
            AppLocalizations.of(context)!.worker_proofOfAddressDesc,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.info, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.worker_photoRequirements,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRequirementBullet(
                    AppLocalizations.of(context)!.worker_reqColorPhoto),
                _buildRequirementBullet(
                    AppLocalizations.of(context)!.worker_reqOriginalDoc),
                _buildRequirementBullet(
                    AppLocalizations.of(context)!.worker_reqNameDobVisible),
                _buildRequirementBullet(
                    AppLocalizations.of(context)!.worker_reqNotExpired),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.info,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.info.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
