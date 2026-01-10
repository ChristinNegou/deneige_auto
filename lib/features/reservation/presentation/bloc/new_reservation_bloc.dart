import 'package:deneige_auto/features/reservation/domain/entities/parking_spot.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/tax_service.dart';
import '../../domain/usecases/create_reservation_usecase.dart';
import '../../domain/usecases/get_parking_spots_usecase.dart';
import '../../domain/usecases/get_vehicules_usecase.dart';
import 'new_reservation_event.dart';
import 'new_reservation_state.dart';

class NewReservationBloc
    extends Bloc<NewReservationEvent, NewReservationState> {
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
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<SetLocationFromAddress>(_onSetLocationFromAddress);
    on<ClearLocationError>(_onClearLocationError);
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<NewReservationState> emit,
  ) async {
    emit(state.copyWith(
      isGettingLocation: true,
      locationError: null,
      needsManualAddress: false,
    ));

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(state.copyWith(
            isGettingLocation: false,
            needsManualAddress: true,
            locationError:
                'Permission de localisation refusée. Veuillez entrer votre adresse.',
          ));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          isGettingLocation: false,
          needsManualAddress: true,
          locationError:
              'Permission refusée définitivement. Veuillez entrer votre adresse.',
        ));
        return;
      }

      // Obtenir la position
      var position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // DEBUG: Détecter si on est sur l'émulateur (coordonnées de Mountain View, California)
      // et utiliser Trois-Rivières à la place
      double latitude = position.latitude;
      double longitude = position.longitude;

      final isEmulatorLocation =
          (position.latitude - 37.4219983).abs() < 0.01 &&
              (position.longitude - (-122.084)).abs() < 0.01;

      if (isEmulatorLocation) {
        // Utiliser les coordonnées de Trois-Rivières pour les tests
        latitude = 46.3432;
        longitude = -72.5476;
      }

      // Reverse geocoding pour obtenir l'adresse
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = '${p.street ?? ''}, ${p.locality ?? ''}, ${p.country ?? ''}'
              .trim();
          if (address.startsWith(',')) address = address.substring(1).trim();
        }
      } catch (_) {
        // Ignorer les erreurs de reverse geocoding
        if (isEmulatorLocation) {
          address = 'Trois-Rivières, QC, Canada';
        }
      }

      emit(state.copyWith(
        isGettingLocation: false,
        locationLatitude: latitude,
        locationLongitude: longitude,
        locationAddress:
            address ?? state.customLocation ?? state.parkingSpotNumber,
        needsManualAddress: false,
        locationError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isGettingLocation: false,
        needsManualAddress: true,
        locationError:
            'Impossible d\'obtenir votre position. Veuillez entrer votre adresse.',
      ));
    }
  }

  Future<void> _onSetLocationFromAddress(
    SetLocationFromAddress event,
    Emitter<NewReservationState> emit,
  ) async {
    if (event.address.trim().isEmpty) {
      emit(state.copyWith(locationError: 'Veuillez entrer une adresse valide'));
      return;
    }

    emit(state.copyWith(
      isGettingLocation: true,
      locationError: null,
    ));

    try {
      // Geocoding: convertir l'adresse en coordonnées
      final locations = await locationFromAddress(event.address);

      if (locations.isEmpty) {
        emit(state.copyWith(
          isGettingLocation: false,
          locationError:
              'Adresse non trouvée. Veuillez réessayer avec une adresse plus précise.',
        ));
        return;
      }

      final location = locations.first;
      emit(state.copyWith(
        isGettingLocation: false,
        locationLatitude: location.latitude,
        locationLongitude: location.longitude,
        locationAddress: event.address,
        needsManualAddress: false,
        locationError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isGettingLocation: false,
        locationError:
            'Erreur lors de la recherche de l\'adresse. Veuillez réessayer.',
      ));
    }
  }

  void _onClearLocationError(
    ClearLocationError event,
    Emitter<NewReservationState> emit,
  ) {
    emit(state.copyWith(locationError: null));
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

    final isUrgent =
        timeDifference.inMinutes < AppConfig.minReservationTimeMinutes;

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
        (state.parkingSpotNumber != null &&
            state.parkingSpotNumber!.trim().isNotEmpty) ||
        (state.customLocation != null &&
            state.customLocation!.trim().isNotEmpty);

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

    // ✅ Sous-total avant taxes et frais
    final subtotal = price;

    // ✅ Frais de service et assurance
    const serviceFee = AppConfig.serviceFee;
    const insuranceFee = AppConfig.insuranceFee;
    price += serviceFee + insuranceFee;

    // ✅ Détecter la province à partir de l'adresse
    final taxService = TaxService();
    final provinceCode =
        taxService.detectProvinceFromAddress(state.locationAddress);

    // ✅ Calcul des taxes selon la province
    final taxCalc = taxService.calculateTaxes(price, provinceCode);

    final breakdown = PriceBreakdown(
      basePrice: basePrice,
      vehicleAdjustment: vehicleAdjustment,
      parkingAdjustment: parkingAdjustment,
      snowSurcharge: snowSurcharge,
      optionsCost: optionsCost,
      urgencyFee: urgencyFee,
      subtotal: subtotal,
      serviceFee: serviceFee,
      insuranceFee: insuranceFee,
      federalTax: taxCalc.federalTax,
      federalTaxRate: taxCalc.federalTaxRate,
      federalTaxName: taxCalc.federalTaxName,
      provincialTax: taxCalc.provincialTax,
      provincialTaxRate: taxCalc.provincialTaxRate,
      provincialTaxName: taxCalc.provincialTaxName,
      provinceCode: taxCalc.provinceCode,
      provinceName: taxCalc.provinceName,
      isHST: taxCalc.isHST,
      totalPrice: taxCalc.total,
    );

    emit(state.copyWith(
      calculatedPrice: taxCalc.total,
      priceBreakdown: breakdown,
    ));
  }

  Future<void> _onSubmitReservation(
    SubmitReservation event,
    Emitter<NewReservationState> emit,
  ) async {
    // Si paymentIntentId est fourni, le paiement a déjà été fait
    // On doit créer la réservation même si canSubmit retourne false
    final hasPayment = event.paymentIntentId != null;

    if (!hasPayment && !state.canSubmit) {
      print('❌ [NewReservationBloc] canSubmit=false, pas de paiement');
      return;
    }

    print('📝 [NewReservationBloc] Création réservation - paymentIntentId: ${event.paymentIntentId}');

    // Vérifier que la localisation est disponible
    if (!state.hasValidLocation) {
      emit(state.copyWith(
        errorMessage:
            'La localisation est requise. Veuillez activer le GPS ou entrer une adresse.',
        needsManualAddress: true,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // ✅ Déterminer le parkingSpotId
      String parkingSpotId;
      if (state.selectedParkingSpot != null) {
        // Cas 1: Place complète sélectionnée
        parkingSpotId = state.selectedParkingSpot!.id;
      } else if (state.parkingSpotNumber != null &&
          state.parkingSpotNumber!.trim().isNotEmpty) {
        // Cas 2: Numéro manuel → utiliser le numéro comme ID temporaire
        parkingSpotId = 'manual-${state.parkingSpotNumber!.trim()}';
      } else if (state.customLocation != null &&
          state.customLocation!.trim().isNotEmpty) {
        // Cas 3: Emplacement personnalisé
        parkingSpotId = 'custom-${state.customLocation!.trim()}';
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Aucune place de parking sélectionnée',
        ));
        return;
      }

      // Utiliser la localisation stockée dans le state
      final result = await createReservation(CreateReservationParams(
        vehicleId: state.selectedVehicle!.id,
        parkingSpotId: parkingSpotId,
        departureTime: state.departureDateTime!,
        deadlineTime: state.deadlineTime!,
        serviceOptions: state.selectedOptions,
        snowDepthCm: state.snowDepthCm,
        totalPrice: state.calculatedPrice!,
        paymentMethod: event.paymentMethod,
        paymentIntentId: event.paymentIntentId,
        latitude: state.locationLatitude,
        longitude: state.locationLongitude,
        address: state.locationAddress ??
            state.customLocation ??
            state.parkingSpotNumber,
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
    // 5 steps: 0=Vehicle/Parking, 1=Location, 2=DateTime, 3=Options, 4=Summary
    if (state.currentStep < 4) {
      final nextStep = state.currentStep + 1;
      emit(state.copyWith(currentStep: nextStep));

      // Calculer le prix quand on arrive au step 3 (options)
      if (nextStep == 3) {
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
