import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository repository;

  AdminBloc({required this.repository}) : super(const AdminState()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<LoadUsers>(_onLoadUsers);
    on<LoadUserDetails>(_onLoadUserDetails);
    on<SuspendUser>(_onSuspendUser);
    on<UnsuspendUser>(_onUnsuspendUser);
    on<LoadReservations>(_onLoadReservations);
    on<LoadReservationDetails>(_onLoadReservationDetails);
    on<RefundReservation>(_onRefundReservation);
    on<BroadcastNotification>(_onBroadcastNotification);
    on<LoadSupportRequests>(_onLoadSupportRequests);
    on<UpdateSupportRequest>(_onUpdateSupportRequest);
    on<RespondToSupportRequest>(_onRespondToSupportRequest);
    on<DeleteSupportRequest>(_onDeleteSupportRequest);
    on<ClearUserDetails>(_onClearUserDetails);
    on<ClearReservationDetails>(_onClearReservationDetails);
    on<ClearError>(_onClearError);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(statsStatus: AdminStatus.loading));
    try {
      final stats = await repository.getDashboardStats();
      emit(state.copyWith(
        stats: stats,
        statsStatus: AdminStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        statsStatus: AdminStatus.error,
        errorMessage: 'Erreur de chargement des statistiques: $e',
      ));
    }
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(
      usersStatus: AdminStatus.loading,
      usersRoleFilter: event.role,
      usersSearchQuery: event.search,
      clearUsersRoleFilter: event.role == null,
      clearUsersSearchQuery: event.search == null,
    ));
    try {
      final response = await repository.getUsers(
        page: event.page,
        role: event.role,
        search: event.search,
      );
      emit(state.copyWith(
        users: response.users,
        usersTotal: response.total,
        usersPage: response.page,
        usersTotalPages: response.totalPages,
        usersStatus: AdminStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        usersStatus: AdminStatus.error,
        errorMessage: 'Erreur de chargement des utilisateurs: $e',
      ));
    }
  }

  Future<void> _onLoadUserDetails(
    LoadUserDetails event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(userDetailsStatus: AdminStatus.loading));
    try {
      final user = await repository.getUserDetails(event.userId);
      emit(state.copyWith(
        selectedUser: user,
        userDetailsStatus: AdminStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        userDetailsStatus: AdminStatus.error,
        errorMessage: 'Erreur de chargement des détails: $e',
      ));
    }
  }

  Future<void> _onSuspendUser(
    SuspendUser event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(actionStatus: AdminStatus.loading));
    try {
      await repository.suspendUser(
        event.userId,
        reason: event.reason,
        days: event.days,
      );
      emit(state.copyWith(
        actionStatus: AdminStatus.success,
        successMessage: 'Utilisateur suspendu avec succès',
      ));
      // Reload users list
      add(LoadUsers(
        page: state.usersPage,
        role: state.usersRoleFilter,
        search: state.usersSearchQuery,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminStatus.error,
        errorMessage: 'Erreur lors de la suspension: $e',
      ));
    }
  }

  Future<void> _onUnsuspendUser(
    UnsuspendUser event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(actionStatus: AdminStatus.loading));
    try {
      await repository.unsuspendUser(event.userId);
      emit(state.copyWith(
        actionStatus: AdminStatus.success,
        successMessage: 'Suspension levée avec succès',
      ));
      // Reload users list
      add(LoadUsers(
        page: state.usersPage,
        role: state.usersRoleFilter,
        search: state.usersSearchQuery,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminStatus.error,
        errorMessage: 'Erreur lors de la levée de suspension: $e',
      ));
    }
  }

  Future<void> _onLoadReservations(
    LoadReservations event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(
      reservationsStatus: AdminStatus.loading,
      reservationsStatusFilter: event.status,
      clearReservationsStatusFilter: event.status == null,
    ));
    try {
      final response = await repository.getReservations(
        page: event.page,
        status: event.status,
      );
      emit(state.copyWith(
        reservations: response.reservations,
        reservationsTotal: response.total,
        reservationsPage: response.page,
        reservationsTotalPages: response.totalPages,
        reservationsStatus: AdminStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        reservationsStatus: AdminStatus.error,
        errorMessage: 'Erreur de chargement des réservations: $e',
      ));
    }
  }

  Future<void> _onLoadReservationDetails(
    LoadReservationDetails event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(reservationDetailsStatus: AdminStatus.loading));
    try {
      final reservation =
          await repository.getReservationDetails(event.reservationId);
      emit(state.copyWith(
        selectedReservation: reservation,
        reservationDetailsStatus: AdminStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        reservationDetailsStatus: AdminStatus.error,
        errorMessage: 'Erreur de chargement des détails: $e',
      ));
    }
  }

  Future<void> _onRefundReservation(
    RefundReservation event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(actionStatus: AdminStatus.loading));
    try {
      final result = await repository.refundReservation(
        event.reservationId,
        amount: event.amount,
        reason: event.reason,
      );
      if (result.success) {
        emit(state.copyWith(
          actionStatus: AdminStatus.success,
          successMessage:
              'Remboursement effectué: ${result.refundAmount?.toStringAsFixed(2)} \$',
        ));
        // Reload reservations list
        add(LoadReservations(
          page: state.reservationsPage,
          status: state.reservationsStatusFilter,
        ));
      } else {
        emit(state.copyWith(
          actionStatus: AdminStatus.error,
          errorMessage: result.message ?? 'Erreur de remboursement',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminStatus.error,
        errorMessage: 'Erreur lors du remboursement: $e',
      ));
    }
  }

  Future<void> _onBroadcastNotification(
    BroadcastNotification event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(actionStatus: AdminStatus.loading));
    try {
      await repository.broadcastNotification(
        title: event.title,
        message: event.message,
        targetRole: event.targetRole,
      );
      emit(state.copyWith(
        actionStatus: AdminStatus.success,
        successMessage: 'Notification envoyée avec succès',
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminStatus.error,
        errorMessage: 'Erreur d\'envoi de la notification: $e',
      ));
    }
  }

  Future<void> _onLoadSupportRequests(
    LoadSupportRequests event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(
      supportStatus: AdminStatus.loading,
      supportStatusFilter: event.status,
      clearSupportStatusFilter: event.status == null,
    ));
    try {
      final response = await repository.getSupportRequests(
        page: event.page,
        status: event.status,
      );
      emit(state.copyWith(
        supportRequests: response.requests,
        supportTotal: response.total,
        supportPage: response.page,
        supportTotalPages: response.totalPages,
        supportStatus: AdminStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        supportStatus: AdminStatus.error,
        errorMessage: 'Erreur de chargement des demandes de support: $e',
      ));
    }
  }

  Future<void> _onUpdateSupportRequest(
    UpdateSupportRequest event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(actionStatus: AdminStatus.loading));
    try {
      await repository.updateSupportRequest(
        event.requestId,
        status: event.status,
        adminNotes: event.adminNotes,
      );
      emit(state.copyWith(
        actionStatus: AdminStatus.success,
        successMessage: 'Demande mise à jour avec succès',
      ));
      // Reload support requests
      add(LoadSupportRequests(
        page: state.supportPage,
        status: state.supportStatusFilter,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminStatus.error,
        errorMessage: 'Erreur de mise à jour: $e',
      ));
    }
  }

  Future<void> _onRespondToSupportRequest(
    RespondToSupportRequest event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(actionStatus: AdminStatus.loading));
    try {
      await repository.respondToSupportRequest(
        event.requestId,
        responseMessage: event.responseMessage,
        sendEmail: event.sendEmail,
        sendNotification: event.sendNotification,
      );
      emit(state.copyWith(
        actionStatus: AdminStatus.success,
        successMessage: 'Réponse envoyée avec succès',
      ));
      // Reload support requests
      add(LoadSupportRequests(
        page: state.supportPage,
        status: state.supportStatusFilter,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminStatus.error,
        errorMessage: 'Erreur lors de l\'envoi de la réponse: $e',
      ));
    }
  }

  Future<void> _onDeleteSupportRequest(
    DeleteSupportRequest event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(actionStatus: AdminStatus.loading));
    try {
      await repository.deleteSupportRequest(event.requestId);
      emit(state.copyWith(
        actionStatus: AdminStatus.success,
        successMessage: 'Demande supprimée avec succès',
      ));
      // Reload support requests
      add(LoadSupportRequests(
        page: state.supportPage,
        status: state.supportStatusFilter,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AdminStatus.error,
        errorMessage: 'Erreur lors de la suppression: $e',
      ));
    }
  }

  void _onClearUserDetails(
    ClearUserDetails event,
    Emitter<AdminState> emit,
  ) {
    emit(state.copyWith(
      clearSelectedUser: true,
      userDetailsStatus: AdminStatus.initial,
    ));
  }

  void _onClearReservationDetails(
    ClearReservationDetails event,
    Emitter<AdminState> emit,
  ) {
    emit(state.copyWith(
      clearSelectedReservation: true,
      reservationDetailsStatus: AdminStatus.initial,
    ));
  }

  void _onClearError(
    ClearError event,
    Emitter<AdminState> emit,
  ) {
    emit(state.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
      actionStatus: AdminStatus.initial,
    ));
  }
}
