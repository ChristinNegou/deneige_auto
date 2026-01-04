import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/worker_job.dart';
import '../../domain/entities/worker_profile.dart';
import '../../domain/entities/worker_stats.dart';
import '../../domain/repositories/worker_repository.dart';
import '../datasources/worker_remote_datasource.dart';
import '../models/worker_profile_model.dart';

export '../datasources/worker_remote_datasource.dart'
    show
        WorkerCancellationResult,
        WorkerCancellationConsequence,
        WorkerCancellationStats,
        WorkerCancellationReasons,
        WorkerCancellationReason,
        WorkerCancellationPolicyInfo;

class WorkerRepositoryImpl implements WorkerRepository {
  final WorkerRemoteDataSource remoteDataSource;

  WorkerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<WorkerJob>>> getAvailableJobs({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      final jobs = await remoteDataSource.getAvailableJobs(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return Right(jobs);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkerJob>>> getMyJobs() async {
    try {
      final jobs = await remoteDataSource.getMyJobs();
      return Right(jobs);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkerJob>>> getJobHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final jobs = await remoteDataSource.getJobHistory(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(jobs);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerStats>> getStats() async {
    try {
      final stats = await remoteDataSource.getStats();
      return Right(stats);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, EarningsBreakdown>> getEarnings({
    String period = 'week',
  }) async {
    try {
      final earnings = await remoteDataSource.getEarnings(period: period);
      return Right(earnings);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerProfile>> getProfile() async {
    try {
      final profile = await remoteDataSource.getProfile();
      return Right(profile);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerProfile>> updateProfile({
    List<PreferredZone>? preferredZones,
    List<String>? equipmentList,
    VehicleType? vehicleType,
    int? maxActiveJobs,
  }) async {
    try {
      final zonesModels = preferredZones
          ?.map((z) => PreferredZoneModel(
                name: z.name,
                centerLat: z.centerLat,
                centerLng: z.centerLng,
                radiusKm: z.radiusKm,
              ))
          .toList();

      final profile = await remoteDataSource.updateProfile(
        preferredZones: zonesModels,
        equipmentList: equipmentList,
        vehicleType: vehicleType?.name,
        maxActiveJobs: maxActiveJobs,
      );
      return Right(profile);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleAvailability(bool isAvailable) async {
    try {
      final result = await remoteDataSource.toggleAvailability(isAvailable);
      return Right(result);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await remoteDataSource.updateLocation(
        latitude: latitude,
        longitude: longitude,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerJob>> acceptJob(String jobId) async {
    try {
      final job = await remoteDataSource.acceptJob(jobId);
      return Right(job);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerJob>> markEnRoute({
    required String jobId,
    double? latitude,
    double? longitude,
    int? estimatedMinutes,
  }) async {
    try {
      final job = await remoteDataSource.markEnRoute(
        jobId: jobId,
        latitude: latitude,
        longitude: longitude,
        estimatedMinutes: estimatedMinutes,
      );
      return Right(job);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerJob>> startJob(String jobId) async {
    try {
      final job = await remoteDataSource.startJob(jobId);
      return Right(job);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerJob>> completeJob({
    required String jobId,
    String? workerNotes,
  }) async {
    try {
      final job = await remoteDataSource.completeJob(
        jobId: jobId,
        workerNotes: workerNotes,
      );
      return Right(job);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPhoto({
    required String jobId,
    required String type,
    required File photo,
  }) async {
    try {
      final photoUrl = await remoteDataSource.uploadJobPhoto(
        jobId: jobId,
        type: type,
        photoFile: photo,
      );
      return Right(photoUrl);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPhotoToJob({
    required String jobId,
    required String type,
    required String photoUrl,
  }) async {
    try {
      await remoteDataSource.addPhotoToJob(
        jobId: jobId,
        type: type,
        photoUrl: photoUrl,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerCancellationResult>> cancelJob({
    required String jobId,
    required String reasonCode,
    String? reason,
    String? description,
  }) async {
    try {
      final result = await remoteDataSource.cancelJob(
        jobId: jobId,
        reasonCode: reasonCode,
        reason: reason,
        description: description,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkerCancellationReasons>>
      getCancellationReasons() async {
    try {
      final reasons = await remoteDataSource.getCancellationReasons();
      return Right(reasons);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure(message: 'Délai de connexion dépassé');
    }

    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(message: 'Erreur de connexion réseau');
    }

    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final errorMessage =
          e.response?.data?['message'] as String? ?? 'Erreur serveur';

      if (statusCode == 401) {
        return UnauthorizedFailure(message: errorMessage);
      }
      if (statusCode == 403) {
        return const AuthFailure(message: 'Accès non autorisé');
      }
      if (statusCode == 404) {
        return const ServerFailure(message: 'Ressource non trouvée');
      }
      if (statusCode == 400) {
        return ValidationFailure(message: errorMessage);
      }

      return ServerFailure(message: errorMessage);
    }

    return const ServerFailure(message: 'Une erreur est survenue');
  }
}
