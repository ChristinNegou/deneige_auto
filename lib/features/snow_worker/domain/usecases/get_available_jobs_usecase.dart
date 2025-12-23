import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/worker_job.dart';
import '../repositories/worker_repository.dart';

class GetAvailableJobsUseCase {
  final WorkerRepository repository;

  GetAvailableJobsUseCase(this.repository);

  Future<Either<Failure, List<WorkerJob>>> call({
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
