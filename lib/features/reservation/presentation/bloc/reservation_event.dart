import 'package:equatable/equatable.dart';
import '../../domain/entities/reservation.dart';

/// Événements du BLoC de réservation
abstract class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

/// Événement pour charger la liste des réservations
class LoadReservations extends ReservationEvent {
  final bool? upcoming;
  final String? userId;

  const LoadReservations({
    this.upcoming,
    this.userId,
  });

  @override
  List<Object?> get props => [upcoming, userId];
}

/// Événement pour créer une nouvelle réservation
class CreateNewReservation extends ReservationEvent {
  final Reservation reservation;

  const CreateNewReservation({required this.reservation});

  @override
  List<Object?> get props => [reservation];
}

/// Événement pour annuler une réservation
class CancelReservation extends ReservationEvent {
  final String reservationId;

  const CancelReservation({required this.reservationId});

  @override
  List<Object?> get props => [reservationId];
}

/// Événement pour charger une réservation par son ID
class LoadReservationById extends ReservationEvent {
  final String reservationId;

  const LoadReservationById({required this.reservationId});

  @override
  List<Object?> get props => [reservationId];
}

/// Événement pour mettre à jour une réservation
class UpdateReservation extends ReservationEvent {
  final Reservation reservation;

  const UpdateReservation({required this.reservation});

  @override
  List<Object?> get props => [reservation];
}