import 'package:dio/dio.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/stripe_reconciliation.dart';

abstract class AdminRemoteDataSource {
  Future<AdminStats> getDashboardStats();
  Future<Map<String, dynamic>> getUsers(
      {int page, int limit, String? role, String? search});
  Future<Map<String, dynamic>> getUserDetails(String userId);
  Future<void> suspendUser(String userId, {String? reason, int days = 7});
  Future<void> unsuspendUser(String userId);
  Future<Map<String, dynamic>> getReservations(
      {int page, int limit, String? status});
  Future<Map<String, dynamic>> getReservationDetails(String reservationId);
  Future<Map<String, dynamic>> refundReservation(String reservationId,
      {double? amount, String? reason});
  Future<void> broadcastNotification(
      {required String title, required String message, String? targetRole});
  Future<Map<String, dynamic>> getSupportRequests(
      {int page, int limit, String? status});
  Future<void> updateSupportRequest(String requestId,
      {String? status, String? adminNotes});
  Future<void> respondToSupportRequest(
    String requestId, {
    required String responseMessage,
    bool sendEmail = true,
    bool sendNotification = true,
  });
  Future<void> deleteSupportRequest(String requestId);
  Future<StripeReconciliation> getStripeReconciliation({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<StripeSyncResult> syncWithStripe({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Identity Verification
  Future<Map<String, dynamic>> getVerifications(
      {int page, int limit, String? status, String? search});
  Future<Map<String, dynamic>> getVerificationStats();
  Future<Map<String, dynamic>> getVerificationDetails(String userId);
  Future<void> submitVerificationDecision(
    String userId, {
    required String decision,
    String? reason,
    String? notes,
  });
  Future<Map<String, dynamic>> reanalyzeVerification(String userId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSourceImpl({required this.dio});

  @override
  Future<AdminStats> getDashboardStats() async {
    final response = await dio.get('/admin/dashboard');
    return AdminStats.fromJson(response.data['stats']);
  }

  @override
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (role != null) queryParams['role'] = role;
    if (search != null) queryParams['search'] = search;

    final response =
        await dio.get('/admin/users', queryParameters: queryParams);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final response = await dio.get('/admin/users/$userId');
    return response.data;
  }

  @override
  Future<void> suspendUser(String userId,
      {String? reason, int days = 7}) async {
    await dio.post('/admin/users/$userId/suspend', data: {
      'reason': reason,
      'days': days,
    });
  }

  @override
  Future<void> unsuspendUser(String userId) async {
    await dio.post('/admin/users/$userId/unsuspend');
  }

  @override
  Future<Map<String, dynamic>> getReservations({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;

    final response =
        await dio.get('/admin/reservations', queryParameters: queryParams);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getReservationDetails(
      String reservationId) async {
    final response = await dio.get('/admin/reservations/$reservationId');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> refundReservation(String reservationId,
      {double? amount, String? reason}) async {
    final response =
        await dio.post('/admin/reservations/$reservationId/refund', data: {
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
    });
    return response.data;
  }

  @override
  Future<void> broadcastNotification({
    required String title,
    required String message,
    String? targetRole,
  }) async {
    await dio.post('/admin/notifications/broadcast', data: {
      'title': title,
      'message': message,
      if (targetRole != null) 'targetRole': targetRole,
    });
  }

  @override
  Future<Map<String, dynamic>> getSupportRequests({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;

    final response =
        await dio.get('/support/requests', queryParameters: queryParams);
    return response.data;
  }

  @override
  Future<void> updateSupportRequest(String requestId,
      {String? status, String? adminNotes}) async {
    await dio.put('/support/requests/$requestId', data: {
      if (status != null) 'status': status,
      if (adminNotes != null) 'adminNotes': adminNotes,
    });
  }

  @override
  Future<void> respondToSupportRequest(
    String requestId, {
    required String responseMessage,
    bool sendEmail = true,
    bool sendNotification = true,
  }) async {
    await dio.post('/support/requests/$requestId/respond', data: {
      'message': responseMessage,
      'sendEmail': sendEmail,
      'sendNotification': sendNotification,
    });
  }

  @override
  Future<void> deleteSupportRequest(String requestId) async {
    await dio.delete('/support/requests/$requestId');
  }

  @override
  Future<StripeReconciliation> getStripeReconciliation({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null)
      queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final response = await dio.get(
      '/admin/finance/reconciliation',
      queryParameters: queryParams,
    );
    return StripeReconciliation.fromJson(response.data);
  }

  @override
  Future<StripeSyncResult> syncWithStripe({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{};
    if (startDate != null) data['startDate'] = startDate.toIso8601String();
    if (endDate != null) data['endDate'] = endDate.toIso8601String();

    final response = await dio.post(
      '/admin/finance/sync-stripe',
      data: data,
    );
    return StripeSyncResult.fromJson(response.data);
  }

  // =============== IDENTITY VERIFICATION ===============

  @override
  Future<Map<String, dynamic>> getVerifications({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final response = await dio.get(
      '/admin/verifications',
      queryParameters: queryParams,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getVerificationStats() async {
    final response = await dio.get('/admin/verifications/stats');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getVerificationDetails(String userId) async {
    final response = await dio.get('/admin/verifications/$userId');
    return response.data;
  }

  @override
  Future<void> submitVerificationDecision(
    String userId, {
    required String decision,
    String? reason,
    String? notes,
  }) async {
    await dio.post('/admin/verifications/$userId/decision', data: {
      'decision': decision,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
    });
  }

  @override
  Future<Map<String, dynamic>> reanalyzeVerification(String userId) async {
    final response = await dio.post('/admin/verifications/$userId/reanalyze');
    return response.data;
  }
}
