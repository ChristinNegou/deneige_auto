import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/cancel_reservation_usecase.dart';
import '../../domain/usecases/create_reservation_usecase.dart';
import '../../domain/usecases/get_reservations_usecase.dart';
import 'reservation_event.dart';
import 'reservation_state.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final GetReservationsUseCase getReservations;
  final CreateReservationUseCase createReservation;
  final CancelReservationUseCase cancelReservation;

  ReservationBloc({
    required this.getReservations,
    required this.createReservation,
    required this.cancelReservation,
  }) : super(ReservationInitial()) {
    on<LoadReservations>(_onLoadReservations);
    on<CreateNewReservation>(_onCreateReservation);
    on<CancelReservation>(_onCancelReservation);
  }

  Future<void> _onLoadReservations(
      LoadReservations event,
      Emitter<ReservationState> emit,
      ) async {
    emit(ReservationLoading());

    final result = await getReservations(
      upcoming: event.upcoming,
      userId: event.userId,
    );

    result.fold(
          (failure) => emit(ReservationError(message: failure.message)),
          (reservations) => emit(ReservationsLoaded(reservations: reservations)),
    );
  }

  Future<void> _onCreateReservation(
      CreateNewReservation event,
      Emitter<ReservationState> emit,
      ) async {
    emit(ReservationLoading());

    final result = await createReservation(event.reservation);

    result.fold(
          (failure) => emit(ReservationError(message: failure.message)),
          (reservation) => emit(ReservationCreated(reservation: reservation)),
    );
  }

  Future<void> _onCancelReservation(
      CancelReservation event,
      Emitter<ReservationState> emit,
      ) async {
    emit(ReservationLoading());

    final result = await cancelReservation(event.reservationId);

    result.fold(
          (failure) => emit(ReservationError(message: failure.message)),
          (_) => emit(ReservationCancelled()),
    );
  }
}