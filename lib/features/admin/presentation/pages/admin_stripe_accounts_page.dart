import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class AdminStripeAccountsPage extends StatefulWidget {
  const AdminStripeAccountsPage({super.key});

  @override
  State<AdminStripeAccountsPage> createState() => _AdminStripeAccountsPageState();
}

class _AdminStripeAccountsPageState extends State<AdminStripeAccountsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = sl<DioClient>().dio;
      final response = await dio.get('/stripe-connect/admin/accounts');

      setState(() {
        _accounts = List<Map<String, dynamic>>.from(response.data['accounts'] ?? []);
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount(Map<String, dynamic> account) async {
    final workerId = account['workerId'];
    final stripeAccountId = account['stripeAccountId'];
    final workerName = account['workerName'] ?? 'Compte orphelin';
    final email = account['workerEmail'] ?? account['email'] ?? '';
    final isOrphan = account['isOrphan'] == true;
    final isInvalidOnStripe = account['isInvalidOnStripe'] == true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Supprimer ce compte?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOrphan
                  ? 'Vous etes sur le point de supprimer un compte Stripe Connect orphelin:'
                  : isInvalidOnStripe
                      ? 'Vous etes sur le point de nettoyer la reference invalide pour:'
                      : 'Vous etes sur le point de supprimer le compte Stripe Connect de:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isOrphan
                        ? AppTheme.warning.withValues(alpha: 0.1)
                        : AppTheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      isOrphan ? Icons.link_off : Icons.person,
                      color: isOrphan ? AppTheme.warning : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOrphan ? 'Compte orphelin' : workerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          email.isNotEmpty ? email : stripeAccountId,
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isInvalidOnStripe ? AppTheme.infoLight : AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isInvalidOnStripe
                      ? AppTheme.info.withValues(alpha: 0.3)
                      : AppTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isInvalidOnStripe ? AppTheme.info : AppTheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isInvalidOnStripe
                          ? 'Cette action nettoiera la reference dans la base de donnees. Le compte n\'existe deja plus sur Stripe.'
                          : 'Cette action est irreversible. Le deneigeur devra recreer un compte pour recevoir des paiements.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isInvalidOnStripe ? AppTheme.info : AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isInvalidOnStripe ? 'Nettoyer' : 'Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final dio = sl<DioClient>().dio;

      if (isOrphan) {
        // Supprimer un compte orphelin par son ID Stripe
        await dio.delete('/stripe-connect/admin/orphan-accounts/$stripeAccountId');
      } else {
        // Supprimer un compte lie a un worker
        await dio.delete('/stripe-connect/admin/accounts/$workerId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOrphan
                  ? 'Compte orphelin supprime'
                  : isInvalidOnStripe
                      ? 'Reference nettoyee pour $workerName'
                      : 'Compte de $workerName supprime',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
      await _loadAccounts();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Comptes Stripe Connect'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAccounts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAccounts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) _buildErrorBanner(),
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    Text(
                      'Comptes des deneigeurs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_accounts.isEmpty)
                      _buildEmptyState()
                    else
                      ..._accounts.map((account) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildAccountCard(account),
                          )),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.info, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion Stripe Connect',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gerez les comptes de paiement des deneigeurs. La suppression d\'un compte est irreversible.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.info.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalAccounts = _accounts.length;
    final activeAccounts = _accounts.where((a) =>
        a['chargesEnabled'] == true &&
        a['payoutsEnabled'] == true &&
        a['isOrphan'] != true &&
        a['isInvalidOnStripe'] != true).length;
    final orphanAccounts = _accounts.where((a) => a['isOrphan'] == true).length;
    final invalidInDb = _accounts.where((a) => a['isInvalidOnStripe'] == true).length;
    final pendingAccounts = _accounts.where((a) =>
        (a['chargesEnabled'] != true || a['payoutsEnabled'] != true) &&
        a['isOrphan'] != true &&
        a['isInvalidOnStripe'] != true).length;

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
              Icon(Icons.analytics_outlined, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Resume',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Total', totalAccounts, AppTheme.primary)),
              Expanded(child: _buildSummaryItem('Actifs', activeAccounts, AppTheme.success)),
              Expanded(child: _buildSummaryItem('En attente', pendingAccounts, AppTheme.warning)),
            ],
          ),
          if (orphanAccounts > 0 || invalidInDb > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (orphanAccounts > 0)
                  Expanded(child: _buildSummaryItem('Orphelins', orphanAccounts, Colors.orange)),
                if (invalidInDb > 0)
                  Expanded(child: _buildSummaryItem('Invalides', invalidInDb, AppTheme.error)),
                if (orphanAccounts == 0 || invalidInDb == 0)
                  const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 40,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun compte Stripe Connect',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun deneigeur n\'a configure son compte de paiement',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final workerName = account['workerName'] ?? 'Compte orphelin';
    final workerEmail = account['workerEmail'] ?? '';
    final stripeEmail = account['email'] ?? '';
    final stripeAccountId = account['stripeAccountId'] ?? '';
    final chargesEnabled = account['chargesEnabled'] == true;
    final payoutsEnabled = account['payoutsEnabled'] == true;
    final detailsSubmitted = account['detailsSubmitted'] == true;
    final hasError = account['error'] != null;
    final created = account['created'];
    final isOrphan = account['isOrphan'] == true;
    final isInvalidOnStripe = account['isInvalidOnStripe'] == true;

    final isActive = chargesEnabled && payoutsEnabled;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isInvalidOnStripe) {
      statusColor = AppTheme.error;
      statusText = 'Invalide';
      statusIcon = Icons.link_off;
    } else if (isOrphan) {
      statusColor = Colors.orange;
      statusText = 'Orphelin';
      statusIcon = Icons.warning_amber;
    } else if (hasError) {
      statusColor = AppTheme.error;
      statusText = 'Erreur';
      statusIcon = Icons.error_outline;
    } else if (isActive) {
      statusColor = AppTheme.success;
      statusText = 'Actif';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = AppTheme.warning;
      statusText = 'En attente';
      statusIcon = Icons.pending;
    }

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
              CircleAvatar(
                radius: 24,
                backgroundColor: isOrphan
                    ? Colors.orange.withValues(alpha: 0.1)
                    : isInvalidOnStripe
                        ? AppTheme.error.withValues(alpha: 0.1)
                        : AppTheme.primary.withValues(alpha: 0.1),
                child: isOrphan || isInvalidOnStripe
                    ? Icon(
                        isOrphan ? Icons.link_off : Icons.error_outline,
                        color: isOrphan ? Colors.orange : AppTheme.error,
                        size: 24,
                      )
                    : Text(
                        workerName.toString().substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOrphan ? 'Compte orphelin' : workerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isOrphan ? Colors.orange : null,
                      ),
                    ),
                    Text(
                      isOrphan
                          ? (stripeEmail.isNotEmpty ? stripeEmail : 'Email non disponible')
                          : workerEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.fingerprint, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stripeAccountId,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (created != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Cree le ${_formatDate(created)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!hasError) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip('Paiements', chargesEnabled),
                const SizedBox(width: 8),
                _buildStatusChip('Virements', payoutsEnabled),
                const SizedBox(width: 8),
                _buildStatusChip('Verifie', detailsSubmitted),
              ],
            ),
          ],
          if (isOrphan) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce compte existe sur Stripe mais n\'est lie a aucun deneigeur dans l\'application.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isInvalidOnStripe) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_off, size: 16, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce compte n\'existe plus sur Stripe. Nettoyez la reference pour permettre au deneigeur de recreer un compte.',
                      style: TextStyle(fontSize: 12, color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasError && !isInvalidOnStripe) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      account['error'] ?? 'Erreur inconnue',
                      style: TextStyle(fontSize: 12, color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _deleteAccount(account),
              icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
              label: Text(
                'Supprimer le compte',
                style: TextStyle(color: AppTheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.textTertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check : Icons.close,
            size: 12,
            color: isActive ? AppTheme.success : AppTheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppTheme.success : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      final DateTime dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}
