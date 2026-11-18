import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_parking_spots_usecase.dart';
import '../../domain/usecases/get_vehicules_usecase.dart';
import '../../domain/usecases/update_reservation_usecase.dart';

// ==================== EVENTS ====================

abstract class EditReservationEvent extends Equatable {
  const EditReservationEvent();

  @override
  List<Object?> get props => [];
}

class LoadEditReservationData extends EditReservationEvent {
  final Reservation reservation;

  const LoadEditReservationData(this.reservation);

  @override
  List<Object?> get props => [reservation];
}

class UpdateVehicle extends EditReservationEvent {
  final Vehicle vehicle;

  const UpdateVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class UpdateParkingSpot extends EditReservationEvent {
  final ParkingSpot parkingSpot;

  const UpdateParkingSpot(this.parkingSpot);

  @override
  List<Object?> get props => [parkingSpot];
}

class UpdateDepartureTime extends EditReservationEvent {
  final DateTime departureTime;

  const UpdateDepartureTime(this.departureTime);

  @override
  List<Object?> get props => [departureTime];
}

class ToggleServiceOptionEdit extends EditReservationEvent {
  final ServiceOption option;

  const ToggleServiceOptionEdit(this.option);

  @override
  List<Object?> get props => [option];
}

class RecalculatePrice extends EditReservationEvent {}

class SubmitReservationUpdate extends EditReservationEvent {}

/// Le texte de l'adresse a change sans qu'une suggestion soit choisie.
class AddressEdited extends EditReservationEvent {}

class UpdateLocationAddress extends EditReservationEvent {
  final String address;
  final double? latitude;
  final double? longitude;

  const UpdateLocationAddress({
    required this.address,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [address, latitude, longitude];
}

// ==================== STATE ====================

class EditReservationState extends Equatable {
  final Reservation? originalReservation;
  final List<Vehicle> availableVehicles;
  final List<ParkingSpot> availableParkingSpots;
  final Vehicle? selectedVehicle;
  final ParkingSpot? selectedParkingSpot;
  final DateTime? departureTime;
  final DateTime? deadlineTime;
  final List<ServiceOption> selectedOptions;
  final double? calculatedPrice;
  final bool isLoading;
  final bool isLoadingData;
  final String? errorMessage;
  final bool isUpdateSuccessful;

  // Location fields
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;

  /// Adresse en cours de saisie : il faut choisir une suggestion avant
  /// d'enregistrer.
  final bool addressPending;

  const EditReservationState({
    this.originalReservation,
    this.availableVehicles = const [],
    this.availableParkingSpots = const [],
    this.selectedVehicle,
    this.selectedParkingSpot,
    this.departureTime,
    this.deadlineTime,
    this.selectedOptions = const [],
    this.calculatedPrice,
    this.isLoading = false,
    this.isLoadingData = false,
    this.errorMessage,
    this.isUpdateSuccessful = false,
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
    this.addressPending = false,
  });

  bool get canSubmit =>
      selectedVehicle != null &&
      selectedParkingSpot != null &&
      departureTime != null &&
      calculatedPrice != null &&
      !addressPending &&
      !isLoading;

  bool get hasChanges {
    if (originalReservation == null) return false;

    return selectedVehicle?.id != originalReservation!.vehicle.id ||
        selectedParkingSpot?.id != originalReservation!.parkingSpot.id ||
        departureTime != originalReservation!.departureTime ||
        !_serviceOptionsEqual(
            selectedOptions, originalReservation!.serviceOptions) ||
        locationAddress != originalReservation!.locationAddress;
  }

  /// Vrai si les choix actuels donneraient un autre prix que celui paye
  /// (categorie de vehicule, type de place, options). Le serveur refuse ces
  /// modifications : il faut annuler et refaire une reservation.
  bool get changesPrice {
    final original = originalReservation;
    if (original == null) return false;
    return (selectedVehicle?.type.priceFactor ??
                original.vehicle.type.priceFactor) !=
            original.vehicle.type.priceFactor ||
        (selectedParkingSpot?.level.priceFactor ??
                original.parkingSpot.level.priceFactor) !=
            original.parkingSpot.level.priceFactor ||
        !_serviceOptionsEqual(selectedOptions, original.serviceOptions);
  }

  bool _serviceOptionsEqual(List<ServiceOption> a, List<ServiceOption> b) {
    if (a.length != b.length) return false;
    return a.toSet().difference(b.toSet()).isEmpty;
  }

  EditReservationState copyWith({
    Reservation? originalReservation,
    List<Vehicle>? availableVehicles,
    List<ParkingSpot>? availableParkingSpots,
    Vehicle? selectedVehicle,
    ParkingSpot? selectedParkingSpot,
    DateTime? departureTime,
    DateTime? deadlineTime,
    List<ServiceOption>? selectedOptions,
    double? calculatedPrice,
    bool? isLoading,
    bool? isLoadingData,
    String? errorMessage,
    bool? isUpdateSuccessful,
    bool clearError = false,
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
    bool? addressPending,
  }) {
    return EditReservationState(
      originalReservation: originalReservation ?? this.originalReservation,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      availableParkingSpots:
          availableParkingSpots ?? this.availableParkingSpots,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      selectedParkingSpot: selectedParkingSpot ?? this.selectedParkingSpot,
      departureTime: departureTime ?? this.departureTime,
      deadlineTime: deadlineTime ?? this.deadlineTime,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      calculatedPrice: calculatedPrice ?? this.calculatedPrice,
      isLoading: isLoading ?? this.isLoading,
      isLoadingData: isLoadingData ?? this.isLoadingData,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUpdateSuccessful: isUpdateSuccessful ?? this.isUpdateSuccessful,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationAddress: locationAddress ?? this.locationAddress,
      addressPending: addressPending ?? this.addressPending,
    );
  }

  @override
  List<Object?> get props => [
        originalReservation,
        availableVehicles,
        availableParkingSpots,
        selectedVehicle,
        selectedParkingSpot,
        departureTime,
        deadlineTime,
        selectedOptions,
        calculatedPrice,
        isLoading,
        isLoadingData,
        errorMessage,
        isUpdateSuccessful,
        locationLatitude,
        locationLongitude,
        locationAddress,
        addressPending,
      ];
}

// ==================== BLOC ====================

class EditReservationBloc
    extends Bloc<EditReservationEvent, EditReservationState> {
  final GetVehiclesUseCase getVehicles;
  final GetParkingSpotsUseCase getParkingSpots;
  final UpdateReservationUseCase updateReservation;

  EditReservationBloc({
    required this.getVehicles,
    required this.getParkingSpots,
    required this.updateReservation,
  }) : super(const EditReservationState()) {
    on<LoadEditReservationData>(_onLoadEditReservationData);
    on<UpdateVehicle>(_onUpdateVehicle);
    on<UpdateParkingSpot>(_onUpdateParkingSpot);
    on<UpdateDepartureTime>(_onUpdateDepartureTime);
    on<ToggleServiceOptionEdit>(_onToggleServiceOption);
    on<RecalculatePrice>(_onRecalculatePrice);
    on<SubmitReservationUpdate>(_onSubmitUpdate);
    on<UpdateLocationAddress>(_onUpdateLocationAddress);
    on<AddressEdited>(
        (event, emit) => emit(state.copyWith(addressPending: true)));
  }

  Future<void> _onLoadEditReservationData(
    LoadEditReservationData event,
    Emitter<EditReservationState> emit,
  ) async {
    emit(state.copyWith(
      isLoadingData: true,
      originalReservation: event.reservation,
    ));

    // Charger les véhicules et places de parking disponibles
    final vehiclesResult = await getVehicles();
    final parkingSpotsResult = await getParkingSpots(availableOnly: false);

    final vehicles = vehiclesResult.fold(
      (failure) => <Vehicle>[],
      (list) => list,
    );

    final parkingSpots = parkingSpotsResult.fold(
      (failure) => <ParkingSpot>[],
      (list) => list,
    );

    // Pré-remplir avec les données actuelles de la réservation
    emit(state.copyWith(
      isLoadingData: false,
      availableVehicles: vehicles,
      availableParkingSpots: parkingSpots,
      selectedVehicle: event.reservation.vehicle,
      selectedParkingSpot: event.reservation.parkingSpot,
      departureTime: event.reservation.departureTime,
      deadlineTime: event.reservation.deadlineTime,
      selectedOptions: event.reservation.serviceOptions,
      calculatedPrice: event.reservation.totalPrice,
      locationLatitude: event.reservation.locationLatitude,
      locationLongitude: event.reservation.locationLongitude,
      locationAddress: event.reservation.locationAddress,
    ));
  }

  void _onUpdateLocationAddress(
    UpdateLocationAddress event,
    Emitter<EditReservationState> emit,
  ) {
    emit(state.copyWith(
      locationAddress: event.address,
      locationLatitude: event.latitude,
      locationLongitude: event.longitude,
      addressPending: false,
    ));
  }

  void _onUpdateVehicle(
    UpdateVehicle event,
    Emitter<EditReservationState> emit,
  ) {
    emit(state.copyWith(selectedVehicle: event.vehicle));
    add(RecalculatePrice());
  }

  void _onUpdateParkingSpot(
    UpdateParkingSpot event,
    Emitter<EditReservationState> emit,
  ) {
    emit(state.copyWith(selectedParkingSpot: event.parkingSpot));
    add(RecalculatePrice());
  }

  void _onUpdateDepartureTime(
    UpdateDepartureTime event,
    Emitter<EditReservationState> emit,
  ) {
    // Calculer la deadline (30 minutes avant le départ)
    final deadline = event.departureTime.subtract(const Duration(minutes: 30));

    emit(state.copyWith(
      departureTime: event.departureTime,
      deadlineTime: deadline,
    ));

    add(RecalculatePrice());
  }

  void _onToggleServiceOption(
    ToggleServiceOptionEdit event,
    Emitter<EditReservationState> emit,
  ) {
    final newOptions = List<ServiceOption>.from(state.selectedOptions);

    if (newOptions.contains(event.option)) {
      newOptions.remove(event.option);
    } else {
      newOptions.add(event.option);
    }

    emit(state.copyWith(selectedOptions: newOptions));
    add(RecalculatePrice());
  }

  void _onRecalculatePrice(
    RecalculatePrice event,
    Emitter<EditReservationState> emit,
  ) {
    // Le prix paye ne change jamais a la modification : seules les
    // modifications sans effet sur le prix sont enregistrees (voir
    // changesPrice). Recalculer ici donnait un prix sans frais ni taxes.
    final paid = state.originalReservation?.totalPrice;
    if (paid != null && state.calculatedPrice != paid) {
      emit(state.copyWith(calculatedPrice: paid));
    }
  }

  Future<void> _onSubmitUpdate(
    SubmitReservationUpdate event,
    Emitter<EditReservationState> emit,
  ) async {
    if (!state.canSubmit || !state.hasChanges || state.changesPrice) return;

    // Vérifier que la réservation peut toujours être modifiée
    if (state.originalReservation?.canBeEdited != true) {
      emit(state.copyWith(
        errorMessage: 'Cette réservation ne peut plus être modifiée',
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final params = UpdateReservationParams(
      reservationId: state.originalReservation!.id,
      vehicleId: state.selectedVehicle!.id,
      parkingSpotId: state.selectedParkingSpot!.id,
      departureTime: state.departureTime!,
      deadlineTime: state.deadlineTime!,
      serviceOptions: state.selectedOptions,
      snowDepthCm: state.originalReservation!.snowDepthCm,
      totalPrice: state.calculatedPrice!,
      latitude: state.locationLatitude,
      longitude: state.locationLongitude,
      address: state.locationAddress,
    );

    final result = await updateReservation(params);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ));
      },
      (updatedReservation) {
        emit(state.copyWith(
          isLoading: false,
          isUpdateSuccessful: true,
        ));
      },
    );
  }
}
