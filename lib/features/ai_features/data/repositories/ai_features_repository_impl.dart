import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/photo_analysis.dart';
import '../../domain/entities/price_estimation.dart';
import '../../domain/repositories/ai_features_repository.dart';
import '../datasources/ai_features_remote_datasource.dart';

class AIFeaturesRepositoryImpl implements AIFeaturesRepository {
  final AIFeaturesRemoteDataSource remoteDataSource;

  AIFeaturesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PriceEstimation>> estimatePrice({
    required List<String> serviceOptions,
    required int snowDepthCm,
    required int timeUntilDepartureMinutes,
    String? weatherCondition,
    Map<String, dynamic>? location,
    double? distanceKm,
  }) async {
    try {
      final result = await remoteDataSource.estimatePrice(
        serviceOptions: serviceOptions,
        snowDepthCm: snowDepthCm,
        timeUntilDepartureMinutes: timeUntilDepartureMinutes,
        weatherCondition: weatherCondition,
        location: location,
        distanceKm: distanceKm,
      );
      return Right(PriceEstimation.fromJson(result));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PhotoAnalysis>> analyzePhotos(
      String reservationId) async {
    try {
      final result = await remoteDataSource.analyzePhotos(reservationId);
      return Right(PhotoAnalysis.fromJson(result));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SinglePhotoAnalysis>> analyzeSinglePhoto({
    required String photoUrl,
    String photoType = 'after',
  }) async {
    try {
      final result = await remoteDataSource.analyzeSinglePhoto(
        photoUrl: photoUrl,
        photoType: photoType,
      );
      return Right(SinglePhotoAnalysis.fromJson(result));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SmartMatchResult>> getSmartMatch(
    String reservationId, {
    int limit = 3,
  }) async {
    try {
      final result = await remoteDataSource.getSmartMatch(
        reservationId,
        limit: limit,
      );
      return Right(SmartMatchResult.fromJson(result));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> autoAssignWorker(
      String reservationId) async {
    try {
      final result = await remoteDataSource.autoAssignWorker(reservationId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DemandPrediction>> predictDemand(String zone) async {
    try {
      final result = await remoteDataSource.predictDemand(zone);
      return Right(DemandPrediction.fromJson(result));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DemandPrediction>>> predictDemandAll() async {
    try {
      final result = await remoteDataSource.predictDemandAll();
      final predictions = (result['predictions'] as List<dynamic>?)
              ?.map((e) => DemandPrediction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return Right(predictions);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DemandPrediction>>> getDemandForecasts({
    int hours = 24,
  }) async {
    try {
      final result = await remoteDataSource.getDemandForecasts(hours: hours);
      final forecasts = result
          .map((e) => DemandPrediction.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(forecasts);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DisputeAnalysis>> analyzeDispute(
      String disputeId) async {
    try {
      final result = await remoteDataSource.analyzeDispute(disputeId);
      return Right(DisputeAnalysis.fromJson(result));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getPendingDisputes() async {
    try {
      final result = await remoteDataSource.getPendingDisputes();
      return Right(result.cast<Map<String, dynamic>>());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> markDisputeReviewed(
    String disputeId, {
    String? decision,
  }) async {
    try {
      final result = await remoteDataSource.markDisputeReviewed(
        disputeId,
        decision: decision,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AIStatus>> getAIStatus() async {
    try {
      final result = await remoteDataSource.getAIStatus();
      return Right(AIStatus.fromJson(result));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchingStats>> getMatchingStats() async {
    try {
      final result = await remoteDataSource.getMatchingStats();
      return Right(MatchingStats.fromJson(result));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PredictionAccuracy>>> getPredictionAccuracy({
    int days = 7,
  }) async {
    try {
      final result = await remoteDataSource.getPredictionAccuracy(days: days);
      final accuracy = result
          .map((e) => PredictionAccuracy.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(accuracy);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
