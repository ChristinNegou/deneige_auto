import 'package:equatable/equatable.dart';

abstract class AIFeaturesEvent extends Equatable {
  const AIFeaturesEvent();

  @override
  List<Object?> get props => [];
}

/// Estimation de prix
class EstimatePriceEvent extends AIFeaturesEvent {
  final List<String> serviceOptions;
  final int snowDepthCm;
  final int timeUntilDepartureMinutes;
  final String? weatherCondition;
  final Map<String, dynamic>? location;
  final double? distanceKm;

  const EstimatePriceEvent({
    required this.serviceOptions,
    required this.snowDepthCm,
    required this.timeUntilDepartureMinutes,
    this.weatherCondition,
    this.location,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
        serviceOptions,
        snowDepthCm,
        timeUntilDepartureMinutes,
        weatherCondition,
        location,
        distanceKm,
      ];
}

/// Analyse des photos d'une reservation
class AnalyzePhotosEvent extends AIFeaturesEvent {
  final String reservationId;

  const AnalyzePhotosEvent(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

/// Analyse rapide d'une photo
class AnalyzeSinglePhotoEvent extends AIFeaturesEvent {
  final String photoUrl;
  final String photoType;

  const AnalyzeSinglePhotoEvent({
    required this.photoUrl,
    this.photoType = 'after',
  });

  @override
  List<Object?> get props => [photoUrl, photoType];
}

/// Smart matching
class GetSmartMatchEvent extends AIFeaturesEvent {
  final String reservationId;
  final int limit;

  const GetSmartMatchEvent(this.reservationId, {this.limit = 3});

  @override
  List<Object?> get props => [reservationId, limit];
}

/// Auto-assignation
class AutoAssignWorkerEvent extends AIFeaturesEvent {
  final String reservationId;

  const AutoAssignWorkerEvent(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

/// Prediction de demande par zone
class PredictDemandEvent extends AIFeaturesEvent {
  final String zone;

  const PredictDemandEvent(this.zone);

  @override
  List<Object?> get props => [zone];
}

/// Prediction pour toutes les zones
class PredictDemandAllEvent extends AIFeaturesEvent {
  const PredictDemandAllEvent();
}

/// Previsions recentes
class GetDemandForecastsEvent extends AIFeaturesEvent {
  final int hours;

  const GetDemandForecastsEvent({this.hours = 24});

  @override
  List<Object?> get props => [hours];
}

/// Analyse de litige
class AnalyzeDisputeEvent extends AIFeaturesEvent {
  final String disputeId;

  const AnalyzeDisputeEvent(this.disputeId);

  @override
  List<Object?> get props => [disputeId];
}

/// Litiges en attente
class GetPendingDisputesEvent extends AIFeaturesEvent {
  const GetPendingDisputesEvent();
}

/// Marquer litige comme revu
class MarkDisputeReviewedEvent extends AIFeaturesEvent {
  final String disputeId;
  final String? decision;

  const MarkDisputeReviewedEvent(this.disputeId, {this.decision});

  @override
  List<Object?> get props => [disputeId, decision];
}

/// Statut des services IA
class GetAIStatusEvent extends AIFeaturesEvent {
  const GetAIStatusEvent();
}

/// Statistiques de matching
class GetMatchingStatsEvent extends AIFeaturesEvent {
  const GetMatchingStatsEvent();
}

/// Precision des predictions
class GetPredictionAccuracyEvent extends AIFeaturesEvent {
  final int days;

  const GetPredictionAccuracyEvent({this.days = 7});

  @override
  List<Object?> get props => [days];
}

/// Reset l'etat
class ResetAIFeaturesEvent extends AIFeaturesEvent {
  const ResetAIFeaturesEvent();
}
