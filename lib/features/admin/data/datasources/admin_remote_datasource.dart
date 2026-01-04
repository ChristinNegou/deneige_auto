import 'package:dio/dio.dart';
import '../../domain/entities/admin_stats.dart';

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
}
