import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';
import 'vehicle.dart';
import 'parking_spot.dart';

class Reservation extends Equatable {
  final String id;
  final String userId;
  final String? workerId;
  final String? workerName;
  final String? workerPhone;
  final ParkingSpot parkingSpot;
  final Vehicle vehicle;
  final DateTime departureTime;
  final DateTime? deadlineTime;
  final ReservationStatus status;
  final List<ServiceOption> serviceOptions;
  final double basePrice;
  final double totalPrice;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? workerNotes;
  final double? rating;
  final String? review;
  final double? tip;
  final bool isPriority;
  final int? snowDepthCm;
  final int? estimatedArrivalMinutes;

  // Location fields
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;

  const Reservation({
    required this.id,
    required this.userId,
    this.workerId,
    this.workerName,
    this.workerPhone,
    required this.parkingSpot,
    required this.vehicle,
    required this.departureTime,
    this.deadlineTime,
    required this.status,
    required this.serviceOptions,
    required this.basePrice,
    required this.totalPrice,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    required this.createdAt,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.workerNotes,
    this.rating,
    this.review,
    this.tip,
    this.isPriority = false,
    this.snowDepthCm,
    this.estimatedArrivalMinutes,
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
  });

  bool get isLate {
    if (deadlineTime == null || completedAt == null) return false;
    return completedAt!.isAfter(deadlineTime!);
  }

  int? get delayInMinutes {
    if (deadlineTime == null || completedAt == null) return null;
    return completedAt!.difference(deadlineTime!).inMinutes;
  }

  bool get canBeCancelled {
    return status == ReservationStatus.pending ||
        status == ReservationStatus.assigned;
  }

  bool get canBeEdited {
    return status == ReservationStatus.pending;
  }

  bool get canBeRated {
    return status == ReservationStatus.completed && rating == null;
  }

  int get estimatedDurationMinutes {
    int base = 15;
    if (serviceOptions.contains(ServiceOption.windowScraping)) base += 5;
    if (serviceOptions.contains(ServiceOption.doorDeicing)) base += 5;
    if (serviceOptions.contains(ServiceOption.wheelClearance)) base += 10;
    if (snowDepthCm != null && snowDepthCm! > 10) {
      base += (snowDepthCm! - 10) * 2;
    }
    return base;
  }

  DateTime? get suggestedStartTime {
    if (deadlineTime == null) return null;
    return deadlineTime!.subtract(Duration(minutes: estimatedDurationMinutes));
  }

  Reservation copyWith({
    String? id,
    String? userId,
    String? workerId,
    String? workerName,
    String? workerPhone,
    ParkingSpot? parkingSpot,
    Vehicle? vehicle,
    DateTime? departureTime,
    DateTime? deadlineTime,
    ReservationStatus? status,
    List<ServiceOption>? serviceOptions,
    double? basePrice,
    double? totalPrice,
    String? beforePhotoUrl,
    String? afterPhotoUrl,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? workerNotes,
    double? rating,
    String? review,
    double? tip,
    bool? isPriority,
    int? snowDepthCm,
    int? estimatedArrivalMinutes,
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerPhone: workerPhone ?? this.workerPhone,
      parkingSpot: parkingSpot ?? this.parkingSpot,
      vehicle: vehicle ?? this.vehicle,
      departureTime: departureTime ?? this.departureTime,
      deadlineTime: deadlineTime ?? this.deadlineTime,
      status: status ?? this.status,
      serviceOptions: serviceOptions ?? this.serviceOptions,
      basePrice: basePrice ?? this.basePrice,
      totalPrice: totalPrice ?? this.totalPrice,
      beforePhotoUrl: beforePhotoUrl ?? this.beforePhotoUrl,
      afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      workerNotes: workerNotes ?? this.workerNotes,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      tip: tip ?? this.tip,
      isPriority: isPriority ?? this.isPriority,
      snowDepthCm: snowDepthCm ?? this.snowDepthCm,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationAddress: locationAddress ?? this.locationAddress,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    workerId,
    workerName,
    workerPhone,
    parkingSpot,
    vehicle,
    departureTime,
    deadlineTime,
    status,
    serviceOptions,
    basePrice,
    totalPrice,
    beforePhotoUrl,
    afterPhotoUrl,
    createdAt,
    assignedAt,
    startedAt,
    completedAt,
    workerNotes,
    rating,
    review,
    tip,
    isPriority,
    snowDepthCm,
    estimatedArrivalMinutes,
    locationLatitude,
    locationLongitude,
    locationAddress,
  ];
}

extension ReservationStatusExtension on ReservationStatus {
  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.assigned:
        return 'Assignée';
      case ReservationStatus.enRoute:
        return 'En route';
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.late:
        return 'En retard';
    }
  }

  String get icon {
    switch (this) {
      case ReservationStatus.pending:
        return '⏳';
      case ReservationStatus.assigned:
        return '👤';
      case ReservationStatus.enRoute:
        return '🚗';
      case ReservationStatus.inProgress:
        return '🚀';
      case ReservationStatus.completed:
        return '✅';
      case ReservationStatus.cancelled:
        return '❌';
      case ReservationStatus.late:
        return '⚠️';
    }
  }
}