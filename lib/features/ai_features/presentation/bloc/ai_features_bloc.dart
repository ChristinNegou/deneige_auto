import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ai_features_repository.dart';
import 'ai_features_event.dart';
import 'ai_features_state.dart';

class AIFeaturesBloc extends Bloc<AIFeaturesEvent, AIFeaturesState> {
  final AIFeaturesRepository repository;

  AIFeaturesBloc({required this.repository}) : super(const AIFeaturesState()) {
    on<EstimatePriceEvent>(_onEstimatePrice);
    on<AnalyzePhotosEvent>(_onAnalyzePhotos);
    on<AnalyzeSinglePhotoEvent>(_onAnalyzeSinglePhoto);
    on<GetSmartMatchEvent>(_onGetSmartMatch);
    on<AutoAssignWorkerEvent>(_onAutoAssignWorker);
    on<PredictDemandEvent>(_onPredictDemand);
    on<PredictDemandAllEvent>(_onPredictDemandAll);
    on<GetDemandForecastsEvent>(_onGetDemandForecasts);
    on<AnalyzeDisputeEvent>(_onAnalyzeDispute);
    on<GetPendingDisputesEvent>(_onGetPendingDisputes);
    on<MarkDisputeReviewedEvent>(_onMarkDisputeReviewed);
    on<GetAIStatusEvent>(_onGetAIStatus);
    on<GetMatchingStatsEvent>(_onGetMatchingStats);
    on<GetPredictionAccuracyEvent>(_onGetPredictionAccuracy);
    on<ResetAIFeaturesEvent>(_onReset);
  }

  Future<void> _onEstimatePrice(
    EstimatePriceEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isEstimatingPrice: true,
      clearPriceEstimationError: true,
    ));

    final result = await repository.estimatePrice(
      serviceOptions: event.serviceOptions,
      snowDepthCm: event.snowDepthCm,
      timeUntilDepartureMinutes: event.timeUntilDepartureMinutes,
      weatherCondition: event.weatherCondition,
      location: event.location,
      distanceKm: event.distanceKm,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isEstimatingPrice: false,
        priceEstimationError: failure.message,
      )),
      (estimation) => emit(state.copyWith(
        isEstimatingPrice: false,
        priceEstimation: estimation,
      )),
    );
  }

  Future<void> _onAnalyzePhotos(
    AnalyzePhotosEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isAnalyzingPhotos: true,
      clearPhotoAnalysisError: true,
    ));

    final result = await repository.analyzePhotos(event.reservationId);

    result.fold(
      (failure) => emit(state.copyWith(
        isAnalyzingPhotos: false,
        photoAnalysisError: failure.message,
      )),
      (analysis) => emit(state.copyWith(
        isAnalyzingPhotos: false,
        photoAnalysis: analysis,
      )),
    );
  }

  Future<void> _onAnalyzeSinglePhoto(
    AnalyzeSinglePhotoEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isAnalyzingSinglePhoto: true,
      clearPhotoAnalysisError: true,
    ));

    final result = await repository.analyzeSinglePhoto(
      photoUrl: event.photoUrl,
      photoType: event.photoType,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isAnalyzingSinglePhoto: false,
        photoAnalysisError: failure.message,
      )),
      (analysis) => emit(state.copyWith(
        isAnalyzingSinglePhoto: false,
        singlePhotoAnalysis: analysis,
      )),
    );
  }

  Future<void> _onGetSmartMatch(
    GetSmartMatchEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isGettingSmartMatch: true,
      clearSmartMatchError: true,
    ));

    final result = await repository.getSmartMatch(
      event.reservationId,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isGettingSmartMatch: false,
        smartMatchError: failure.message,
      )),
      (match) => emit(state.copyWith(
        isGettingSmartMatch: false,
        smartMatch: match,
      )),
    );
  }

  Future<void> _onAutoAssignWorker(
    AutoAssignWorkerEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isAutoAssigning: true,
      clearErrorMessage: true,
    ));

    final result = await repository.autoAssignWorker(event.reservationId);

    result.fold(
      (failure) => emit(state.copyWith(
        isAutoAssigning: false,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        isAutoAssigning: false,
        autoAssignResult: data,
      )),
    );
  }

  Future<void> _onPredictDemand(
    PredictDemandEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isPredictingDemand: true,
      clearDemandPredictionError: true,
    ));

    final result = await repository.predictDemand(event.zone);

    result.fold(
      (failure) => emit(state.copyWith(
        isPredictingDemand: false,
        demandPredictionError: failure.message,
      )),
      (prediction) => emit(state.copyWith(
        isPredictingDemand: false,
        demandPrediction: prediction,
      )),
    );
  }

  Future<void> _onPredictDemandAll(
    PredictDemandAllEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isPredictingDemand: true,
      clearDemandPredictionError: true,
    ));

    final result = await repository.predictDemandAll();

    result.fold(
      (failure) => emit(state.copyWith(
        isPredictingDemand: false,
        demandPredictionError: failure.message,
      )),
      (predictions) => emit(state.copyWith(
        isPredictingDemand: false,
        demandPredictions: predictions,
      )),
    );
  }

  Future<void> _onGetDemandForecasts(
    GetDemandForecastsEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isPredictingDemand: true,
      clearDemandPredictionError: true,
    ));

    final result = await repository.getDemandForecasts(hours: event.hours);

    result.fold(
      (failure) => emit(state.copyWith(
        isPredictingDemand: false,
        demandPredictionError: failure.message,
      )),
      (forecasts) => emit(state.copyWith(
        isPredictingDemand: false,
        demandForecasts: forecasts,
      )),
    );
  }

  Future<void> _onAnalyzeDispute(
    AnalyzeDisputeEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isAnalyzingDispute: true,
      clearDisputeAnalysisError: true,
    ));

    final result = await repository.analyzeDispute(event.disputeId);

    result.fold(
      (failure) => emit(state.copyWith(
        isAnalyzingDispute: false,
        disputeAnalysisError: failure.message,
      )),
      (analysis) => emit(state.copyWith(
        isAnalyzingDispute: false,
        disputeAnalysis: analysis,
      )),
    );
  }

  Future<void> _onGetPendingDisputes(
    GetPendingDisputesEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(
      isAnalyzingDispute: true,
      clearDisputeAnalysisError: true,
    ));

    final result = await repository.getPendingDisputes();

    result.fold(
      (failure) => emit(state.copyWith(
        isAnalyzingDispute: false,
        disputeAnalysisError: failure.message,
      )),
      (disputes) => emit(state.copyWith(
        isAnalyzingDispute: false,
        pendingDisputes: disputes,
      )),
    );
  }

  Future<void> _onMarkDisputeReviewed(
    MarkDisputeReviewedEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    final result = await repository.markDisputeReviewed(
      event.disputeId,
      decision: event.decision,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (data) {
        // Refresh pending disputes list
        add(const GetPendingDisputesEvent());
      },
    );
  }

  Future<void> _onGetAIStatus(
    GetAIStatusEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(isLoadingStatus: true));

    final result = await repository.getAIStatus();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingStatus: false,
        errorMessage: failure.message,
      )),
      (status) => emit(state.copyWith(
        isLoadingStatus: false,
        aiStatus: status,
      )),
    );
  }

  Future<void> _onGetMatchingStats(
    GetMatchingStatsEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(isLoadingStats: true));

    final result = await repository.getMatchingStats();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingStats: false,
        errorMessage: failure.message,
      )),
      (stats) => emit(state.copyWith(
        isLoadingStats: false,
        matchingStats: stats,
      )),
    );
  }

  Future<void> _onGetPredictionAccuracy(
    GetPredictionAccuracyEvent event,
    Emitter<AIFeaturesState> emit,
  ) async {
    emit(state.copyWith(isLoadingStats: true));

    final result = await repository.getPredictionAccuracy(days: event.days);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingStats: false,
        errorMessage: failure.message,
      )),
      (accuracy) => emit(state.copyWith(
        isLoadingStats: false,
        predictionAccuracy: accuracy,
      )),
    );
  }

  void _onReset(
    ResetAIFeaturesEvent event,
    Emitter<AIFeaturesState> emit,
  ) {
    emit(const AIFeaturesState());
  }
}
