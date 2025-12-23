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
}
