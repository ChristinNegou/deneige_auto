import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/usecases/get_reservations_usecase.dart';
import '../../domain/usecases/get_reservation_by_id_usecase.dart';
import '../../domain/usecases/cancel_reservation_usecase.dart';

// Events
abstract class ReservationListEvent extends Equatable {
  const ReservationListEvent();

  @override
  List<Object?> get props => [];
}

class LoadReservations extends ReservationListEvent {
  final bool upcomingOnly;

  const LoadReservations({this.upcomingOnly = false});

  @override
  List<Object?> get props => [upcomingOnly];
}

class RefreshReservations extends ReservationListEvent {}

class CancelReservationEvent extends ReservationListEvent {
  final String reservationId;

  const CancelReservationEvent(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

class LoadReservationById extends ReservationListEvent {
  final String reservationId;

  const LoadReservationById(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

/// Événement pour charger toutes les réservations (incluant terminées)
/// Utilisé pour la page "Activités"
class LoadAllReservations extends ReservationListEvent {
  const LoadAllReservations();
}

// States
class ReservationListState extends Equatable {
  final List<Reservation> reservations;
  final Reservation? selectedReservation;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ReservationListState({
    this.reservations = const [],
    this.selectedReservation,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ReservationListState copyWith({
    List<Reservation>? reservations,
    Reservation? selectedReservation,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSelectedReservation = false,
  }) {
    return ReservationListState(
      reservations: reservations ?? this.reservations,
      selectedReservation: clearSelectedReservation ? null : (selectedReservation ?? this.selectedReservation),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [reservations, selectedReservation, isLoading, errorMessage, successMessage];
}

// BLoC
class ReservationListBloc extends Bloc<ReservationListEvent, ReservationListState> {
  final GetReservationsUseCase getReservations;
  final GetReservationByIdUseCase getReservationById;
  final CancelReservationUseCase cancelReservation;

  ReservationListBloc({
    required this.getReservations,
    required this.getReservationById,
    required this.cancelReservation,
  }) : super(const ReservationListState(isLoading: true)) {
    on<LoadReservations>(_onLoadReservations);
    on<RefreshReservations>(_onRefreshReservations);
    on<CancelReservationEvent>(_onCancelReservation);
    on<LoadReservationById>(_onLoadReservationById);
    on<LoadAllReservations>(_onLoadAllReservations);
  }

  Future<void> _onLoadReservations(
      LoadReservations event,
      Emitter<ReservationListState> emit,
      ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await getReservations(upcoming: event.upcomingOnly);

    result.fold(
          (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
          (reservations) {
        // Filtrer pour afficher uniquement les réservations actives et non passées
        final activeReservations = reservations.where((r) =>
          !r.isPast &&
          (r.status == ReservationStatus.pending ||
           r.status == ReservationStatus.assigned ||
           r.status == ReservationStatus.enRoute ||
           r.status == ReservationStatus.inProgress)
        ).toList();

        emit(state.copyWith(
          isLoading: false,
          reservations: activeReservations,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onRefreshReservations(
      RefreshReservations event,
      Emitter<ReservationListState> emit,
      ) async {
    final result = await getReservations(upcoming: false);

    result.fold(
          (failure) => emit(state.copyWith(errorMessage: failure.message)),
          (reservations) {
        // Filtrer pour afficher uniquement les réservations actives et non passées
        final activeReservations = reservations.where((r) =>
          !r.isPast &&
          (r.status == ReservationStatus.pending ||
           r.status == ReservationStatus.assigned ||
           r.status == ReservationStatus.enRoute ||
           r.status == ReservationStatus.inProgress)
        ).toList();

        emit(state.copyWith(
          reservations: activeReservations,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onCancelReservation(
      CancelReservationEvent event,
      Emitter<ReservationListState> emit,
      ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await cancelReservation(event.reservationId);

    result.fold(
          (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
          (_) {
        // Supprimer la réservation de la liste
        final updatedReservations = state.reservations
            .where((r) => r.id != event.reservationId)
            .toList();

        emit(state.copyWith(
          isLoading: false,
          reservations: updatedReservations,
          successMessage: 'Réservation annulée avec succès',
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLoadReservationById(
      LoadReservationById event,
      Emitter<ReservationListState> emit,
      ) async {
    // Ne montrer le loading que si on n'a pas encore de réservation (premier chargement)
    final isInitialLoad = state.selectedReservation == null;
    if (isInitialLoad) {
      emit(state.copyWith(isLoading: true, clearError: true));
    }

    final result = await getReservationById(event.reservationId);

    result.fold(
          (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
          (reservation) {
        emit(state.copyWith(
          isLoading: false,
          selectedReservation: reservation,
          clearError: true,
        ));
      },
    );
  }

  /// Charge toutes les réservations (incluant en cours et terminées)
  /// pour la page "Activités"
  Future<void> _onLoadAllReservations(
      LoadAllReservations event,
      Emitter<ReservationListState> emit,
      ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await getReservations(upcoming: false);

    result.fold(
          (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
          (reservations) {
        // Filtrer pour afficher les réservations en cours et terminées
        // Exclure: pending (en attente), cancelled (annulées)
        final activityReservations = reservations.where((r) =>
          r.status == ReservationStatus.assigned ||
          r.status == ReservationStatus.enRoute ||
          r.status == ReservationStatus.inProgress ||
          r.status == ReservationStatus.completed
        ).toList();

        // Trier par date (les plus récentes en premier)
        activityReservations.sort((a, b) =>
          b.departureTime.compareTo(a.departureTime));

        emit(state.copyWith(
          isLoading: false,
          reservations: activityReservations,
          clearError: true,
        ));
      },
    );
  }
}