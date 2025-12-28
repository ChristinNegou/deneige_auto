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
}
