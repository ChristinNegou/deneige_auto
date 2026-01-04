abstract class AdminEvent {}

// Dashboard Events
class LoadDashboardStats extends AdminEvent {}

// Users Events
class LoadUsers extends AdminEvent {
  final int page;
  final String? role;
  final String? search;

  LoadUsers({this.page = 1, this.role, this.search});
}

class LoadUserDetails extends AdminEvent {
  final String userId;

  LoadUserDetails(this.userId);
}

class SuspendUser extends AdminEvent {
  final String userId;
  final String? reason;
  final int days;

  SuspendUser({required this.userId, this.reason, this.days = 7});
}

class UnsuspendUser extends AdminEvent {
  final String userId;

  UnsuspendUser(this.userId);
}

// Reservations Events
class LoadReservations extends AdminEvent {
  final int page;
  final String? status;

  LoadReservations({this.page = 1, this.status});
}

class LoadReservationDetails extends AdminEvent {
  final String reservationId;

  LoadReservationDetails(this.reservationId);
}

class RefundReservation extends AdminEvent {
  final String reservationId;
  final double? amount;
  final String? reason;

  RefundReservation({required this.reservationId, this.amount, this.reason});
}

// Notification Events
class BroadcastNotification extends AdminEvent {
  final String title;
  final String message;
  final String? targetRole;

  BroadcastNotification({
    required this.title,
    required this.message,
    this.targetRole,
  });
}

// Clear Events
class ClearUserDetails extends AdminEvent {}

class ClearReservationDetails extends AdminEvent {}

class ClearError extends AdminEvent {}
