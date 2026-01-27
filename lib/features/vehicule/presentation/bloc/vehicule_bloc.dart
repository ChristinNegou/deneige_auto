import 'dart:io';

import 'package:deneige_auto/features/reservation/domain/usecases/add_vehicle_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/delete_vehicle_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../reservation/domain/entities/vehicle.dart';
import '../../../reservation/domain/repositories/reservation_repository.dart';
import '../../../reservation/domain/usecases/get_vehicules_usecase.dart';

// ==================== EVENTS ====================
abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  @override
  List<Object?> get props => [];
}

class LoadVehicles extends VehicleEvent {}

class AddVehicle extends VehicleEvent {
  final AddVehicleParams params;

  const AddVehicle(this.params);

  @override
  List<Object?> get props => [params];
}

class DeleteVehicle extends VehicleEvent {
  final String vehicleId;

  const DeleteVehicle(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class UploadVehiclePhoto extends VehicleEvent {
  final String vehicleId;
  final File photo;

  const UploadVehiclePhoto({required this.vehicleId, required this.photo});

  @override
  List<Object?> get props => [vehicleId, photo];
}

// ==================== STATES ====================
class VehicleState extends Equatable {
  final List<Vehicle> vehicles;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const VehicleState({
    this.vehicles = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        vehicles,
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
      ];
}

// ==================== BLOC ====================
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final GetVehiclesUseCase getVehicles;
  final AddVehicleUseCase addVehicle;
  final DeleteVehicleUseCase deleteVehicle;
  final ReservationRepository repository;

  VehicleBloc({
    required this.getVehicles,
    required this.addVehicle,
    required this.deleteVehicle,
    required this.repository,
  }) : super(const VehicleState()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<AddVehicle>(_onAddVehicle);
    on<DeleteVehicle>(_onDeleteVehicle);
    on<UploadVehiclePhoto>(_onUploadVehiclePhoto);
  }

  Future<void> _onLoadVehicles(
    LoadVehicles event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await getVehicles();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (vehicles) => emit(state.copyWith(
        isLoading: false,
        vehicles: vehicles,
        clearError: true,
      )),
    );
  }

  Future<void> _onAddVehicle(
    AddVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await addVehicle(event.params);

    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      )),
      (vehicle) {
        final updatedVehicles = List<Vehicle>.from(state.vehicles)
          ..add(vehicle);
        emit(state.copyWith(
          isSubmitting: false,
          vehicles: updatedVehicles,
          successMessage: 'vehicle_added_flag',
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onDeleteVehicle(
    DeleteVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await deleteVehicle(event.vehicleId);

    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedVehicles =
            state.vehicles.where((v) => v.id != event.vehicleId).toList();
        emit(state.copyWith(
          isSubmitting: false,
          vehicles: updatedVehicles,
          successMessage: 'vehicle_deleted_flag',
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onUploadVehiclePhoto(
    UploadVehiclePhoto event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await repository.uploadVehiclePhoto(
      vehicleId: event.vehicleId,
      photoPath: event.photo.path,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      )),
      (photoUrl) {
        // Update the vehicle in the list with the new photo URL
        final updatedVehicles = state.vehicles.map((v) {
          if (v.id == event.vehicleId) {
            return v.copyWith(photoUrl: photoUrl);
          }
          return v;
        }).toList();

        emit(state.copyWith(
          isSubmitting: false,
          vehicles: updatedVehicles,
          successMessage: 'vehicle_photo_updated_flag',
          clearError: true,
        ));
      },
    );
  }
}
