
import 'package:deneige_auto/features/reservation/data/models/vehicule_model.dart';

import '../../domain/entities/reservation.dart';
import '../../../../core/config/app_config.dart';

import 'parking_spot_model.dart';

class ReservationModel extends Reservation {
  const ReservationModel({
    required super.id,
    required super.userId,
    super.workerId,
    required super.parkingSpot,
    required super.vehicle,
    required super.departureTime,
    super.deadlineTime,
    required super.status,
    required super.serviceOptions,
    required super.basePrice,
    required super.totalPrice,
    super.beforePhotoUrl,
    super.afterPhotoUrl,
    required super.createdAt,
    super.assignedAt,
    super.startedAt,
    super.completedAt,
    super.workerNotes,
    super.rating,
    super.review,
    super.tip,
    super.isPriority,
    super.snowDepthCm,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String? ?? json['_id'] as String,
      userId: json['userId'] as String,
      workerId: json['workerId'] as String?,
      parkingSpot: json['parkingSpot'] != null
          ? ParkingSpotModel.fromJson(json['parkingSpot'] as Map<String, dynamic>)
          : ParkingSpotModel.fromJson({
        'id': 'manual',
        'spotNumber': json['parkingSpotNumber'] ?? json['customLocation'] ?? 'N/A',
        'level': 'outdoor',
        'isAssigned': false,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }),
      vehicle: json['vehicle'] != null
          ? VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>)
          : throw Exception('Vehicle data is required but was null'),
      departureTime: DateTime.parse(json['departureTime'] as String),
      deadlineTime: json['deadlineTime'] != null
          ? DateTime.parse(json['deadlineTime'] as String)
          : null,
      status: _parseReservationStatus(json['status'] as String),
      serviceOptions: (json['serviceOptions'] as List<dynamic>?)
          ?.map((e) => _parseServiceOption(e as String))
          .toList() ?? [],
      basePrice: (json['basePrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      beforePhotoUrl: json['beforePhotoUrl'] as String?,
      afterPhotoUrl: json['afterPhotoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      workerNotes: json['workerNotes'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      review: json['review'] as String?,
      tip: json['tip'] != null ? (json['tip'] as num).toDouble() : null,
      isPriority: json['isPriority'] as bool? ?? false,
      snowDepthCm: json['snowDepthCm'] as int?,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'workerId': workerId,
      'parkingSpot': (parkingSpot as ParkingSpotModel).toJson(),
      'vehicle': (vehicle as VehicleModel).toJson(),
      'departureTime': departureTime.toIso8601String(),
      'deadlineTime': deadlineTime?.toIso8601String(),
      'status': _reservationStatusToString(status),
      'serviceOptions': serviceOptions.map((e) => _serviceOptionToString(e)).toList(),
      'basePrice': basePrice,
      'totalPrice': totalPrice,
      'beforePhotoUrl': beforePhotoUrl,
      'afterPhotoUrl': afterPhotoUrl,
      'createdAt': createdAt.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'workerNotes': workerNotes,
      'rating': rating,
      'review': review,
      'tip': tip,
      'isPriority': isPriority,
      'snowDepthCm': snowDepthCm,
    };
  }

  static ReservationStatus _parseReservationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ReservationStatus.pending;
      case 'assigned':
        return ReservationStatus.assigned;
      case 'inprogress':
      case 'in_progress':
        return ReservationStatus.inProgress;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'late':
        return ReservationStatus.late;
      default:
        return ReservationStatus.pending;
    }
  }

  static String _reservationStatusToString(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'pending';
      case ReservationStatus.assigned:
        return 'assigned';
      case ReservationStatus.inProgress:
        return 'inProgress';
      case ReservationStatus.completed:
        return 'completed';
      case ReservationStatus.cancelled:
        return 'cancelled';
      case ReservationStatus.late:
        return 'late';
    }
  }

  static ServiceOption _parseServiceOption(String option) {
    switch (option.toLowerCase()) {
      case 'windowscraping':
      case 'window_scraping':
        return ServiceOption.windowScraping;
      case 'doordeicing':
      case 'door_deicing':
        return ServiceOption.doorDeicing;
      case 'wheelclearance':
      case 'wheel_clearance':
        return ServiceOption.wheelClearance;
      default:
        return ServiceOption.windowScraping;
    }
  }

  static String _serviceOptionToString(ServiceOption option) {
    switch (option) {
      case ServiceOption.windowScraping:
        return 'windowScraping';
      case ServiceOption.doorDeicing:
        return 'doorDeicing';
      case ServiceOption.wheelClearance:
        return 'wheelClearance';
    }
  }
}