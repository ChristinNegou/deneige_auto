import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/worker_profile.dart';
import '../../domain/repositories/worker_repository.dart';
import '../../domain/usecases/toggle_availability_usecase.dart';

// Events
abstract class WorkerAvailabilityEvent extends Equatable {
  const WorkerAvailabilityEvent();

  @override
  List<Object?> get props => [];
}

class LoadAvailability extends WorkerAvailabilityEvent {
  const LoadAvailability();
}

class ToggleAvailability extends WorkerAvailabilityEvent {
  const ToggleAvailability();
}

class UpdateLocation extends WorkerAvailabilityEvent {
  final double latitude;
  final double longitude;

  const UpdateLocation({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class LoadProfile extends WorkerAvailabilityEvent {
  const LoadProfile();
}

class UpdateProfile extends WorkerAvailabilityEvent {
  final List<PreferredZone>? preferredZones;
  final List<String>? equipmentList;
  final VehicleType? vehicleType;
  final int? maxActiveJobs;

  const UpdateProfile({
    this.preferredZones,
    this.equipmentList,
    this.vehicleType,
    this.maxActiveJobs,
  });

  @override
  List<Object?> get props => [preferredZones, equipmentList, vehicleType, maxActiveJobs];
}

// States
abstract class WorkerAvailabilityState extends Equatable {
  const WorkerAvailabilityState();

  @override
  List<Object?> get props => [];
}

class WorkerAvailabilityInitial extends WorkerAvailabilityState {
  const WorkerAvailabilityInitial();
}

class WorkerAvailabilityLoading extends WorkerAvailabilityState {
  const WorkerAvailabilityLoading();
}

class WorkerAvailabilityLoaded extends WorkerAvailabilityState {
  final bool isAvailable;
  final WorkerProfile? profile;
  final bool isUpdating;

  const WorkerAvailabilityLoaded({
    required this.isAvailable,
    this.profile,
    this.isUpdating = false,
  });

  WorkerAvailabilityLoaded copyWith({
    bool? isAvailable,
    WorkerProfile? profile,
    bool? isUpdating,
  }) {
    return WorkerAvailabilityLoaded(
      isAvailable: isAvailable ?? this.isAvailable,
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [isAvailable, profile, isUpdating];
}

class WorkerAvailabilityError extends WorkerAvailabilityState {
  final String message;

  const WorkerAvailabilityError(this.message);

  @override
  List<Object?> get props => [message];
}

class WorkerProfileUpdated extends WorkerAvailabilityState {
  final WorkerProfile profile;

  const WorkerProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

// BLoC
class WorkerAvailabilityBloc
    extends Bloc<WorkerAvailabilityEvent, WorkerAvailabilityState> {
  final ToggleAvailabilityUseCase toggleAvailabilityUseCase;
  final UpdateLocationUseCase updateLocationUseCase;
  final WorkerRepository repository;

  WorkerAvailabilityBloc({
    required this.toggleAvailabilityUseCase,
    required this.updateLocationUseCase,
    required this.repository,
  }) : super(const WorkerAvailabilityInitial()) {
    on<LoadAvailability>(_onLoadAvailability);
    on<ToggleAvailability>(_onToggleAvailability);
    on<UpdateLocation>(_onUpdateLocation);
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
  }

  Future<void> _onLoadAvailability(
    LoadAvailability event,
    Emitter<WorkerAvailabilityState> emit,
  ) async {
    emit(const WorkerAvailabilityLoading());

    final result = await repository.getProfile();

    result.fold(
      (failure) => emit(WorkerAvailabilityError(failure.message)),
      (profile) => emit(WorkerAvailabilityLoaded(
        isAvailable: profile.isAvailable,
        profile: profile,
      )),
    );
  }

  Future<void> _onToggleAvailability(
    ToggleAvailability event,
    Emitter<WorkerAvailabilityState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkerAvailabilityLoaded) return;

    final newAvailability = !currentState.isAvailable;

    emit(currentState.copyWith(isUpdating: true));

    final result = await toggleAvailabilityUseCase(newAvailability);

    result.fold(
      (failure) {
        emit(currentState.copyWith(isUpdating: false));
        emit(WorkerAvailabilityError(failure.message));
      },
      (isAvailable) {
        emit(currentState.copyWith(
          isAvailable: isAvailable,
          isUpdating: false,
        ));
      },
    );
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<WorkerAvailabilityState> emit,
  ) async {
    final result = await updateLocationUseCase(
      latitude: event.latitude,
      longitude: event.longitude,
    );

    result.fold(
      (failure) {
        // Silently fail for location updates
        // Could log this error
      },
      (_) {
        // Location updated successfully
      },
    );
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<WorkerAvailabilityState> emit,
  ) async {
    final currentState = state;
    if (currentState is WorkerAvailabilityLoaded) {
      emit(currentState.copyWith(isUpdating: true));
    } else {
      emit(const WorkerAvailabilityLoading());
    }

    final result = await repository.getProfile();

    result.fold(
      (failure) => emit(WorkerAvailabilityError(failure.message)),
      (profile) => emit(WorkerAvailabilityLoaded(
        isAvailable: profile.isAvailable,
        profile: profile,
      )),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<WorkerAvailabilityState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkerAvailabilityLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    final result = await repository.updateProfile(
      preferredZones: event.preferredZones,
      equipmentList: event.equipmentList,
      vehicleType: event.vehicleType,
      maxActiveJobs: event.maxActiveJobs,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isUpdating: false));
        emit(WorkerAvailabilityError(failure.message));
      },
      (profile) {
        emit(WorkerProfileUpdated(profile));
        emit(currentState.copyWith(
          profile: profile,
          isUpdating: false,
        ));
      },
    );
  }
}
