import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class WorkerStripeService {
  final Dio _dio;

  WorkerStripeService({required DioClient dioClient}) : _dio = dioClient.dio;

  /// Creer un compte Stripe Connect pour le deneigeur
  Future<Map<String, dynamic>> createConnectAccount() async {
    final response = await _dio.post('/stripe-connect/create-account');
    return response.data;
  }

  /// Verifier le statut du compte Connect
  Future<Map<String, dynamic>> getAccountStatus() async {
    final response = await _dio.get('/stripe-connect/account-status');
    return response.data;
  }

  /// Obtenir le lien vers le dashboard Stripe Express
  Future<String> getDashboardLink() async {
    final response = await _dio.get('/stripe-connect/dashboard-link');
    return response.data['dashboardUrl'];
  }

  /// Obtenir le solde disponible
  Future<Map<String, dynamic>> getBalance() async {
    final response = await _dio.get('/stripe-connect/balance');
    return response.data['balance'];
  }

  /// Obtenir l'historique des versements
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    final response = await _dio.get('/stripe-connect/payout-history');
    final List<dynamic> payouts = response.data['payouts'] ?? [];
    return payouts.cast<Map<String, dynamic>>();
  }

  /// Obtenir la configuration des commissions
  Future<Map<String, dynamic>> getFeeConfig() async {
    final response = await _dio.get('/stripe-connect/fee-config');
    return response.data;
  }

  /// Obtenir le resume des gains
  Future<Map<String, dynamic>> getEarningsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await _dio.get(
      '/payments/payouts/summary',
      queryParameters: queryParams,
    );
    return response.data['summary'];
  }

  // ============== GESTION DES COMPTES BANCAIRES ==============

  /// Obtenir la liste de tous les comptes bancaires
  Future<List<Map<String, dynamic>>> listBankAccounts() async {
    final response = await _dio.get('/stripe-connect/bank-accounts');
    final List<dynamic> accounts = response.data['bankAccounts'] ?? [];
    return accounts.cast<Map<String, dynamic>>();
  }

  /// Ajouter un nouveau compte bancaire
  Future<Map<String, dynamic>> addBankAccount({
    required String accountNumber,
    required String transitNumber,
    required String institutionNumber,
    required String accountHolderName,
    String accountHolderType = 'individual',
    bool setAsDefault = false,
  }) async {
    final response = await _dio.post('/stripe-connect/bank-accounts', data: {
      'accountNumber': accountNumber,
      'transitNumber': transitNumber,
      'institutionNumber': institutionNumber,
      'accountHolderName': accountHolderName,
      'accountHolderType': accountHolderType,
      'setAsDefault': setAsDefault,
    });
    return response.data;
  }

  /// Supprimer un compte bancaire
  Future<Map<String, dynamic>> deleteBankAccount(String bankAccountId) async {
    final response =
        await _dio.delete('/stripe-connect/bank-accounts/$bankAccountId');
    return response.data;
  }

  /// Definir un compte bancaire comme compte par defaut
  Future<Map<String, dynamic>> setDefaultBankAccount(
      String bankAccountId) async {
    final response = await _dio
        .put('/stripe-connect/bank-accounts/$bankAccountId/set-default');
    return response.data;
  }

  /// Obtenir la liste des banques canadiennes
  Future<List<Map<String, dynamic>>> getCanadianBanks() async {
    final response = await _dio.get('/stripe-connect/canadian-banks');
    final List<dynamic> banks = response.data['banks'] ?? [];
    return banks.cast<Map<String, dynamic>>();
  }
}
