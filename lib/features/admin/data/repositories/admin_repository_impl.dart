import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/admin_reservation.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AdminStats> getDashboardStats() async {
    return await remoteDataSource.getDashboardStats();
  }

  @override
  Future<AdminUsersResponse> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? search,
  }) async {
    final response = await remoteDataSource.getUsers(
      page: page,
      limit: limit,
      role: role,
      search: search,
    );
    return AdminUsersResponse.fromJson(response);
  }

  @override
  Future<AdminUser> getUserDetails(String userId) async {
    final response = await remoteDataSource.getUserDetails(userId);
    return AdminUser.fromJson(response['user']);
  }

  @override
  Future<void> suspendUser(String userId,
      {String? reason, int days = 7}) async {
    await remoteDataSource.suspendUser(userId, reason: reason, days: days);
  }

  @override
  Future<void> unsuspendUser(String userId) async {
    await remoteDataSource.unsuspendUser(userId);
  }

  @override
  Future<AdminReservationsResponse> getReservations({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await remoteDataSource.getReservations(
      page: page,
      limit: limit,
      status: status,
    );
    return AdminReservationsResponse.fromJson(response);
  }

  @override
  Future<AdminReservation> getReservationDetails(String reservationId) async {
    final response =
        await remoteDataSource.getReservationDetails(reservationId);
    return AdminReservation.fromJson(response['reservation']);
  }

  @override
  Future<RefundResult> refundReservation(String reservationId,
      {double? amount, String? reason}) async {
    final response = await remoteDataSource.refundReservation(
      reservationId,
      amount: amount,
      reason: reason,
    );
    return RefundResult.fromJson(response);
  }

  @override
  Future<void> broadcastNotification({
    required String title,
    required String message,
    String? targetRole,
  }) async {
    await remoteDataSource.broadcastNotification(
      title: title,
      message: message,
      targetRole: targetRole,
    );
  }
}
