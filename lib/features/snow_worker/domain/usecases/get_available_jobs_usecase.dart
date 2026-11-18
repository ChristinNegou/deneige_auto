import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/available_jobs.dart';
import '../repositories/worker_repository.dart';

class GetAvailableJobsUseCase {
  final WorkerRepository repository;

  GetAvailableJobsUseCase(this.repository);

  Future<Either<Failure, AvailableJobs>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) {
    return repository.getAvailableJobs(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}
