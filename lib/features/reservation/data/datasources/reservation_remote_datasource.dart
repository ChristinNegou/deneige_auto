import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/vehicle.dart';
import '../models/parking_spot_model.dart';
import '../models/reservation_model.dart';
import '../models/vehicule_model.dart';

/// Contrat du datasource distant pour les opérations de réservation.
/// Définit les appels API pour les véhicules, places de stationnement et réservations.
abstract class ReservationRemoteDataSource {
  Future<List<VehicleModel>> getVehicles();
  Future<List<ParkingSpotModel>> getParkingSpots({bool availableOnly});
  Future<List<ReservationModel>> getReservations({bool? upcoming});
  Future<ReservationModel> getReservationById(String reservationId);
  Future<ReservationModel> createReservation(Map<String, dynamic> data);
  Future<CancellationResult> cancelReservation(String reservationId,
      {String? reason});
  Future<ReservationModel> updateReservation(
      String reservationId, Map<String, dynamic> data);
  Future<Vehicle> addVehicle(Map<String, dynamic> data);
  Future<CancellationPolicy> getCancellationPolicy();
  Future<Map<String, dynamic>> rateReservation({
    required String reservationId,
    required int rating,
    String? review,
  });
  Future<Map<String, dynamic>> getReservationRating(String reservationId);
  Future<Map<String, dynamic>> addTip({
    required String reservationId,
    required double amount,
  });
  Future<void> deleteVehicle(String vehicleId);
  Future<String> uploadVehiclePhoto({
    required String vehicleId,
    required String photoPath,
  });
}

/// Résultat d'une annulation de réservation.
/// Contient les détails de facturation (frais, remboursement) et le statut précédent.
class CancellationResult {
  final bool success;
  final String message;
  final String reservationId;
  final String previousStatus;
  final double originalPrice;
  final double cancellationFeePercent;
  final double cancellationFeeAmount;
  final double refundAmount;

  CancellationResult({
    required this.success,
    required this.message,
    required this.reservationId,
    required this.previousStatus,
    required this.originalPrice,
    required this.cancellationFeePercent,
    required this.cancellationFeeAmount,
    required this.refundAmount,
  });

  factory CancellationResult.fromJson(Map<String, dynamic> json) {
    final billing = json['billing'] as Map<String, dynamic>? ?? {};
    final reservation = json['reservation'] as Map<String, dynamic>? ?? {};

    return CancellationResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      reservationId: reservation['id'] as String? ?? '',
      previousStatus: reservation['previousStatus'] as String? ?? '',
      originalPrice: (billing['originalPrice'] as num?)?.toDouble() ?? 0.0,
      cancellationFeePercent:
          (billing['cancellationFeePercent'] as num?)?.toDouble() ?? 0.0,
      cancellationFeeAmount:
          (billing['cancellationFeeAmount'] as num?)?.toDouble() ?? 0.0,
      refundAmount: (billing['refundAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Politique d'annulation regroupant les règles par statut de réservation.
class CancellationPolicy {
  final Map<String, CancellationPolicyItem> policies;

  CancellationPolicy({required this.policies});

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    final policyData = json['policy'] as Map<String, dynamic>? ?? {};
    final policies = <String, CancellationPolicyItem>{};

    policyData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        policies[key] = CancellationPolicyItem.fromJson(value);
      }
    });

    return CancellationPolicy(policies: policies);
  }
}

/// Élément de politique d'annulation pour un statut donné (frais en pourcentage).
class CancellationPolicyItem {
  final String status;
  final String label;
  final int feePercent;
  final String description;

  CancellationPolicyItem({
    required this.status,
    required this.label,
    required this.feePercent,
    required this.description,
  });

  factory CancellationPolicyItem.fromJson(Map<String, dynamic> json) {
    return CancellationPolicyItem(
      status: json['status'] as String? ?? '',
      label: json['label'] as String? ?? '',
      feePercent: json['feePercent'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}

/// Implémentation du datasource distant pour les réservations via l'API REST.
/// Gère les appels HTTP (Dio) pour le CRUD des réservations, véhicules et évaluations.
class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  final Dio dio;

  ReservationRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<VehicleModel>> getVehicles() async {
    try {
      final response = await dio.get('/vehicles');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['vehicles'] ?? response.data;
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur de récupération des véhicules',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<List<ParkingSpotModel>> getParkingSpots(
      {bool availableOnly = false}) async {
    try {
      final queryParams = {'available': availableOnly};

      final response = await dio.get(
        '/parking-spots',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['parkingSpots'] ?? response.data;
        return data.map((json) => ParkingSpotModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur de récupération des places de parking',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<List<ReservationModel>> getReservations({bool? upcoming}) async {
    try {
      final queryParams = upcoming != null ? {'upcoming': upcoming} : null;

      final response = await dio.get(
        '/reservations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['reservations'] ?? response.data;
        return data.map((json) => ReservationModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Erreur de récupération des réservations',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<ReservationModel> getReservationById(String reservationId) async {
    try {
      final response = await dio.get('/reservations/$reservationId');

      if (response.statusCode == 200) {
        final data = response.data['reservation'] ?? response.data;
        return ReservationModel.fromJson(data);
      } else {
        throw ServerException(
          message: 'Réservation non trouvée',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ServerException(
          message: 'Réservation non trouvée',
          statusCode: 404,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<ReservationModel> createReservation(Map<String, dynamic> data) async {
    try {
      debugPrint('📝 [DataSource] Envoi requête POST /reservations');
      debugPrint('📝 [DataSource] Data: $data');

      final response = await dio.post('/reservations', data: data);

      debugPrint('📝 [DataSource] Réponse: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ [DataSource] Réservation créée avec succès');
        return ReservationModel.fromJson(
            response.data['reservation'] ?? response.data);
      } else {
        debugPrint('❌ [DataSource] Erreur: ${response.statusCode}');
        throw ServerException(
          message: 'Erreur de création de réservation',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [DataSource] DioException: ${e.message}');
      debugPrint('❌ [DataSource] Response: ${e.response?.data}');
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<Vehicle> addVehicle(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        '/vehicles',
        data: data,
      );

      if (response.statusCode == 201) {
        // Convertir la réponse en VehicleModel
        return VehicleModel.fromJson(response.data['vehicle']);
      } else {
        throw ServerException(
          message:
              response.data['message'] ?? 'Erreur lors de l\'ajout du véhicule',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<CancellationResult> cancelReservation(String reservationId,
      {String? reason}) async {
    try {
      final response = await dio.patch(
        '/reservations/$reservationId/cancel-by-client',
        data: {
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return CancellationResult.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message:
              response.data['message'] ?? 'Erreur d\'annulation de réservation',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ServerException(
          message: e.response?.data['message'] ??
              'Réservation non trouvée ou déjà annulée',
          statusCode: 404,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<CancellationPolicy> getCancellationPolicy() async {
    try {
      final response =
          await dio.get('/reservations/client/cancellation-policy');

      if (response.statusCode == 200) {
        return CancellationPolicy.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Erreur de récupération de la politique d\'annulation',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<ReservationModel> updateReservation(
      String reservationId, Map<String, dynamic> data) async {
    try {
      final response =
          await dio.put('/reservations/$reservationId', data: data);

      if (response.statusCode == 200) {
        return ReservationModel.fromJson(
            response.data['reservation'] ?? response.data);
      } else {
        throw ServerException(
          message: 'Erreur de mise à jour de réservation',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> rateReservation({
    required String reservationId,
    required int rating,
    String? review,
  }) async {
    try {
      final response = await dio.post(
        '/reservations/$reservationId/rate',
        data: {
          'rating': rating,
          if (review != null) 'review': review,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': response.data['success'] ?? true,
          'message': response.data['message'] ?? 'Note enregistrée',
          'rating': response.data['rating'],
          'workerNewAverage': response.data['workerNewAverage'],
        };
      } else {
        throw ServerException(
          message: response.data['message'] ??
              'Erreur lors de l\'enregistrement de la note',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Erreur réseau: ${e.message}';
      throw ServerException(
          message: message, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<Map<String, dynamic>> getReservationRating(
      String reservationId) async {
    try {
      final response = await dio.get('/reservations/$reservationId/rating');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'hasRating': response.data['hasRating'] ?? false,
          'rating': response.data['rating'],
          'review': response.data['review'],
          'ratedAt': response.data['ratedAt'],
          'worker': response.data['worker'],
        };
      } else {
        throw ServerException(
          message: 'Erreur lors de la récupération de la note',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> addTip({
    required String reservationId,
    required double amount,
  }) async {
    try {
      final response = await dio.post(
        '/reservations/$reservationId/tip',
        data: {
          'amount': amount,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': response.data['success'] ?? true,
          'message': response.data['message'] ?? 'Pourboire envoyé',
          'tipAmount': response.data['tipAmount'],
          'workerName': response.data['workerName'],
        };
      } else {
        throw ServerException(
          message: response.data['message'] ??
              'Erreur lors de l\'envoi du pourboire',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Erreur réseau: ${e.message}';
      throw ServerException(
          message: message, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      final response = await dio.delete('/vehicles/$vehicleId');

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ??
              'Erreur lors de la suppression du véhicule',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ServerException(
          message: 'Véhicule non trouvé',
          statusCode: 404,
        );
      }
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }

  @override
  Future<String> uploadVehiclePhoto({
    required String vehicleId,
    required String photoPath,
  }) async {
    try {
      final fileName = photoPath.split('/').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '/vehicles/$vehicleId/photo',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data']['photoUrl'] as String;
      } else {
        throw ServerException(
          message: response.data['message'] ??
              'Erreur lors de l\'upload de la photo',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw NetworkException(message: 'Erreur réseau: ${e.message}');
    }
  }
}
