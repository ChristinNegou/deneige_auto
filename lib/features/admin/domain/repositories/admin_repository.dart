import '../entities/admin_stats.dart';
import '../entities/admin_user.dart';
import '../entities/admin_reservation.dart';
import '../entities/admin_support_request.dart';
import '../entities/stripe_reconciliation.dart';

abstract class AdminRepository {
  Future<AdminStats> getDashboardStats();

  // Users
  Future<AdminUsersResponse> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? search,
  });
  Future<AdminUser> getUserDetails(String userId);
  Future<void> suspendUser(String userId, {String? reason, int days = 7});
  Future<void> unsuspendUser(String userId);

  // Reservations
  Future<AdminReservationsResponse> getReservations({
    int page = 1,
    int limit = 20,
    String? status,
  });
  Future<AdminReservation> getReservationDetails(String reservationId);
  Future<RefundResult> refundReservation(String reservationId,
      {double? amount, String? reason});

  // Notifications
  Future<void> broadcastNotification({
    required String title,
    required String message,
    String? targetRole,
  });

  // Support
  Future<AdminSupportResponse> getSupportRequests({
    int page = 1,
    int limit = 20,
    String? status,
  });
  Future<void> updateSupportRequest(String requestId,
      {String? status, String? adminNotes});
  Future<void> respondToSupportRequest(
    String requestId, {
    required String responseMessage,
    bool sendEmail = true,
    bool sendNotification = true,
  });
  Future<void> deleteSupportRequest(String requestId);

  // Finance
  Future<StripeReconciliation> getStripeReconciliation({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<StripeSyncResult> syncWithStripe({
    DateTime? startDate,
    DateTime? endDate,
  });
}

class AdminUsersResponse {
  final List<AdminUser> users;
  final int total;
  final int page;
  final int totalPages;

  AdminUsersResponse({
    required this.users,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory AdminUsersResponse.fromJson(Map<String, dynamic> json) {
    return AdminUsersResponse(
      users: (json['users'] as List<dynamic>?)
              ?.map((u) => AdminUser.fromJson(u))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class AdminReservationsResponse {
  final List<AdminReservation> reservations;
  final int total;
  final int page;
  final int totalPages;

  AdminReservationsResponse({
    required this.reservations,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory AdminReservationsResponse.fromJson(Map<String, dynamic> json) {
    return AdminReservationsResponse(
      reservations: (json['reservations'] as List<dynamic>?)
              ?.map((r) => AdminReservation.fromJson(r))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class RefundResult {
  final bool success;
  final double? refundAmount;
  final String? refundId;
  final String? message;

  RefundResult({
    required this.success,
    this.refundAmount,
    this.refundId,
    this.message,
  });

  factory RefundResult.fromJson(Map<String, dynamic> json) {
    return RefundResult(
      success: json['success'] ?? false,
      refundAmount: _toDouble(json['refundAmount']),
      refundId: json['refundId']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class AdminSupportResponse {
  final List<AdminSupportRequest> requests;
  final int total;
  final int page;
  final int totalPages;

  AdminSupportResponse({
    required this.requests,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory AdminSupportResponse.fromJson(Map<String, dynamic> json) {
    return AdminSupportResponse(
      requests: (json['requests'] as List<dynamic>?)
              ?.map((r) => AdminSupportRequest.fromJson(r))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
