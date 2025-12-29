import 'dart:io';

import 'package:dio/dio.dart';

import '../models/worker_job_model.dart';
import '../models/worker_profile_model.dart';
import '../models/worker_stats_model.dart';

abstract class WorkerRemoteDataSource {
  Future<List<WorkerJobModel>> getAvailableJobs({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  Future<List<WorkerJobModel>> getMyJobs();

  Future<List<WorkerJobModel>> getJobHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<WorkerStatsModel> getStats();

  Future<EarningsBreakdownModel> getEarnings({String period = 'week'});

  Future<WorkerProfileModel> getProfile();

  Future<WorkerProfileModel> updateProfile({
    List<PreferredZoneModel>? preferredZones,
    List<String>? equipmentList,
    String? vehicleType,
    int? maxActiveJobs,
  });

  Future<bool> toggleAvailability(bool isAvailable);

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  });

  Future<WorkerJobModel> acceptJob(String jobId);

  Future<WorkerJobModel> markEnRoute({
    required String jobId,
    double? latitude,
    double? longitude,
    int? estimatedMinutes,
  });

  Future<WorkerJobModel> startJob(String jobId);

  Future<WorkerJobModel> completeJob({
    required String jobId,
    String? workerNotes,
  });

  Future<void> addPhotoToJob({
    required String jobId,
    required String type,
    required String photoUrl,
  });

  Future<String> uploadJobPhoto({
    required String jobId,
    required String type,
    required File photoFile,
  });

  /// Annuler un job avec une raison valable
  Future<WorkerCancellationResult> cancelJob({
    required String jobId,
    required String reasonCode,
    String? reason,
    String? description,
  });

  /// Obtenir les raisons valables d'annulation
  Future<WorkerCancellationReasons> getCancellationReasons();
}

/// Résultat d'annulation pour le déneigeur
class WorkerCancellationResult {
  final bool success;
  final String message;
  final String jobId;
  final WorkerCancellationConsequence? consequence;
  final WorkerCancellationStats stats;

  WorkerCancellationResult({
    required this.success,
    required this.message,
    required this.jobId,
    this.consequence,
    required this.stats,
  });

  factory WorkerCancellationResult.fromJson(Map<String, dynamic> json) {
    final reservation = json['reservation'] as Map<String, dynamic>? ?? {};
    final consequenceData = json['consequence'] as Map<String, dynamic>?;
    final statsData = json['stats'] as Map<String, dynamic>? ?? {};

    return WorkerCancellationResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      jobId: reservation['id'] as String? ?? '',
      consequence: consequenceData != null
          ? WorkerCancellationConsequence.fromJson(consequenceData)
          : null,
      stats: WorkerCancellationStats.fromJson(statsData),
    );
  }
}

class WorkerCancellationConsequence {
  final String type; // 'warning' ou 'suspension'
  final String message;
  final DateTime? suspendedUntil;
  final int? warningCount;

  WorkerCancellationConsequence({
    required this.type,
    required this.message,
    this.suspendedUntil,
    this.warningCount,
  });

  factory WorkerCancellationConsequence.fromJson(Map<String, dynamic> json) {
    return WorkerCancellationConsequence(
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      suspendedUntil: json['suspendedUntil'] != null
          ? DateTime.parse(json['suspendedUntil'] as String)
          : null,
      warningCount: json['warningCount'] as int?,
    );
  }
}

class WorkerCancellationStats {
  final int totalCancellations;
  final int warningCount;
  final bool isSuspended;

  WorkerCancellationStats({
    required this.totalCancellations,
    required this.warningCount,
    required this.isSuspended,
  });

  factory WorkerCancellationStats.fromJson(Map<String, dynamic> json) {
    return WorkerCancellationStats(
      totalCancellations: json['totalCancellations'] as int? ?? 0,
      warningCount: json['warningCount'] as int? ?? 0,
      isSuspended: json['isSuspended'] as bool? ?? false,
    );
  }
}

/// Raisons valables d'annulation pour le déneigeur
class WorkerCancellationReasons {
  final Map<String, WorkerCancellationReason> reasons;
  final WorkerCancellationPolicyInfo policy;

  WorkerCancellationReasons({
    required this.reasons,
    required this.policy,
  });

  factory WorkerCancellationReasons.fromJson(Map<String, dynamic> json) {
    final reasonsData = json['reasons'] as Map<String, dynamic>? ?? {};
    final policyData = json['policy'] as Map<String, dynamic>? ?? {};

    final reasons = <String, WorkerCancellationReason>{};
    reasonsData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        reasons[key] = WorkerCancellationReason.fromJson(value);
      }
    });

    return WorkerCancellationReasons(
      reasons: reasons,
      policy: WorkerCancellationPolicyInfo.fromJson(policyData),
    );
  }
}

class WorkerCancellationReason {
  final String code;
  final String label;
  final String description;
  final bool requiresDescription;

  WorkerCancellationReason({
    required this.code,
    required this.label,
    required this.description,
    this.requiresDescription = false,
  });

  factory WorkerCancellationReason.fromJson(Map<String, dynamic> json) {
    return WorkerCancellationReason(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requiresDescription: json['requiresDescription'] as bool? ?? false,
    );
  }
}

class WorkerCancellationPolicyInfo {
  final int warningThreshold;
  final int suspensionThreshold;
  final int suspensionDays;
  final String note;

  WorkerCancellationPolicyInfo({
    required this.warningThreshold,
    required this.suspensionThreshold,
    required this.suspensionDays,
    required this.note,
  });

  factory WorkerCancellationPolicyInfo.fromJson(Map<String, dynamic> json) {
    return WorkerCancellationPolicyInfo(
      warningThreshold: json['warningThreshold'] as int? ?? 2,
      suspensionThreshold: json['suspensionThreshold'] as int? ?? 5,
      suspensionDays: json['suspensionDays'] as int? ?? 7,
      note: json['note'] as String? ?? '',
    );
  }
}

class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  final Dio dio;

  WorkerRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<WorkerJobModel>> getAvailableJobs({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final response = await dio.get(
      '/workers/available-jobs',
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'radiusKm': radiusKm,
      },
    );

    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((job) => WorkerJobModel.fromJson(job as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WorkerJobModel>> getMyJobs() async {
    final response = await dio.get('/workers/my-jobs');

    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((job) => WorkerJobModel.fromJson(job as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WorkerJobModel>> getJobHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await dio.get(
      '/workers/history',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((job) => WorkerJobModel.fromJson(job as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WorkerStatsModel> getStats() async {
    final response = await dio.get('/workers/stats');
    return WorkerStatsModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<EarningsBreakdownModel> getEarnings({String period = 'week'}) async {
    final response = await dio.get(
      '/workers/earnings',
      queryParameters: {'period': period},
    );

    return EarningsBreakdownModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<WorkerProfileModel> getProfile() async {
    final response = await dio.get('/workers/profile');
    return WorkerProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<WorkerProfileModel> updateProfile({
    List<PreferredZoneModel>? preferredZones,
    List<String>? equipmentList,
    String? vehicleType,
    int? maxActiveJobs,
  }) async {
    final body = <String, dynamic>{};

    if (preferredZones != null) {
      body['preferredZones'] = preferredZones.map((z) => z.toJson()).toList();
    }
    if (equipmentList != null) {
      body['equipmentList'] = equipmentList;
    }
    if (vehicleType != null) {
      body['vehicleType'] = vehicleType;
    }
    if (maxActiveJobs != null) {
      body['maxActiveJobs'] = maxActiveJobs;
    }

    final response = await dio.put('/workers/profile', data: body);
    return WorkerProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<bool> toggleAvailability(bool isAvailable) async {
    final response = await dio.patch(
      '/workers/availability',
      data: {'isAvailable': isAvailable},
    );
    return response.data['isAvailable'] as bool? ?? isAvailable;
  }

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    await dio.put(
      '/workers/location',
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  @override
  Future<WorkerJobModel> acceptJob(String jobId) async {
    final response = await dio.post('/workers/jobs/$jobId/accept');
    return WorkerJobModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<WorkerJobModel> markEnRoute({
    required String jobId,
    double? latitude,
    double? longitude,
    int? estimatedMinutes,
  }) async {
    final body = <String, dynamic>{};

    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (estimatedMinutes != null) body['estimatedMinutes'] = estimatedMinutes;

    final response = await dio.patch(
      '/workers/jobs/$jobId/en-route',
      data: body,
    );
    return WorkerJobModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<WorkerJobModel> startJob(String jobId) async {
    final response = await dio.patch('/workers/jobs/$jobId/start');
    return WorkerJobModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<WorkerJobModel> completeJob({
    required String jobId,
    String? workerNotes,
  }) async {
    final body = <String, dynamic>{};
    if (workerNotes != null) body['workerNotes'] = workerNotes;

    final response = await dio.patch(
      '/workers/jobs/$jobId/complete',
      data: body,
    );
    return WorkerJobModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> addPhotoToJob({
    required String jobId,
    required String type,
    required String photoUrl,
  }) async {
    await dio.post(
      '/workers/jobs/$jobId/photos',
      data: {
        'type': type,
        'photoUrl': photoUrl,
      },
    );
  }

  @override
  Future<String> uploadJobPhoto({
    required String jobId,
    required String type,
    required File photoFile,
  }) async {
    final fileName = photoFile.path.split('/').last;
    final formData = FormData.fromMap({
      'type': type,
      'photo': await MultipartFile.fromFile(
        photoFile.path,
        filename: fileName,
      ),
    });

    final response = await dio.post(
      '/workers/jobs/$jobId/photos/upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return response.data['data']['url'] as String;
  }

  @override
  Future<WorkerCancellationResult> cancelJob({
    required String jobId,
    required String reasonCode,
    String? reason,
    String? description,
  }) async {
    final response = await dio.patch(
      '/reservations/$jobId/cancel-by-worker',
      data: {
        'reasonCode': reasonCode,
        if (reason != null) 'reason': reason,
        if (description != null) 'description': description,
      },
    );

    return WorkerCancellationResult.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<WorkerCancellationReasons> getCancellationReasons() async {
    final response = await dio.get('/reservations/worker/cancellation-reasons');

    return WorkerCancellationReasons.fromJson(
        response.data as Map<String, dynamic>);
  }
}
