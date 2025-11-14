import 'package:deneige_auto/features/reservation/domain/entities/parking_spot.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/usecases/create_reservation_usecase.dart';
import '../../domain/usecases/get_parking_spots_usecase.dart';
import '../../domain/usecases/get_vehicules_usecase.dart';
import 'new_reservation_event.dart';
import 'new_reservation_state.dart';

class NewReservationBloc extends Bloc<NewReservationEvent, NewReservationState> {
  final GetVehiclesUseCase getVehicles;
  final GetParkingSpotsUseCase getParkingSpots;
  final CreateReservationUseCase createReservation;

  NewReservationBloc({
    required this.getVehicles,
    required this.getParkingSpots,
    required this.createReservation,
  }) : super(const NewReservationState()) {
    on<LoadInitialData>(_onLoadInitialData);
    on<SelectVehicle>(_onSelectVehicle);
    on<SelectParkingSpot>(_onSelectParkingSpot);
    on<SelectDateTime>(_onSelectDateTime);
    on<ToggleServiceOption>(_onToggleServiceOption);
    on<UpdateSnowDepth>(_onUpdateSnowDepth);
    on<CalculatePrice>(_onCalculatePrice);
    on<SubmitReservation>(_onSubmitReservation);
    on<GoToNextStep>(_onGoToNextStep);
    on<GoToPreviousStep>(_onGoToPreviousStep);
    on<ResetReservation>(_onResetReservation);
    on<UpdateParkingSpotNumber>(_onUpdateParkingSpotNumber);
    on<UpdateCustomLocation>(_onUpdateCustomLocation);


  }

  Future<void> _onLoadInitialData(
      LoadInitialData event,
      Emitter<NewReservationState> emit,
      ) async {
    emit(state.copyWith(isLoadingData: true));

    try {
      final vehiclesResult = await getVehicles();
      final parkingSpotsResult = await getParkingSpots(availableOnly: true);

      emit(state.copyWith(
        isLoadingData: false,
        availableVehicles: vehiclesResult.fold(
              (failure) => [],
              (vehicles) => vehicles,
        ),
        availableParkingSpots: parkingSpotsResult.fold(
              (failure) => [],
              (spots) => spots,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingData: false,
        errorMessage: 'Erreur lors du chargement des données',
      ));
    }
  }

  void _onSelectVehicle(
      SelectVehicle event,
      Emitter<NewReservationState> emit,
      ) {
    emit(state.copyWith(selectedVehicle: event.vehicle));
    if (state.currentStep >= 2) {
      add(CalculatePrice());
    }
  }

  void _onSelectParkingSpot(
      SelectParkingSpot event,
      Emitter<NewReservationState> emit,
      ) {
    emit(state.copyWith(selectedParkingSpot: event.parkingSpot));
    if (state.currentStep >= 2) {
      add(CalculatePrice());
    }
  }

  void _onUpdateParkingSpotNumber(
      UpdateParkingSpotNumber event,
      Emitter<NewReservationState> emit,
      ) {
    emit(state.copyWith(
      parkingSpotNumber: event.spotNumber,
      customLocation: null,
    ));
  }

  void _onUpdateCustomLocation(
      UpdateCustomLocation event,
      Emitter<NewReservationState> emit,
      ) {
    emit(state.copyWith(
      customLocation: event.location,
      parkingSpotNumber: null, // ✅ Réinitialiser l'autre option
    ));
  }

  void _onSelectDateTime(
      SelectDateTime event,
      Emitter<NewReservationState> emit,
      ) {
    final now = DateTime.now();
    final timeDifference = event.departureDateTime.difference(now);

    final deadline = event.departureDateTime.subtract(
      const Duration(minutes: 30),
    );

    final isUrgent = timeDifference.inMinutes < AppConfig.minReservationTimeMinutes;

    emit(state.copyWith(
      departureDateTime: event.departureDateTime,
      deadlineTime: deadline,
      isUrgent: isUrgent,
    ));

    if (state.currentStep >= 2) {
      add(CalculatePrice());
    }
  }

  void _onToggleServiceOption(
      ToggleServiceOption event,
      Emitter<NewReservationState> emit,
      ) {
    final options = List<ServiceOption>.from(state.selectedOptions);

    if (options.contains(event.option)) {
      options.remove(event.option);
    } else {
      options.add(event.option);
    }

    emit(state.copyWith(selectedOptions: options));
    add(CalculatePrice());
  }

  void _onUpdateSnowDepth(
      UpdateSnowDepth event,
      Emitter<NewReservationState> emit,
      ) {
    emit(state.copyWith(snowDepthCm: event.snowDepthCm));
    add(CalculatePrice());
  }

  void _onCalculatePrice(
      CalculatePrice event,
      Emitter<NewReservationState> emit,
      ) {
    // ✅ Vérifier qu'il y a un véhicule
    if (state.selectedVehicle == null) {
      return;
    }

    // ✅ Vérifier qu'il y a UNE place (spot complet OU numéro manuel OU emplacement perso)
    final hasParkingInfo = state.selectedParkingSpot != null ||
        (state.parkingSpotNumber != null && state.parkingSpotNumber!.trim().isNotEmpty) ||
        (state.customLocation != null && state.customLocation!.trim().isNotEmpty);

    if (!hasParkingInfo) {
      return;
    }

    double basePrice = AppConfig.basePrice;

    // ✅ Calcul du facteur véhicule
    final vehicleFactor = state.selectedVehicle!.type.priceFactor;
    final vehicleAdjustment = basePrice * (vehicleFactor - 1.0);
    double price = basePrice * vehicleFactor;

    // ✅ Calcul du facteur parking (si place complète sélectionnée, sinon facteur neutre)
    double parkingFactor = 1.0;
    double parkingAdjustment = 0;

    if (state.selectedParkingSpot != null) {
      parkingFactor = state.selectedParkingSpot!.level.priceFactor;
      parkingAdjustment = price * (parkingFactor - 1.0);
      price *= parkingFactor;
    }

    // ✅ Calcul du supplément neige
    double snowSurcharge = 0;
    if (state.snowDepthCm != null && state.snowDepthCm! > 10) {
      snowSurcharge = (state.snowDepthCm! - 10) * AppConfig.pricePerCm;
      price += snowSurcharge;
    }

    // ✅ Calcul du coût des options
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

    // ✅ Calcul des frais d'urgence
    double urgencyFee = 0;
    if (state.isUrgent) {
      urgencyFee = price * AppConfig.urgencyFeePercentage;
      price += urgencyFee;
    }

    final breakdown = PriceBreakdown(
      basePrice: basePrice,
      vehicleAdjustment: vehicleAdjustment,
      parkingAdjustment: parkingAdjustment,
      snowSurcharge: snowSurcharge,
      optionsCost: optionsCost,
      urgencyFee: urgencyFee,
      totalPrice: price,
    );

    emit(state.copyWith(
      calculatedPrice: price,
      priceBreakdown: breakdown,
    ));
  }


  Future<void> _onSubmitReservation(
      SubmitReservation event,
      Emitter<NewReservationState> emit,
      ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // ✅ Déterminer le parkingSpotId
      String parkingSpotId;
      if (state.selectedParkingSpot != null) {
        // Cas 1: Place complète sélectionnée
        parkingSpotId = state.selectedParkingSpot!.id;
      } else if (state.parkingSpotNumber != null && state.parkingSpotNumber!.trim().isNotEmpty) {
        // Cas 2: Numéro manuel → utiliser le numéro comme ID temporaire
        parkingSpotId = 'manual-${state.parkingSpotNumber!.trim()}';
      } else if (state.customLocation != null && state.customLocation!.trim().isNotEmpty) {
        // Cas 3: Emplacement personnalisé
        parkingSpotId = 'custom-${state.customLocation!.trim()}';
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Aucune place de parking sélectionnée',
        ));
        return;
      }

      final result = await createReservation(CreateReservationParams(
        vehicleId: state.selectedVehicle!.id,
        parkingSpotId: parkingSpotId,
        departureTime: state.departureDateTime!,
        deadlineTime: state.deadlineTime!,
        serviceOptions: state.selectedOptions,
        snowDepthCm: state.snowDepthCm,
        totalPrice: state.calculatedPrice!,
        paymentMethod: event.paymentMethod,
      ));

      result.fold(
            (failure) {
          emit(state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          ));
        },
            (reservation) {
          emit(state.copyWith(
            isLoading: false,
            isSubmitted: true,
            reservationId: reservation.id,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Une erreur est survenue lors de la création',
      ));
    }
  }

  void _onGoToNextStep(
      GoToNextStep event,
      Emitter<NewReservationState> emit,
      ) {
    if (state.currentStep < 3) {
      final nextStep = state.currentStep + 1;
      emit(state.copyWith(currentStep: nextStep));

      if (nextStep == 2) {
        add(CalculatePrice());
      }
    }
  }

  void _onGoToPreviousStep(
      GoToPreviousStep event,
      Emitter<NewReservationState> emit,
      ) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void _onResetReservation(
      ResetReservation event,
      Emitter<NewReservationState> emit,
      ) {
    emit(const NewReservationState());
  }
}