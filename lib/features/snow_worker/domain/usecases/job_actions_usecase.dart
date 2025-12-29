import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/worker_job.dart';
import '../repositories/worker_repository.dart';
import '../../data/datasources/worker_remote_datasource.dart'
    show WorkerCancellationResult, WorkerCancellationReasons;

class AcceptJobUseCase {
  final WorkerRepository repository;

  AcceptJobUseCase(this.repository);

  Future<Either<Failure, WorkerJob>> call(String jobId) {
    return repository.acceptJob(jobId);
  }
}

class MarkEnRouteUseCase {
  final WorkerRepository repository;

  MarkEnRouteUseCase(this.repository);

  Future<Either<Failure, WorkerJob>> call({
    required String jobId,
    double? latitude,
    double? longitude,
    int? estimatedMinutes,
  }) {
    return repository.markEnRoute(
      jobId: jobId,
      latitude: latitude,
      longitude: longitude,
      estimatedMinutes: estimatedMinutes,
    );
  }
}

class StartJobUseCase {
  final WorkerRepository repository;

  StartJobUseCase(this.repository);

  Future<Either<Failure, WorkerJob>> call(String jobId) {
    return repository.startJob(jobId);
  }
}

class CompleteJobUseCase {
  final WorkerRepository repository;

  CompleteJobUseCase(this.repository);

  Future<Either<Failure, WorkerJob>> call({
    required String jobId,
    String? workerNotes,
  }) {
    return repository.completeJob(
      jobId: jobId,
      workerNotes: workerNotes,
    );
  }
}

class UploadJobPhotoUseCase {
  final WorkerRepository repository;

  UploadJobPhotoUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String jobId,
    required String type,
    required File photo,
  }) {
    return repository.uploadPhoto(
      jobId: jobId,
      type: type,
      photo: photo,
    );
  }
}

class CancelJobUseCase {
  final WorkerRepository repository;

  CancelJobUseCase(this.repository);

  Future<Either<Failure, WorkerCancellationResult>> call({
    required String jobId,
    required String reasonCode,
    String? reason,
    String? description,
  }) {
    return repository.cancelJob(
      jobId: jobId,
      reasonCode: reasonCode,
      reason: reason,
      description: description,
    );
  }
}

class GetCancellationReasonsUseCase {
  final WorkerRepository repository;

  GetCancellationReasonsUseCase(this.repository);

  Future<Either<Failure, WorkerCancellationReasons>> call() {
    return repository.getCancellationReasons();
  }
}
