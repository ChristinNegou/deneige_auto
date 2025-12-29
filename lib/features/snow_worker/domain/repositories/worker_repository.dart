import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/worker_job.dart';
import '../entities/worker_profile.dart';
import '../entities/worker_stats.dart';
import '../../data/datasources/worker_remote_datasource.dart'
    show WorkerCancellationResult, WorkerCancellationReasons;

abstract class WorkerRepository {
  /// Get available jobs near worker's location
  Future<Either<Failure, List<WorkerJob>>> getAvailableJobs({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  /// Get worker's assigned and in-progress jobs
  Future<Either<Failure, List<WorkerJob>>> getMyJobs();

  /// Get worker's job history (completed/cancelled)
  Future<Either<Failure, List<WorkerJob>>> getJobHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get worker statistics (today, week, month, all-time)
  Future<Either<Failure, WorkerStats>> getStats();

  /// Get detailed earnings breakdown
  Future<Either<Failure, EarningsBreakdown>> getEarnings({
    String period = 'week',
  });

  /// Get worker profile
  Future<Either<Failure, WorkerProfile>> getProfile();

  /// Update worker profile (zones, equipment, settings)
  Future<Either<Failure, WorkerProfile>> updateProfile({
    List<PreferredZone>? preferredZones,
    List<String>? equipmentList,
    VehicleType? vehicleType,
    int? maxActiveJobs,
  });

  /// Toggle worker availability
  Future<Either<Failure, bool>> toggleAvailability(bool isAvailable);

  /// Update worker's current location
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
  });

  /// Accept a job
  Future<Either<Failure, WorkerJob>> acceptJob(String jobId);

  /// Mark worker as en route to job
  Future<Either<Failure, WorkerJob>> markEnRoute({
    required String jobId,
    double? latitude,
    double? longitude,
    int? estimatedMinutes,
  });

  /// Start working on a job
  Future<Either<Failure, WorkerJob>> startJob(String jobId);

  /// Complete a job
  Future<Either<Failure, WorkerJob>> completeJob({
    required String jobId,
    String? workerNotes,
  });

  /// Upload before/after photo
  Future<Either<Failure, String>> uploadPhoto({
    required String jobId,
    required String type, // 'before' or 'after'
    required File photo,
  });

  /// Add photo URL to job (after uploading to storage)
  Future<Either<Failure, void>> addPhotoToJob({
    required String jobId,
    required String type,
    required String photoUrl,
  });

  /// Cancel a job with a valid reason
  Future<Either<Failure, WorkerCancellationResult>> cancelJob({
    required String jobId,
    required String reasonCode,
    String? reason,
    String? description,
  });

  /// Get valid cancellation reasons for workers
  Future<Either<Failure, WorkerCancellationReasons>> getCancellationReasons();
}
