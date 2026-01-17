import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_status.dart';
import '../../domain/entities/demand_prediction.dart';
import '../../domain/entities/dispute_analysis.dart';
import '../../domain/entities/photo_analysis.dart';
import '../../domain/entities/price_estimation.dart';
import '../../domain/entities/smart_match.dart';

class AIFeaturesState extends Equatable {
  // Loading states
  final bool isEstimatingPrice;
  final bool isAnalyzingPhotos;
  final bool isAnalyzingSinglePhoto;
  final bool isGettingSmartMatch;
  final bool isAutoAssigning;
  final bool isPredictingDemand;
  final bool isAnalyzingDispute;
  final bool isLoadingStatus;
  final bool isLoadingStats;

  // Data
  final PriceEstimation? priceEstimation;
  final PhotoAnalysis? photoAnalysis;
  final SinglePhotoAnalysis? singlePhotoAnalysis;
  final SmartMatchResult? smartMatch;
  final Map<String, dynamic>? autoAssignResult;
  final DemandPrediction? demandPrediction;
  final List<DemandPrediction>? demandPredictions;
  final List<DemandPrediction>? demandForecasts;
  final DisputeAnalysis? disputeAnalysis;
  final List<Map<String, dynamic>>? pendingDisputes;
  final AIStatus? aiStatus;
  final MatchingStats? matchingStats;
  final List<PredictionAccuracy>? predictionAccuracy;

  // Errors
  final String? errorMessage;
  final String? priceEstimationError;
  final String? photoAnalysisError;
  final String? smartMatchError;
  final String? demandPredictionError;
  final String? disputeAnalysisError;

  const AIFeaturesState({
    this.isEstimatingPrice = false,
    this.isAnalyzingPhotos = false,
    this.isAnalyzingSinglePhoto = false,
    this.isGettingSmartMatch = false,
    this.isAutoAssigning = false,
    this.isPredictingDemand = false,
    this.isAnalyzingDispute = false,
    this.isLoadingStatus = false,
    this.isLoadingStats = false,
    this.priceEstimation,
    this.photoAnalysis,
    this.singlePhotoAnalysis,
    this.smartMatch,
    this.autoAssignResult,
    this.demandPrediction,
    this.demandPredictions,
    this.demandForecasts,
    this.disputeAnalysis,
    this.pendingDisputes,
    this.aiStatus,
    this.matchingStats,
    this.predictionAccuracy,
    this.errorMessage,
    this.priceEstimationError,
    this.photoAnalysisError,
    this.smartMatchError,
    this.demandPredictionError,
    this.disputeAnalysisError,
  });

  AIFeaturesState copyWith({
    bool? isEstimatingPrice,
    bool? isAnalyzingPhotos,
    bool? isAnalyzingSinglePhoto,
    bool? isGettingSmartMatch,
    bool? isAutoAssigning,
    bool? isPredictingDemand,
    bool? isAnalyzingDispute,
    bool? isLoadingStatus,
    bool? isLoadingStats,
    PriceEstimation? priceEstimation,
    PhotoAnalysis? photoAnalysis,
    SinglePhotoAnalysis? singlePhotoAnalysis,
    SmartMatchResult? smartMatch,
    Map<String, dynamic>? autoAssignResult,
    DemandPrediction? demandPrediction,
    List<DemandPrediction>? demandPredictions,
    List<DemandPrediction>? demandForecasts,
    DisputeAnalysis? disputeAnalysis,
    List<Map<String, dynamic>>? pendingDisputes,
    AIStatus? aiStatus,
    MatchingStats? matchingStats,
    List<PredictionAccuracy>? predictionAccuracy,
    String? errorMessage,
    String? priceEstimationError,
    String? photoAnalysisError,
    String? smartMatchError,
    String? demandPredictionError,
    String? disputeAnalysisError,
    bool clearPriceEstimationError = false,
    bool clearPhotoAnalysisError = false,
    bool clearSmartMatchError = false,
    bool clearDemandPredictionError = false,
    bool clearDisputeAnalysisError = false,
    bool clearErrorMessage = false,
  }) {
    return AIFeaturesState(
      isEstimatingPrice: isEstimatingPrice ?? this.isEstimatingPrice,
      isAnalyzingPhotos: isAnalyzingPhotos ?? this.isAnalyzingPhotos,
      isAnalyzingSinglePhoto:
          isAnalyzingSinglePhoto ?? this.isAnalyzingSinglePhoto,
      isGettingSmartMatch: isGettingSmartMatch ?? this.isGettingSmartMatch,
      isAutoAssigning: isAutoAssigning ?? this.isAutoAssigning,
      isPredictingDemand: isPredictingDemand ?? this.isPredictingDemand,
      isAnalyzingDispute: isAnalyzingDispute ?? this.isAnalyzingDispute,
      isLoadingStatus: isLoadingStatus ?? this.isLoadingStatus,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      priceEstimation: priceEstimation ?? this.priceEstimation,
      photoAnalysis: photoAnalysis ?? this.photoAnalysis,
      singlePhotoAnalysis: singlePhotoAnalysis ?? this.singlePhotoAnalysis,
      smartMatch: smartMatch ?? this.smartMatch,
      autoAssignResult: autoAssignResult ?? this.autoAssignResult,
      demandPrediction: demandPrediction ?? this.demandPrediction,
      demandPredictions: demandPredictions ?? this.demandPredictions,
      demandForecasts: demandForecasts ?? this.demandForecasts,
      disputeAnalysis: disputeAnalysis ?? this.disputeAnalysis,
      pendingDisputes: pendingDisputes ?? this.pendingDisputes,
      aiStatus: aiStatus ?? this.aiStatus,
      matchingStats: matchingStats ?? this.matchingStats,
      predictionAccuracy: predictionAccuracy ?? this.predictionAccuracy,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      priceEstimationError: clearPriceEstimationError
          ? null
          : (priceEstimationError ?? this.priceEstimationError),
      photoAnalysisError: clearPhotoAnalysisError
          ? null
          : (photoAnalysisError ?? this.photoAnalysisError),
      smartMatchError: clearSmartMatchError
          ? null
          : (smartMatchError ?? this.smartMatchError),
      demandPredictionError: clearDemandPredictionError
          ? null
          : (demandPredictionError ?? this.demandPredictionError),
      disputeAnalysisError: clearDisputeAnalysisError
          ? null
          : (disputeAnalysisError ?? this.disputeAnalysisError),
    );
  }

  @override
  List<Object?> get props => [
        isEstimatingPrice,
        isAnalyzingPhotos,
        isAnalyzingSinglePhoto,
        isGettingSmartMatch,
        isAutoAssigning,
        isPredictingDemand,
        isAnalyzingDispute,
        isLoadingStatus,
        isLoadingStats,
        priceEstimation,
        photoAnalysis,
        singlePhotoAnalysis,
        smartMatch,
        autoAssignResult,
        demandPrediction,
        demandPredictions,
        demandForecasts,
        disputeAnalysis,
        pendingDisputes,
        aiStatus,
        matchingStats,
        predictionAccuracy,
        errorMessage,
        priceEstimationError,
        photoAnalysisError,
        smartMatchError,
        demandPredictionError,
        disputeAnalysisError,
      ];
}
