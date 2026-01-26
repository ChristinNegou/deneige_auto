import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';

/// DataSource pour les fonctionnalités IA
class AIFeaturesRemoteDataSource {
  final Dio _dio;

  AIFeaturesRemoteDataSource({required Dio dio}) : _dio = dio;

  /// Estime le prix d'une réservation
  Future<Map<String, dynamic>> estimatePrice({
    required List<String> serviceOptions,
    required int snowDepthCm,
    required int timeUntilDepartureMinutes,
    String? weatherCondition,
    Map<String, dynamic>? location,
    double? distanceKm,
  }) async {
    try {
      final response = await _dio.post('/ai/estimate-price', data: {
        'serviceOptions': serviceOptions,
        'snowDepthCm': snowDepthCm,
        'timeUntilDepartureMinutes': timeUntilDepartureMinutes,
        'weatherCondition': weatherCondition,
        'location': location,
        'distanceKm': distanceKm,
      });

      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de l\'estimation du prix: $e');
    }
  }

  /// Analyse les photos d'une réservation
  Future<Map<String, dynamic>> analyzePhotos(String reservationId) async {
    try {
      final response = await _dio.post('/ai/analyze-photos/$reservationId');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de l\'analyse des photos: $e');
    }
  }

  /// Analyse rapide d'une photo
  Future<Map<String, dynamic>> analyzeSinglePhoto({
    required String photoUrl,
    String photoType = 'after',
  }) async {
    try {
      final response = await _dio.post('/ai/analyze-single-photo', data: {
        'photoUrl': photoUrl,
        'photoType': photoType,
      });
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de l\'analyse de la photo: $e');
    }
  }

  /// Smart matching pour une réservation (admin)
  Future<Map<String, dynamic>> getSmartMatch(String reservationId,
      {int limit = 3}) async {
    try {
      final response = await _dio.post('/ai/smart-match/$reservationId', data: {
        'limit': limit,
      });
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Erreur lors du smart matching: $e');
    }
  }

  /// Auto-assigne le meilleur worker (admin)
  Future<Map<String, dynamic>> autoAssignWorker(String reservationId) async {
    try {
      final response = await _dio.post('/ai/auto-assign/$reservationId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Erreur lors de l\'auto-assignation: $e');
    }
  }

  /// Prédiction de demande pour une zone (admin)
  Future<Map<String, dynamic>> predictDemand(String zone) async {
    try {
      final response = await _dio.get('/ai/predict-demand/$zone');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de la prédiction de demande: $e');
    }
  }

  /// Prédiction de demande pour toutes les zones (admin)
  Future<Map<String, dynamic>> predictDemandAll() async {
    try {
      final response = await _dio.get('/ai/predict-demand-all');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors de la prédiction globale: $e');
    }
  }

  /// Récupère les prévisions récentes (admin)
  Future<List<dynamic>> getDemandForecasts({int hours = 24}) async {
    try {
      final response = await _dio.get('/ai/demand-forecasts', queryParameters: {
        'hours': hours,
      });
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement des prévisions: $e');
    }
  }

  /// Analyse un litige (admin)
  Future<Map<String, dynamic>> analyzeDispute(String disputeId) async {
    try {
      final response = await _dio.post('/ai/analyze-dispute/$disputeId');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Erreur lors de l\'analyse du litige: $e');
    }
  }

  /// Liste les litiges en attente d'analyse (admin)
  Future<List<dynamic>> getPendingDisputes() async {
    try {
      final response = await _dio.get('/ai/pending-disputes');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement des litiges: $e');
    }
  }

  /// Marque un litige comme revu (admin)
  Future<Map<String, dynamic>> markDisputeReviewed(
    String disputeId, {
    String? decision,
  }) async {
    try {
      final response = await _dio.put('/ai/dispute-reviewed/$disputeId', data: {
        'decision': decision,
      });
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Erreur lors du marquage du litige: $e');
    }
  }

  /// Récupère le statut des services IA (admin)
  Future<Map<String, dynamic>> getAIStatus() async {
    try {
      final response = await _dio.get('/ai/status');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement du statut IA: $e');
    }
  }

  /// Statistiques de matching (admin)
  Future<Map<String, dynamic>> getMatchingStats() async {
    try {
      final response = await _dio.get('/ai/matching-stats');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Erreur lors du chargement des stats: $e');
    }
  }

  /// Précision des prédictions (admin)
  Future<List<dynamic>> getPredictionAccuracy({int days = 7}) async {
    try {
      final response =
          await _dio.get('/ai/prediction-accuracy', queryParameters: {
        'days': days,
      });
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
          message: 'Erreur lors du chargement de la précision: $e');
    }
  }

  AppException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String?;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Délai de connexion dépassé. Vérifiez votre connexion.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Impossible de se connecter au serveur.',
        );
      default:
        if (statusCode == 503) {
          return const ServerException(
            message: 'Service IA temporairement indisponible.',
            statusCode: 503,
          );
        }
        if (statusCode == 429) {
          return const ServerException(
            message:
                'Trop de requêtes. Veuillez réessayer dans quelques instants.',
            statusCode: 429,
          );
        }
        return ServerException(
          message: message ?? 'Une erreur serveur est survenue.',
          statusCode: statusCode,
        );
    }
  }
}
