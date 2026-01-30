import 'dart:io';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

/// Types de litiges disponibles
enum DisputeType {
  noShow('no_show', 'Déneigeur non venu'),
  incompleteWork('incomplete_work', 'Travail incomplet'),
  qualityIssue('quality_issue', 'Qualité insuffisante'),
  lateArrival('late_arrival', 'Retard important'),
  damage('damage', 'Dommage causé'),
  wrongLocation('wrong_location', 'Mauvais emplacement'),
  overcharge('overcharge', 'Surfacturation'),
  unprofessional('unprofessional', 'Comportement inapproprié'),
  other('other', 'Autre');

  final String value;
  final String label;

  const DisputeType(this.value, this.label);

  static DisputeType fromValue(String value) {
    return DisputeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisputeType.other,
    );
  }
}

/// Statuts des litiges
enum DisputeStatus {
  open('open', 'Ouvert'),
  underReview('under_review', 'En examen'),
  pendingResponse('pending_response', 'En attente de réponse'),
  resolved('resolved', 'Résolu'),
  closed('closed', 'Fermé'),
  appealed('appealed', 'En appel'),
  escalated('escalated', 'Escaladé');

  final String value;
  final String label;

  const DisputeStatus(this.value, this.label);

  static DisputeStatus fromValue(String value) {
    return DisputeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisputeStatus.open,
    );
  }
}

/// Modèle de preuve photo
class DisputePhoto {
  final String url;
  final DateTime? uploadedAt;
  final String? description;

  DisputePhoto({
    required this.url,
    this.uploadedAt,
    this.description,
  });

  factory DisputePhoto.fromJson(Map<String, dynamic> json) {
    return DisputePhoto(
      url: json['url'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'])
          : null,
      description: json['description'],
    );
  }
}

/// Modèle de constat clé de l'analyse IA
class AIKeyFinding {
  final String category;
  final String finding;
  final String
      impact; // 'favorable_claimant', 'favorable_respondent', 'neutral'

  AIKeyFinding({
    required this.category,
    required this.finding,
    required this.impact,
  });

  factory AIKeyFinding.fromJson(Map<String, dynamic> json) {
    return AIKeyFinding(
      category: json['category'] ?? '',
      finding: json['finding'] ?? '',
      impact: json['impact'] ?? 'neutral',
    );
  }
}

/// Modèle d'analyse IA
class DisputeAIAnalysis {
  final int? evidenceStrength; // 0-100
  final String? recommendedDecision;
  final double? confidence; // 0-1
  final String? reasoning;
  final List<String> riskFactors;
  final int? suggestedRefundPercent; // 0-100
  final String? suggestedPenalty;
  final List<AIKeyFinding> keyFindings;
  final DateTime? analyzedAt;
  final bool reviewedByAdmin;

  DisputeAIAnalysis({
    this.evidenceStrength,
    this.recommendedDecision,
    this.confidence,
    this.reasoning,
    this.riskFactors = const [],
    this.suggestedRefundPercent,
    this.suggestedPenalty,
    this.keyFindings = const [],
    this.analyzedAt,
    this.reviewedByAdmin = false,
  });

  factory DisputeAIAnalysis.fromJson(Map<String, dynamic> json) {
    return DisputeAIAnalysis(
      evidenceStrength: json['evidenceStrength'],
      recommendedDecision: json['recommendedDecision'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      reasoning: json['reasoning'],
      riskFactors: (json['riskFactors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedRefundPercent: json['suggestedRefundPercent'],
      suggestedPenalty: json['suggestedPenalty'],
      keyFindings: (json['keyFindings'] as List<dynamic>?)
              ?.map((e) => AIKeyFinding.fromJson(e))
              .toList() ??
          [],
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.tryParse(json['analyzedAt'])
          : null,
      reviewedByAdmin: json['reviewedByAdmin'] ?? false,
    );
  }
}

/// Modèle de litige
class Dispute {
  final String id;
  final DisputeType type;
  final DisputeStatus status;
  final String reservationId;
  final String description;
  final double claimedAmount;
  final String priority;
  final DateTime createdAt;
  final DateTime? responseDeadline;
  final DateTime? resolutionDeadline;
  final Map<String, dynamic>? claimant;
  final Map<String, dynamic>? respondent;
  final Map<String, dynamic>? resolution;
  final Map<String, dynamic>? response;
  final bool? autoResolutionEligible;
  // Nouveaux champs
  final List<DisputePhoto> evidencePhotos;
  final List<DisputePhoto> responsePhotos;
  final DisputeAIAnalysis? aiAnalysis;

  Dispute({
    required this.id,
    required this.type,
    required this.status,
    required this.reservationId,
    required this.description,
    required this.claimedAmount,
    required this.priority,
    required this.createdAt,
    this.responseDeadline,
    this.resolutionDeadline,
    this.claimant,
    this.respondent,
    this.resolution,
    this.response,
    this.autoResolutionEligible,
    this.evidencePhotos = const [],
    this.responsePhotos = const [],
    this.aiAnalysis,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    // Parser les photos de preuves
    List<DisputePhoto> evidencePhotos = [];
    if (json['evidence']?['photos'] != null) {
      evidencePhotos = (json['evidence']['photos'] as List<dynamic>)
          .map((e) => DisputePhoto.fromJson(e))
          .toList();
    }

    // Parser les photos de réponse
    List<DisputePhoto> responsePhotos = [];
    if (json['response']?['photos'] != null) {
      responsePhotos = (json['response']['photos'] as List<dynamic>)
          .map((e) => DisputePhoto.fromJson(e))
          .toList();
    }

    // Parser l'analyse IA
    DisputeAIAnalysis? aiAnalysis;
    if (json['aiAnalysis'] != null &&
        json['aiAnalysis']['analyzedAt'] != null) {
      aiAnalysis = DisputeAIAnalysis.fromJson(json['aiAnalysis']);
    }

    return Dispute(
      id: json['_id'] ?? json['id'] ?? '',
      type: DisputeType.fromValue(json['type'] ?? 'other'),
      status: DisputeStatus.fromValue(json['status'] ?? 'open'),
      reservationId: json['reservation']?['_id'] ?? json['reservation'] ?? '',
      description: json['description'] ?? '',
      claimedAmount: (json['claimedAmount'] ?? 0).toDouble(),
      priority: json['priority'] ?? 'medium',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      responseDeadline: json['deadlines']?['responseDeadline'] != null
          ? DateTime.tryParse(json['deadlines']['responseDeadline'])
          : null,
      resolutionDeadline: json['deadlines']?['resolutionDeadline'] != null
          ? DateTime.tryParse(json['deadlines']['resolutionDeadline'])
          : null,
      claimant: json['claimant'],
      respondent: json['respondent'],
      resolution: json['resolution'],
      response: json['response'],
      autoResolutionEligible: json['autoResolution']?['eligible'],
      evidencePhotos: evidencePhotos,
      responsePhotos: responsePhotos,
      aiAnalysis: aiAnalysis,
    );
  }

  bool get isOpen =>
      status == DisputeStatus.open ||
      status == DisputeStatus.underReview ||
      status == DisputeStatus.pendingResponse;

  bool get canRespond =>
      status == DisputeStatus.open || status == DisputeStatus.pendingResponse;

  bool get canAppeal => status == DisputeStatus.resolved;

  bool get hasResponse => response != null && response!['text'] != null;

  bool get hasEvidence => evidencePhotos.isNotEmpty;

  bool get hasAIAnalysis => aiAnalysis != null;
}

/// Service pour gérer les litiges
class DisputeService {
  final Dio _dio;

  DisputeService({required DioClient dioClient}) : _dio = dioClient.dio;

  // ============== PHOTO UPLOAD ==============

  /// Upload des photos pour un litige
  /// Retourne la liste des URLs des photos uploadées
  Future<List<String>> uploadPhotos(List<File> photos) async {
    if (photos.isEmpty) return [];

    final formData = FormData();
    for (final photo in photos) {
      final fileName = photo.path.split('/').last;
      formData.files.add(
        MapEntry(
          'photos',
          await MultipartFile.fromFile(photo.path, filename: fileName),
        ),
      );
    }

    final response = await _dio.post(
      '/disputes/upload-photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final List<dynamic> urls = response.data['urls'] ?? [];
    return urls.cast<String>();
  }

  // ============== CLIENT ENDPOINTS ==============

  /// Signaler un no-show (déneigeur pas venu)
  Future<Map<String, dynamic>> reportNoShow({
    required String reservationId,
    String? description,
    List<String>? photos,
    Map<String, double>? gpsLocation,
  }) async {
    final response = await _dio.post(
      '/disputes/report-no-show/$reservationId',
      data: {
        if (description != null) 'description': description,
        if (photos != null) 'photos': photos,
        if (gpsLocation != null) 'gpsLocation': gpsLocation,
      },
    );
    return response.data;
  }

  /// Créer un litige général
  Future<Map<String, dynamic>> createDispute({
    required String reservationId,
    required DisputeType type,
    required String description,
    double? claimedAmount,
    List<String>? photos,
    Map<String, double>? gpsLocation,
  }) async {
    final response = await _dio.post(
      '/disputes',
      data: {
        'reservationId': reservationId,
        'type': type.value,
        'description': description,
        if (claimedAmount != null) 'claimedAmount': claimedAmount,
        if (photos != null) 'photos': photos,
        if (gpsLocation != null) 'gpsLocation': gpsLocation,
      },
    );
    return response.data;
  }

  /// Obtenir mes litiges
  Future<List<Dispute>> getMyDisputes({
    DisputeStatus? status,
    DisputeType? type,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status.value;
    if (type != null) queryParams['type'] = type.value;

    final response = await _dio.get(
      '/disputes/my-disputes',
      queryParameters: queryParams,
    );

    final List<dynamic> disputesJson = response.data['disputes'] ?? [];
    return disputesJson.map((json) => Dispute.fromJson(json)).toList();
  }

  /// Obtenir les détails d'un litige
  Future<Dispute> getDisputeDetails(String disputeId) async {
    final response = await _dio.get('/disputes/$disputeId');
    return Dispute.fromJson(response.data['dispute']);
  }

  /// Répondre à un litige (pour le défendeur)
  Future<Map<String, dynamic>> respondToDispute({
    required String disputeId,
    required String text,
    List<String>? photos,
  }) async {
    final response = await _dio.post(
      '/disputes/$disputeId/respond',
      data: {
        'text': text,
        if (photos != null) 'photos': photos,
      },
    );
    return response.data;
  }

  /// Ajouter des preuves à un litige
  Future<Map<String, dynamic>> addEvidence({
    required String disputeId,
    List<String>? photos,
    List<Map<String, dynamic>>? documents,
    String? description,
  }) async {
    final response = await _dio.post(
      '/disputes/$disputeId/evidence',
      data: {
        if (photos != null) 'photos': photos,
        if (documents != null) 'documents': documents,
        if (description != null) 'description': description,
      },
    );
    return response.data;
  }

  /// Faire appel d'une décision
  Future<Map<String, dynamic>> appealDispute({
    required String disputeId,
    required String reason,
  }) async {
    final response = await _dio.post(
      '/disputes/$disputeId/appeal',
      data: {'reason': reason},
    );
    return response.data;
  }

  /// Confirmer la satisfaction du travail
  Future<Map<String, dynamic>> confirmSatisfaction({
    required String reservationId,
    required bool satisfied,
    String? comments,
  }) async {
    final response = await _dio.post(
      '/disputes/confirm-satisfaction/$reservationId',
      data: {
        'satisfied': satisfied,
        if (comments != null) 'comments': comments,
      },
    );
    return response.data;
  }

  /// Obtenir les types de litiges disponibles
  Future<List<Map<String, dynamic>>> getDisputeTypes() async {
    final response = await _dio.get('/disputes/types');
    final List<dynamic> types = response.data['types'] ?? [];
    return types.cast<Map<String, dynamic>>();
  }

  // ============== ADMIN ENDPOINTS ==============

  /// Obtenir tous les litiges (admin)
  Future<Map<String, dynamic>> getAllDisputes({
    DisputeStatus? status,
    DisputeType? type,
    String? priority,
    int page = 1,
    int limit = 20,
    String sort = '-createdAt',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort,
    };
    if (status != null) queryParams['status'] = status.value;
    if (type != null) queryParams['type'] = type.value;
    if (priority != null) queryParams['priority'] = priority;

    final response = await _dio.get(
      '/disputes/admin/all',
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Obtenir les statistiques des litiges (admin)
  Future<Map<String, dynamic>> getDisputeStats() async {
    final response = await _dio.get('/disputes/admin/stats');
    return response.data['stats'];
  }

  /// Résoudre un litige (admin)
  Future<Map<String, dynamic>> resolveDispute({
    required String disputeId,
    required String decision,
    double? refundAmount,
    String? workerPenalty,
    String? clientPenalty,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/disputes/$disputeId/resolve',
      data: {
        'decision': decision,
        if (refundAmount != null) 'refundAmount': refundAmount,
        if (workerPenalty != null) 'workerPenalty': workerPenalty,
        if (clientPenalty != null) 'clientPenalty': clientPenalty,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  /// Ajouter une note admin
  Future<Map<String, dynamic>> addAdminNote({
    required String disputeId,
    required String note,
  }) async {
    final response = await _dio.post(
      '/disputes/$disputeId/admin-note',
      data: {'note': note},
    );
    return response.data;
  }

  /// Résoudre un appel (admin)
  Future<Map<String, dynamic>> resolveAppeal({
    required String disputeId,
    required String decision,
    String? notes,
    double? newRefundAmount,
    String? newWorkerPenalty,
    String? newClientPenalty,
  }) async {
    final response = await _dio.post(
      '/disputes/$disputeId/resolve-appeal',
      data: {
        'decision': decision,
        if (notes != null) 'notes': notes,
        if (newRefundAmount != null) 'newRefundAmount': newRefundAmount,
        if (newWorkerPenalty != null) 'newWorkerPenalty': newWorkerPenalty,
        if (newClientPenalty != null) 'newClientPenalty': newClientPenalty,
      },
    );
    return response.data;
  }

  /// Vérifier la qualité d'un travail (admin)
  Future<Map<String, dynamic>> verifyWorkQuality(String reservationId) async {
    final response = await _dio.post('/disputes/verify-quality/$reservationId');
    return response.data['verification'];
  }
}
