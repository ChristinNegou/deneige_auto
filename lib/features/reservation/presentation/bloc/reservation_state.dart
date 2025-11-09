import 'package:equatable/equatable.dart';
import '../../domain/entities/reservation.dart';

/// États du BLoC de réservation
abstract class ReservationState extends Equatable {
  const ReservationState();

  @override
  List<Object?> get props => [];
}

/// État initial
class ReservationInitial extends ReservationState {}

/// État de chargement
class ReservationLoading extends ReservationState {}

/// État avec la liste des réservations chargée
class ReservationsLoaded extends ReservationState {
  final List<Reservation> reservations;

  const ReservationsLoaded({required this.reservations});

  @override
  List<Object?> get props => [reservations];
}

/// État avec une réservation unique chargée
class ReservationLoaded extends ReservationState {
  final Reservation reservation;

  const ReservationLoaded({required this.reservation});

  @override
  List<Object?> get props => [reservation];
}

/// État de réservation créée avec succès
class ReservationCreated extends ReservationState {
  final Reservation reservation;

  const ReservationCreated({required this.reservation});

  @override
  List<Object?> get props => [reservation];
}

/// État de réservation mise à jour avec succès
class ReservationUpdated extends ReservationState {
  final Reservation reservation;

  const ReservationUpdated({required this.reservation});

  @override
  List<Object?> get props => [reservation];
}

/// État de réservation annulée avec succès
class ReservationCancelled extends ReservationState {}

/// État d'erreur
class ReservationError extends ReservationState {
  final String message;

  const ReservationError({required this.message});

  @override
  List<Object?> get props => [message];
}