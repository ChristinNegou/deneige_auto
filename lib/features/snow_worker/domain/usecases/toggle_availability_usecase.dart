import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/worker_repository.dart';

class ToggleAvailabilityUseCase {
  final WorkerRepository repository;

  ToggleAvailabilityUseCase(this.repository);

  Future<Either<Failure, bool>> call(bool isAvailable) {
    return repository.toggleAvailability(isAvailable);
  }
}

class UpdateLocationUseCase {
  final WorkerRepository repository;

  UpdateLocationUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required double latitude,
    required double longitude,
  }) {
    return repository.updateLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
