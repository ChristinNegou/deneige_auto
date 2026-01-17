import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo_analysis.dart';
import '../entities/price_estimation.dart';
import '../entities/smart_match.dart';
import '../entities/demand_prediction.dart';
import '../entities/dispute_analysis.dart';
import '../entities/ai_status.dart';

export '../entities/smart_match.dart';
export '../entities/demand_prediction.dart';
export '../entities/dispute_analysis.dart';
export '../entities/ai_status.dart';

abstract class AIFeaturesRepository {
  /// Estime le prix d'une reservation
  Future<Either<Failure, PriceEstimation>> estimatePrice({
    required List<String> serviceOptions,
    required int snowDepthCm,
    required int timeUntilDepartureMinutes,
    String? weatherCondition,
    Map<String, dynamic>? location,
    double? distanceKm,
  });

  /// Analyse les photos d'une reservation
  Future<Either<Failure, PhotoAnalysis>> analyzePhotos(String reservationId);

  /// Analyse rapide d'une photo unique
  Future<Either<Failure, SinglePhotoAnalysis>> analyzeSinglePhoto({
    required String photoUrl,
    String photoType = 'after',
  });

  /// Smart matching pour une reservation
  Future<Either<Failure, SmartMatchResult>> getSmartMatch(
    String reservationId, {
    int limit = 3,
  });

  /// Auto-assigne le meilleur worker
  Future<Either<Failure, Map<String, dynamic>>> autoAssignWorker(
      String reservationId);

  /// Prediction de demande pour une zone
  Future<Either<Failure, DemandPrediction>> predictDemand(String zone);

  /// Prediction de demande pour toutes les zones
  Future<Either<Failure, List<DemandPrediction>>> predictDemandAll();

  /// Recupere les previsions recentes
  Future<Either<Failure, List<DemandPrediction>>> getDemandForecasts({
    int hours = 24,
  });

  /// Analyse un litige
  Future<Either<Failure, DisputeAnalysis>> analyzeDispute(String disputeId);

  /// Liste les litiges en attente d'analyse
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingDisputes();

  /// Marque un litige comme revu
  Future<Either<Failure, Map<String, dynamic>>> markDisputeReviewed(
    String disputeId, {
    String? decision,
  });

  /// Recupere le statut des services IA
  Future<Either<Failure, AIStatus>> getAIStatus();

  /// Statistiques de matching
  Future<Either<Failure, MatchingStats>> getMatchingStats();

  /// Precision des predictions
  Future<Either<Failure, List<PredictionAccuracy>>> getPredictionAccuracy({
    int days = 7,
  });
}
