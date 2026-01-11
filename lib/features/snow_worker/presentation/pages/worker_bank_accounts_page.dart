import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/services/worker_stripe_service.dart';

class WorkerBankAccountsPage extends StatefulWidget {
  const WorkerBankAccountsPage({super.key});

  @override
  State<WorkerBankAccountsPage> createState() => _WorkerBankAccountsPageState();
}

class _WorkerBankAccountsPageState extends State<WorkerBankAccountsPage> {
  late WorkerStripeService _stripeService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _canadianBanks = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _stripeService = WorkerStripeService(dioClient: sl<DioClient>());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accounts = await _stripeService.listBankAccounts();
      final banks = await _stripeService.getCanadianBanks();
      setState(() {
        _bankAccounts = accounts;
        _canadianBanks = banks;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setAsDefault(String bankAccountId) async {
    setState(() => _isLoading = true);

    try {
      await _stripeService.setDefaultBankAccount(bankAccountId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Compte defini comme principal'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
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

  Future<void> _deleteAccount(String bankAccountId, String last4) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer ce compte?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer le compte se terminant par $last4?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _stripeService.deleteBankAccount(bankAccountId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Compte supprime'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
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

  void _showAddAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddBankAccountModal(
        stripeService: _stripeService,
        canadianBanks: _canadianBanks,
        onSuccess: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Comptes bancaires'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountModal,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) _buildErrorBanner(),
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    if (_bankAccounts.isEmpty)
                      _buildEmptyState()
                    else
                      ..._bankAccounts.map((account) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildBankAccountCard(account),
                          )),
                    const SizedBox(height: 80),
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
                  'Compte principal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vos gains seront deposes sur le compte marque comme principal. Vous pouvez changer de compte a tout moment.',
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
              Icons.account_balance_outlined,
              size: 40,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun compte bancaire',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un compte bancaire pour recevoir vos gains',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddAccountModal,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un compte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(Map<String, dynamic> account) {
    final bankName = account['bankName'] ?? 'Banque';
    final last4 = account['last4'] ?? '****';
    final status = account['status'] ?? 'new';
    final currency = (account['currency'] ?? 'cad').toString().toUpperCase();
    final accountHolderName = account['accountHolderName'];
    final isDefault = account['isDefault'] == true;
    final accountId = account['id'] as String;

    final bool isVerified = status == 'verified' || status == 'new';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault
              ? AppTheme.primary.withValues(alpha: 0.5)
              : AppTheme.border,
          width: isDefault ? 2 : 1,
        ),
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
                  color: isDefault
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: isDefault ? AppTheme.primary : AppTheme.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bankName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Principal',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
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
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currency,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isVerified ? Icons.verified : Icons.pending,
                          size: 14,
                          color:
                              isVerified ? AppTheme.success : AppTheme.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (accountHolderName != null) ...[
            const SizedBox(height: 8),
            Text(
              accountHolderName,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isDefault) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setAsDefault(accountId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Definir comme principal',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!isDefault || _bankAccounts.length > 1)
                Expanded(
                  child: OutlinedButton(
                    onPressed: isDefault && _bankAccounts.length > 1
                        ? null
                        : () => _deleteAccount(accountId, last4),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                        color: isDefault && _bankAccounts.length > 1
                            ? AppTheme.border
                            : AppTheme.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Supprimer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDefault && _bankAccounts.length > 1
                            ? AppTheme.textTertiary
                            : AppTheme.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (isDefault && _bankAccounts.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Definissez un autre compte comme principal avant de supprimer celui-ci',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============== MODAL AJOUT COMPTE BANCAIRE ==============

class _AddBankAccountModal extends StatefulWidget {
  final WorkerStripeService stripeService;
  final List<Map<String, dynamic>> canadianBanks;
  final VoidCallback onSuccess;

  const _AddBankAccountModal({
    required this.stripeService,
    required this.canadianBanks,
    required this.onSuccess,
  });

  @override
  State<_AddBankAccountModal> createState() => _AddBankAccountModalState();
}

class _AddBankAccountModalState extends State<_AddBankAccountModal> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _transitNumberController = TextEditingController();
  final _institutionNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  bool _isLoading = false;
  bool _setAsDefault = true;
  String? _selectedBankCode;
  String? _errorMessage;

  @override
  void dispose() {
    _accountNumberController.dispose();
    _transitNumberController.dispose();
    _institutionNumberController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  void _selectBank(String code) {
    setState(() {
      _selectedBankCode = code;
      _institutionNumberController.text = code;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.stripeService.addBankAccount(
        accountNumber: _accountNumberController.text.trim(),
        transitNumber: _transitNumberController.text.trim(),
        institutionNumber: _institutionNumberController.text.trim(),
        accountHolderName: _accountHolderNameController.text.trim(),
        setAsDefault: _setAsDefault,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Compte bancaire ajoute avec succes'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ajouter un compte bancaire',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: AppTheme.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                    fontSize: 13, color: AppTheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Institution bancaire
                    Text(
                      'Institution bancaire',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.canadianBanks.length,
                        itemBuilder: (context, index) {
                          final bank = widget.canadianBanks[index];
                          final isSelected = _selectedBankCode == bank['code'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () => _selectBank(bank['code']),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 110,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.1)
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.account_balance,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      bank['name'].toString().split(' ').first,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.textPrimary,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      bank['code'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nom du titulaire
                    TextFormField(
                      controller: _accountHolderNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du titulaire',
                        hintText:
                            'Nom complet tel qu\'il apparait sur le compte',
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppTheme.primary, width: 2),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom du titulaire est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Numéro d'institution
                    TextFormField(
                      controller: _institutionNumberController,
                      decoration: InputDecoration(
                        labelText: 'Numero d\'institution (3 chiffres)',
                        hintText: 'Ex: 001',
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppTheme.primary, width: 2),
                        ),
                        prefixIcon:
                            Icon(Icons.business, color: AppTheme.textSecondary),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) {
                        if (value == null || value.length != 3) {
                          return 'Le numero d\'institution doit contenir 3 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Numéro de transit
                    TextFormField(
                      controller: _transitNumberController,
                      decoration: InputDecoration(
                        labelText: 'Numero de transit (5 chiffres)',
                        hintText: 'Ex: 12345',
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppTheme.primary, width: 2),
                        ),
                        prefixIcon:
                            Icon(Icons.pin, color: AppTheme.textSecondary),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (value) {
                        if (value == null || value.length != 5) {
                          return 'Le numero de transit doit contenir 5 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Numéro de compte
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: InputDecoration(
                        labelText: 'Numero de compte',
                        hintText: 'Ex: 1234567',
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: AppTheme.primary, width: 2),
                        ),
                        prefixIcon: Icon(Icons.credit_card,
                            color: AppTheme.textSecondary),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      validator: (value) {
                        if (value == null || value.length < 7) {
                          return 'Le numero de compte doit contenir au moins 7 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Checkbox définir par défaut
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _setAsDefault,
                            onChanged: (value) {
                              setState(() => _setAsDefault = value ?? true);
                            },
                            activeColor: AppTheme.primary,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _setAsDefault = !_setAsDefault);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Definir comme compte principal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Les gains seront deposes sur ce compte',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Info sécurité
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline,
                              color: AppTheme.success, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vos informations bancaires sont securisees et encryptees par Stripe',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // Submit button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        AppTheme.primary.withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Ajouter le compte',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
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
