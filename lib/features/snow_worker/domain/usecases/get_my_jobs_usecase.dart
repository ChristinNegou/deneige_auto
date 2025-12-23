import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/worker_job.dart';
import '../repositories/worker_repository.dart';

class GetMyJobsUseCase {
  final WorkerRepository repository;

  GetMyJobsUseCase(this.repository);

  Future<Either<Failure, List<WorkerJob>>> call() {
    return repository.getMyJobs();
  }
}
