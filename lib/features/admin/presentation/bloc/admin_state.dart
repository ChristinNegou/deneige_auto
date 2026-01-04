import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/admin_reservation.dart';

enum AdminStatus { initial, loading, success, error }

class AdminState {
  // Dashboard
  final AdminStats? stats;
  final AdminStatus statsStatus;

  // Users
  final List<AdminUser> users;
  final int usersTotal;
  final int usersPage;
  final int usersTotalPages;
  final AdminStatus usersStatus;
  final AdminUser? selectedUser;
  final AdminStatus userDetailsStatus;

  // Reservations
  final List<AdminReservation> reservations;
  final int reservationsTotal;
  final int reservationsPage;
  final int reservationsTotalPages;
  final AdminStatus reservationsStatus;
  final AdminReservation? selectedReservation;
  final AdminStatus reservationDetailsStatus;

  // Filters
  final String? usersRoleFilter;
  final String? usersSearchQuery;
  final String? reservationsStatusFilter;

  // Actions
  final AdminStatus actionStatus;
  final String? successMessage;
  final String? errorMessage;

  const AdminState({
    // Dashboard
    this.stats,
    this.statsStatus = AdminStatus.initial,

    // Users
    this.users = const [],
    this.usersTotal = 0,
    this.usersPage = 1,
    this.usersTotalPages = 1,
    this.usersStatus = AdminStatus.initial,
    this.selectedUser,
    this.userDetailsStatus = AdminStatus.initial,

    // Reservations
    this.reservations = const [],
    this.reservationsTotal = 0,
    this.reservationsPage = 1,
    this.reservationsTotalPages = 1,
    this.reservationsStatus = AdminStatus.initial,
    this.selectedReservation,
    this.reservationDetailsStatus = AdminStatus.initial,

    // Filters
    this.usersRoleFilter,
    this.usersSearchQuery,
    this.reservationsStatusFilter,

    // Actions
    this.actionStatus = AdminStatus.initial,
    this.successMessage,
    this.errorMessage,
  });

  AdminState copyWith({
    // Dashboard
    AdminStats? stats,
    AdminStatus? statsStatus,

    // Users
    List<AdminUser>? users,
    int? usersTotal,
    int? usersPage,
    int? usersTotalPages,
    AdminStatus? usersStatus,
    AdminUser? selectedUser,
    bool clearSelectedUser = false,
    AdminStatus? userDetailsStatus,

    // Reservations
    List<AdminReservation>? reservations,
    int? reservationsTotal,
    int? reservationsPage,
    int? reservationsTotalPages,
    AdminStatus? reservationsStatus,
    AdminReservation? selectedReservation,
    bool clearSelectedReservation = false,
    AdminStatus? reservationDetailsStatus,

    // Filters
    String? usersRoleFilter,
    bool clearUsersRoleFilter = false,
    String? usersSearchQuery,
    bool clearUsersSearchQuery = false,
    String? reservationsStatusFilter,
    bool clearReservationsStatusFilter = false,

    // Actions
    AdminStatus? actionStatus,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AdminState(
      // Dashboard
      stats: stats ?? this.stats,
      statsStatus: statsStatus ?? this.statsStatus,

      // Users
      users: users ?? this.users,
      usersTotal: usersTotal ?? this.usersTotal,
      usersPage: usersPage ?? this.usersPage,
      usersTotalPages: usersTotalPages ?? this.usersTotalPages,
      usersStatus: usersStatus ?? this.usersStatus,
      selectedUser:
          clearSelectedUser ? null : (selectedUser ?? this.selectedUser),
      userDetailsStatus: userDetailsStatus ?? this.userDetailsStatus,

      // Reservations
      reservations: reservations ?? this.reservations,
      reservationsTotal: reservationsTotal ?? this.reservationsTotal,
      reservationsPage: reservationsPage ?? this.reservationsPage,
      reservationsTotalPages:
          reservationsTotalPages ?? this.reservationsTotalPages,
      reservationsStatus: reservationsStatus ?? this.reservationsStatus,
      selectedReservation: clearSelectedReservation
          ? null
          : (selectedReservation ?? this.selectedReservation),
      reservationDetailsStatus:
          reservationDetailsStatus ?? this.reservationDetailsStatus,

      // Filters
      usersRoleFilter: clearUsersRoleFilter
          ? null
          : (usersRoleFilter ?? this.usersRoleFilter),
      usersSearchQuery: clearUsersSearchQuery
          ? null
          : (usersSearchQuery ?? this.usersSearchQuery),
      reservationsStatusFilter: clearReservationsStatusFilter
          ? null
          : (reservationsStatusFilter ?? this.reservationsStatusFilter),

      // Actions
      actionStatus: actionStatus ?? this.actionStatus,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
