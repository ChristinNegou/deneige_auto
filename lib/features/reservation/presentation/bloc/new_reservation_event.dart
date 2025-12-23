import 'package:equatable/equatable.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/parking_spot.dart';
import '../../../../core/config/app_config.dart';

// ==================== EVENTS ====================
abstract class NewReservationEvent extends Equatable {
  const NewReservationEvent();

  @override
  List<Object?> get props => [];
}

// Step 1 Events
class LoadInitialData extends NewReservationEvent {}

class SelectVehicle extends NewReservationEvent {
  final Vehicle vehicle;
  const SelectVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class SelectParkingSpot extends NewReservationEvent {
  final ParkingSpot parkingSpot;
  const SelectParkingSpot(this.parkingSpot);

  @override
  List<Object?> get props => [parkingSpot];
}

class UpdateParkingSpotNumber extends NewReservationEvent {
  final String spotNumber;

  const UpdateParkingSpotNumber(this.spotNumber);

  @override
  List<Object?> get props => [spotNumber];
}

class UpdateCustomLocation extends NewReservationEvent {
  final String location;

  const UpdateCustomLocation(this.location);

  @override
  List<Object?> get props => [location];
}


// Step 2 Events
class SelectDateTime extends NewReservationEvent {
  final DateTime departureDateTime;
  const SelectDateTime(this.departureDateTime);

  @override
  List<Object?> get props => [departureDateTime];
}

// Step 3 Events
class ToggleServiceOption extends NewReservationEvent {
  final ServiceOption option;
  const ToggleServiceOption(this.option);

  @override
  List<Object?> get props => [option];
}

class UpdateSnowDepth extends NewReservationEvent {
  final int? snowDepthCm;
  const UpdateSnowDepth(this.snowDepthCm);

  @override
  List<Object?> get props => [snowDepthCm];
}

// Step 4 Events
class CalculatePrice extends NewReservationEvent {}

class SubmitReservation extends NewReservationEvent {
  final String paymentMethod;
  final String? paymentIntentId;

  const SubmitReservation(this.paymentMethod, {this.paymentIntentId});

  @override
  List<Object?> get props => [paymentMethod, paymentIntentId];

}

// Navigation Events
class GoToNextStep extends NewReservationEvent {}
class GoToPreviousStep extends NewReservationEvent {}
class ResetReservation extends NewReservationEvent {}

// Location Events
class GetCurrentLocation extends NewReservationEvent {}

class SetLocationFromAddress extends NewReservationEvent {
  final String address;
  const SetLocationFromAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class ClearLocationError extends NewReservationEvent {}