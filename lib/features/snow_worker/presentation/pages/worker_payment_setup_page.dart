import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/services/worker_stripe_service.dart';

class WorkerPaymentSetupPage extends StatefulWidget {
  const WorkerPaymentSetupPage({super.key});

  @override
  State<WorkerPaymentSetupPage> createState() => _WorkerPaymentSetupPageState();
}

class _WorkerPaymentSetupPageState extends State<WorkerPaymentSetupPage> with WidgetsBindingObserver {
  late WorkerStripeService _stripeService;
  bool _isLoading = true;
  bool _hasAccount = false;
  bool _isComplete = false;
  bool _chargesEnabled = false;
  bool _payoutsEnabled = false;
  Map<String, dynamic>? _balance;
  Map<String, dynamic>? _feeConfig;
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
          // Marquer qu'on attend le retour de Stripe
          _waitingForStripeReturn = true;
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Paiements'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
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
                    if (_hasAccount && _isComplete) ...[
                      _buildBalanceCard(),
                      const SizedBox(height: 20),
                    ] else ...[
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
                          ? 'Compte configure'
                          : 'Configurez vos paiements',
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConfigured
                          ? 'Pret a recevoir des paiements'
                          : 'Recevez vos gains directement',
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
            _buildStatusRow('Compte verifie', _isComplete),
            const SizedBox(height: 8),
            _buildStatusRow('Paiements actifs', _chargesEnabled),
            const SizedBox(height: 8),
            _buildStatusRow('Virements actifs', _payoutsEnabled),
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
                child: const Text(
                  'Voir mon dashboard Stripe',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
                      ? 'Continuer la configuration'
                      : 'Configurer maintenant',
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
                'Solde',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
                      'Disponible',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                        'En attente',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
            'Les fonds sont deposes sur votre compte bancaire sous 2-3 jours ouvrables.',
            style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
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
                'Repartition des paiements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
            Text(label, style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
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
            'Comment ca fonctionne',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
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
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
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
          Icon(Icons.verified_user_outlined,
              color: AppTheme.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiements securises',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Propulse par Stripe, leader mondial des paiements',
                  style: TextStyle(fontSize: 11, color: AppTheme.success.withValues(alpha: 0.8)),
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
                child: Icon(Icons.badge_outlined, color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Documents requis',
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
            'Pour recevoir vos paiements, Stripe doit verifier votre identite. Preparez les documents suivants:',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildRequirementItem(
            Icons.credit_card,
            'Piece d\'identite avec photo',
            'Permis de conduire, passeport ou carte d\'identite',
          ),
          const SizedBox(height: 12),
          _buildRequirementItem(
            Icons.home_outlined,
            'Preuve d\'adresse',
            'Facture de services publics ou releve bancaire recent',
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
                      'Exigences pour les photos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRequirementBullet('Photo en couleur (format JPG ou PNG)'),
                _buildRequirementBullet('Document original, pas une photocopie'),
                _buildRequirementBullet('Nom et date de naissance lisibles'),
                _buildRequirementBullet('Document non expire'),
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
