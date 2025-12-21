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
  });

  bool get canSubmit =>
      selectedVehicle != null &&
      selectedParkingSpot != null &&
      departureTime != null &&
      calculatedPrice != null &&
      !isLoading;

  bool get hasChanges {
    if (originalReservation == null) return false;

    return selectedVehicle?.id != originalReservation!.vehicle.id ||
        selectedParkingSpot?.id != originalReservation!.parkingSpot.id ||
        departureTime != originalReservation!.departureTime ||
        !_serviceOptionsEqual(selectedOptions, originalReservation!.serviceOptions);
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
  }) {
    return EditReservationState(
      originalReservation: originalReservation ?? this.originalReservation,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      availableParkingSpots: availableParkingSpots ?? this.availableParkingSpots,
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
      ];
}

// ==================== BLOC ====================

class EditReservationBloc extends Bloc<EditReservationEvent, EditReservationState> {
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

    // Vérifier si c'est urgent (moins de 45 minutes)
    final now = DateTime.now();
    final minutesUntilDeparture = event.departureTime.difference(now).inMinutes;

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
    // Vérifier qu'il y a un véhicule et une place de parking
    if (state.selectedVehicle == null || state.selectedParkingSpot == null) {
      return;
    }

    double basePrice = AppConfig.basePrice;

    // Calcul du facteur véhicule
    final vehicleFactor = state.selectedVehicle!.type.priceFactor;
    double price = basePrice * vehicleFactor;

    // Calcul du facteur parking
    final parkingFactor = state.selectedParkingSpot!.level.priceFactor;
    price *= parkingFactor;

    // Calcul du supplément neige (si disponible dans la réservation originale)
    if (state.originalReservation?.snowDepthCm != null &&
        state.originalReservation!.snowDepthCm! > 10) {
      final snowSurcharge = (state.originalReservation!.snowDepthCm! - 10) * AppConfig.pricePerCm;
      price += snowSurcharge;
    }

    // Calcul du coût des options
    double optionsCost = 0;
    for (final option in state.selectedOptions) {
      switch (option) {
        case ServiceOption.windowScraping:
          optionsCost += 5.0;
          break;
        case ServiceOption.doorDeicing:
          optionsCost += AppConfig.doorDeicingSurcharge;
          break;
        case ServiceOption.wheelClearance:
          optionsCost += AppConfig.wheelClearanceSurcharge;
          break;
      }
    }
    price += optionsCost;

    // Calcul des frais d'urgence (si départ dans moins de 45 minutes)
    if (state.departureTime != null) {
      final now = DateTime.now();
      final minutesUntilDeparture = state.departureTime!.difference(now).inMinutes;

      if (minutesUntilDeparture < AppConfig.urgencyThresholdMinutes) {
        final urgencyFee = price * AppConfig.urgencyFeePercentage;
        price += urgencyFee;
      }
    }

    emit(state.copyWith(calculatedPrice: price));
  }

  Future<void> _onSubmitUpdate(
    SubmitReservationUpdate event,
    Emitter<EditReservationState> emit,
  ) async {
    if (!state.canSubmit || !state.hasChanges) return;

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
