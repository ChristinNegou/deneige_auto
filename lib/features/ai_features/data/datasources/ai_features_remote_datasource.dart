import 'package:dio/dio.dart';
import '../../../../core/di/injection_container.dart';

/// DataSource pour les fonctionnalités IA
class AIFeaturesRemoteDataSource {
  final Dio _dio;

  AIFeaturesRemoteDataSource({Dio? dio}) : _dio = dio ?? sl<Dio>();

  /// Estime le prix d'une réservation
  Future<Map<String, dynamic>> estimatePrice({
    required List<String> serviceOptions,
    required int snowDepthCm,
    required int timeUntilDepartureMinutes,
    String? weatherCondition,
    Map<String, dynamic>? location,
    double? distanceKm,
  }) async {
    final response = await _dio.post('/ai/estimate-price', data: {
      'serviceOptions': serviceOptions,
      'snowDepthCm': snowDepthCm,
      'timeUntilDepartureMinutes': timeUntilDepartureMinutes,
      'weatherCondition': weatherCondition,
      'location': location,
      'distanceKm': distanceKm,
    });

    return response.data['data'] as Map<String, dynamic>;
  }

  /// Analyse les photos d'une réservation
  Future<Map<String, dynamic>> analyzePhotos(String reservationId) async {
    final response = await _dio.post('/ai/analyze-photos/$reservationId');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Analyse rapide d'une photo
  Future<Map<String, dynamic>> analyzeSinglePhoto({
    required String photoUrl,
    String photoType = 'after',
  }) async {
    final response = await _dio.post('/ai/analyze-single-photo', data: {
      'photoUrl': photoUrl,
      'photoType': photoType,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Smart matching pour une réservation (admin)
  Future<Map<String, dynamic>> getSmartMatch(String reservationId,
      {int limit = 3}) async {
    final response = await _dio.post('/ai/smart-match/$reservationId', data: {
      'limit': limit,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Auto-assigne le meilleur worker (admin)
  Future<Map<String, dynamic>> autoAssignWorker(String reservationId) async {
    final response = await _dio.post('/ai/auto-assign/$reservationId');
    return response.data;
  }

  /// Prédiction de demande pour une zone (admin)
  Future<Map<String, dynamic>> predictDemand(String zone) async {
    final response = await _dio.get('/ai/predict-demand/$zone');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Prédiction de demande pour toutes les zones (admin)
  Future<Map<String, dynamic>> predictDemandAll() async {
    final response = await _dio.get('/ai/predict-demand-all');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Récupère les prévisions récentes (admin)
  Future<List<dynamic>> getDemandForecasts({int hours = 24}) async {
    final response = await _dio.get('/ai/demand-forecasts', queryParameters: {
      'hours': hours,
    });
    return response.data['data'] as List<dynamic>;
  }

  /// Analyse un litige (admin)
  Future<Map<String, dynamic>> analyzeDispute(String disputeId) async {
    final response = await _dio.post('/ai/analyze-dispute/$disputeId');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Liste les litiges en attente d'analyse (admin)
  Future<List<dynamic>> getPendingDisputes() async {
    final response = await _dio.get('/ai/pending-disputes');
    return response.data['data'] as List<dynamic>;
  }

  /// Marque un litige comme revu (admin)
  Future<Map<String, dynamic>> markDisputeReviewed(
    String disputeId, {
    String? decision,
  }) async {
    final response = await _dio.put('/ai/dispute-reviewed/$disputeId', data: {
      'decision': decision,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Récupère le statut des services IA (admin)
  Future<Map<String, dynamic>> getAIStatus() async {
    final response = await _dio.get('/ai/status');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Statistiques de matching (admin)
  Future<Map<String, dynamic>> getMatchingStats() async {
    final response = await _dio.get('/ai/matching-stats');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Précision des prédictions (admin)
  Future<List<dynamic>> getPredictionAccuracy({int days = 7}) async {
    final response =
        await _dio.get('/ai/prediction-accuracy', queryParameters: {
      'days': days,
    });
    return response.data['data'] as List<dynamic>;
  }
}
