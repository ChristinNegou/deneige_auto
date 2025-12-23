import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/worker_stats.dart';
import '../repositories/worker_repository.dart';

class GetWorkerStatsUseCase {
  final WorkerRepository repository;

  GetWorkerStatsUseCase(this.repository);

  Future<Either<Failure, WorkerStats>> call() {
    return repository.getStats();
  }
}

class GetEarningsUseCase {
  final WorkerRepository repository;

  GetEarningsUseCase(this.repository);

  Future<Either<Failure, EarningsBreakdown>> call({String period = 'week'}) {
    return repository.getEarnings(period: period);
  }
}
