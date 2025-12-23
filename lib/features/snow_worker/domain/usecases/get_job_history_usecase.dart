import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/worker_job.dart';
import '../repositories/worker_repository.dart';

class GetJobHistoryUseCase {
  final WorkerRepository repository;

  GetJobHistoryUseCase(this.repository);

  Future<Either<Failure, List<WorkerJob>>> call({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await repository.getJobHistory(
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
