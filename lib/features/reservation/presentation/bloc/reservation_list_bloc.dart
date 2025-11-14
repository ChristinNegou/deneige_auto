import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/usecases/get_reservations_usecase.dart';
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

// States
class ReservationListState extends Equatable {
  final List<Reservation> reservations;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ReservationListState({
    this.reservations = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ReservationListState copyWith({
    List<Reservation>? reservations,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ReservationListState(
      reservations: reservations ?? this.reservations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [reservations, isLoading, errorMessage, successMessage];
}

// BLoC
class ReservationListBloc extends Bloc<ReservationListEvent, ReservationListState> {
  final GetReservationsUseCase getReservations;
  final CancelReservationUseCase cancelReservation;

  ReservationListBloc({
    required this.getReservations,
    required this.cancelReservation,
  }) : super(const ReservationListState()) {
    on<LoadReservations>(_onLoadReservations);
    on<RefreshReservations>(_onRefreshReservations);
    on<CancelReservationEvent>(_onCancelReservation);
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
          (reservations) => emit(state.copyWith(
        isLoading: false,
        reservations: reservations,
        clearError: true,
      )),
    );
  }

  Future<void> _onRefreshReservations(
      RefreshReservations event,
      Emitter<ReservationListState> emit,
      ) async {
    final result = await getReservations(upcoming: false);

    result.fold(
          (failure) => emit(state.copyWith(errorMessage: failure.message)),
          (reservations) => emit(state.copyWith(
        reservations: reservations,
        clearError: true,
      )),
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
}