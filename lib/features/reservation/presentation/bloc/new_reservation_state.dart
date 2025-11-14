import 'package:equatable/equatable.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/parking_spot.dart';
import '../../../../core/config/app_config.dart';

class NewReservationState extends Equatable {
  final int currentStep;
  final Vehicle? selectedVehicle;
  final ParkingSpot? selectedParkingSpot;
  final List<Vehicle> availableVehicles;
  final List<ParkingSpot> availableParkingSpots;
  final DateTime? departureDateTime;
  final DateTime? deadlineTime;
  final bool isUrgent;
  final List<ServiceOption> selectedOptions;
  final int? snowDepthCm;
  final double? calculatedPrice;
  final PriceBreakdown? priceBreakdown;
  final bool isLoading;
  final bool isLoadingData;
  final String? errorMessage;
  final bool isSubmitted;
  final String? reservationId;

  const NewReservationState({
    this.currentStep = 0,
    this.selectedVehicle,
    this.selectedParkingSpot,
    this.availableVehicles = const [],
    this.availableParkingSpots = const [],
    this.departureDateTime,
    this.deadlineTime,
    this.isUrgent = false,
    this.selectedOptions = const [],
    this.snowDepthCm,
    this.calculatedPrice,
    this.priceBreakdown,
    this.isLoading = false,
    this.isLoadingData = false,
    this.errorMessage,
    this.isSubmitted = false,
    this.reservationId,
  });

  bool get canProceedStep1 {
    return selectedVehicle != null && selectedParkingSpot != null;
  }

  bool get canProceedStep2 {
    return departureDateTime != null && _validateDateTime(departureDateTime) == null;
  }

  bool get canProceedStep3 {
    return true;
  }

  bool get canSubmit {
    return canProceedStep1 && canProceedStep2 && calculatedPrice != null;
  }

  String? _validateDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Date requise';

    final now = DateTime.now();
    final minTime = now.add(Duration(minutes: AppConfig.minReservationTimeMinutes));

    if (dateTime.isBefore(minTime)) {
      return 'Le départ doit être dans au moins ${AppConfig.minReservationTimeMinutes} minutes';
    }

    final maxTime = now.add(const Duration(days: 30));
    if (dateTime.isAfter(maxTime)) {
      return 'Le départ ne peut pas être dans plus de 30 jours';
    }

    if (dateTime.hour < 5 || dateTime.hour >= 23) {
      return 'L\'heure doit être entre 05:00 et 23:00';
    }

    return null;
  }

  NewReservationState copyWith({
    int? currentStep,
    Vehicle? selectedVehicle,
    ParkingSpot? selectedParkingSpot,
    List<Vehicle>? availableVehicles,
    List<ParkingSpot>? availableParkingSpots,
    DateTime? departureDateTime,
    DateTime? deadlineTime,
    bool? isUrgent,
    List<ServiceOption>? selectedOptions,
    int? snowDepthCm,
    double? calculatedPrice,
    PriceBreakdown? priceBreakdown,
    bool? isLoading,
    bool? isLoadingData,
    String? errorMessage,
    bool? isSubmitted,
    String? reservationId,
  }) {
    return NewReservationState(
      currentStep: currentStep ?? this.currentStep,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      selectedParkingSpot: selectedParkingSpot ?? this.selectedParkingSpot,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      availableParkingSpots: availableParkingSpots ?? this.availableParkingSpots,
      departureDateTime: departureDateTime ?? this.departureDateTime,
      deadlineTime: deadlineTime ?? this.deadlineTime,
      isUrgent: isUrgent ?? this.isUrgent,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      snowDepthCm: snowDepthCm ?? this.snowDepthCm,
      calculatedPrice: calculatedPrice ?? this.calculatedPrice,
      priceBreakdown: priceBreakdown ?? this.priceBreakdown,
      isLoading: isLoading ?? this.isLoading,
      isLoadingData: isLoadingData ?? this.isLoadingData,
      errorMessage: errorMessage,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      reservationId: reservationId ?? this.reservationId,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    selectedVehicle,
    selectedParkingSpot,
    availableVehicles,
    availableParkingSpots,
    departureDateTime,
    deadlineTime,
    isUrgent,
    selectedOptions,
    snowDepthCm,
    calculatedPrice,
    priceBreakdown,
    isLoading,
    isLoadingData,
    errorMessage,
    isSubmitted,
    reservationId,
  ];
}

class PriceBreakdown extends Equatable {
  final double basePrice;
  final double vehicleAdjustment;
  final double parkingAdjustment;
  final double snowSurcharge;
  final double optionsCost;
  final double urgencyFee;
  final double totalPrice;

  const PriceBreakdown({
    required this.basePrice,
    required this.vehicleAdjustment,
    required this.parkingAdjustment,
    required this.snowSurcharge,
    required this.optionsCost,
    required this.urgencyFee,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [
    basePrice,
    vehicleAdjustment,
    parkingAdjustment,
    snowSurcharge,
    optionsCost,
    urgencyFee,
    totalPrice,
  ];
}