import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';
import 'vehicle.dart';
import 'parking_spot.dart';

/// Entity représentant une réservation de déneigement
class Reservation extends Equatable {
  final String id;
  final String userId;
  final String? workerId;
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
  final bool isPriority; // Pour les abonnés
  final int? snowDepthCm;

  const Reservation({
    required this.id,
    required this.userId,
    this.workerId,
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
  });

  /// Vérifie si la réservation est en retard
  bool get isLate {
    if (deadlineTime == null || completedAt == null) return false;
    return completedAt!.isAfter(deadlineTime!);
  }

  /// Calcule le délai en minutes (négatif = en avance, positif = en retard)
  int? get delayInMinutes {
    if (deadlineTime == null || completedAt == null) return null;
    return completedAt!.difference(deadlineTime!).inMinutes;
  }

  /// Vérifie si la réservation peut être annulée
  bool get canBeCancelled {
    return status == ReservationStatus.pending ||
        status == ReservationStatus.assigned;
  }

  /// Vérifie si la réservation peut être notée
  bool get canBeRated {
    return status == ReservationStatus.completed && rating == null;
  }

  /// Durée estimée du service en minutes
  int get estimatedDurationMinutes {
    int base = 15; // Base 15 minutes
    if (serviceOptions.contains(ServiceOption.windowScraping)) base += 5;
    if (serviceOptions.contains(ServiceOption.doorDeicing)) base += 5;
    if (serviceOptions.contains(ServiceOption.wheelClearance)) base += 10;
    if (snowDepthCm != null && snowDepthCm! > 10) {
      base += (snowDepthCm! - 10) * 2; // +2 min par cm au-delà de 10cm
    }
    return base;
  }

  /// Temps suggéré pour démarrer (deadlineTime - estimatedDuration)
  DateTime? get suggestedStartTime {
    if (deadlineTime == null) return null;
    return deadlineTime!.subtract(Duration(minutes: estimatedDurationMinutes));
  }

  Reservation copyWith({
    String? id,
    String? userId,
    String? workerId,
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
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
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
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    workerId,
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
  ];
}

/// Extension pour le formatage
extension ReservationStatusExtension on ReservationStatus {
  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.assigned:
        return 'Assignée';
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