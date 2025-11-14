
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../reservation/domain/entities/vehicle.dart';
import '../../../reservation/domain/usecases/get_vehicules_usecase.dart';

// ==================== EVENTS ====================
abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  @override
  List<Object?> get props => [];
}

class LoadVehicles extends VehicleEvent {}

class AddVehicle extends VehicleEvent {
  final Vehicle vehicle;

  const AddVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class DeleteVehicle extends VehicleEvent {
  final String vehicleId;

  const DeleteVehicle(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

// ==================== STATES ====================
class VehicleState extends Equatable {
  final List<Vehicle> vehicles;
  final bool isLoading;
  final String? errorMessage;

  const VehicleState({
    this.vehicles = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [vehicles, isLoading, errorMessage];
}

// ==================== BLOC ====================
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final GetVehiclesUseCase getVehicles;

  VehicleBloc({
    required this.getVehicles,
  }) : super(const VehicleState()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<AddVehicle>(_onAddVehicle);
    on<DeleteVehicle>(_onDeleteVehicle);
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
    final updatedVehicles = List<Vehicle>.from(state.vehicles)..add(event.vehicle);
    emit(state.copyWith(vehicles: updatedVehicles));
  }

  Future<void> _onDeleteVehicle(
      DeleteVehicle event,
      Emitter<VehicleState> emit,
      ) async {
    final updatedVehicles = state.vehicles
        .where((v) => v.id != event.vehicleId)
        .toList();
    emit(state.copyWith(vehicles: updatedVehicles));
  }
}