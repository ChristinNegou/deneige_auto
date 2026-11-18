import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';
import 'vehicle.dart';
import 'parking_spot.dart';

/// Entité métier représentant une réservation de déneigement.
/// Contient les informations du véhicule, de la place, du déneigeur et du statut.
class Reservation extends Equatable {
  final String id;
  final String userId;
  final String? workerId;
  final String? workerName;
  final String? workerPhone;
  final String? workerPhotoUrl;
  final bool? workerIsVerified;
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

  /// Etat du paiement cote serveur ('paid', 'pending', 'refunded'...).
  final String? paymentStatus;
  final int? snowDepthCm;
  final int? estimatedArrivalMinutes;

  // --- Champs de localisation ---
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;

  const Reservation({
    required this.id,
    required this.userId,
    this.workerId,
    this.workerName,
    this.workerPhone,
    this.workerPhotoUrl,
    this.workerIsVerified,
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
    this.paymentStatus,
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

  /// Le client a paye cette reservation (rien a rembourser sinon).
  bool get isPaid => paymentStatus == null || paymentStatus == 'paid';

  bool get canBeCancelled {
    // Le client peut annuler à tout moment (avec frais selon le statut)
    return status == ReservationStatus.pending ||
        status == ReservationStatus.assigned ||
        status == ReservationStatus.enRoute ||
        status == ReservationStatus.inProgress;
  }

  bool get canBeEdited {
    return status == ReservationStatus.pending;
  }

  bool get canBeRated {
    return status == ReservationStatus.completed && rating == null;
  }

  /// Vérifie si la réservation est passée (departureTime déjà écoulé)
  /// Utilisé pour filtrer les réservations dans la section "Prochaines réservations"
  bool get isPast {
    return departureTime.isBefore(DateTime.now());
  }

  /// Vérifie si la réservation a été créée récemment (moins de 2 heures)
  bool get isRecentlyCreated {
    final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
    return createdAt.isAfter(twoHoursAgo);
  }

  /// Vérifie si la réservation est à venir et active
  /// Inclut:
  /// - Réservations futures avec statut pending/assigned
  /// - Réservations créées récemment (même si departureTime est passé)
  /// - Réservations en cours (enRoute, inProgress)
  bool get isUpcoming {
    // Toujours afficher les réservations actives
    if (status == ReservationStatus.enRoute ||
        status == ReservationStatus.inProgress) {
      return true;
    }

    // Afficher les réservations récentes même si departureTime est passé
    if (isRecentlyCreated &&
        (status == ReservationStatus.pending ||
            status == ReservationStatus.assigned)) {
      return true;
    }

    // Réservations futures avec statut pending/assigned
    return !isPast &&
        (status == ReservationStatus.pending ||
            status == ReservationStatus.assigned);
  }

  /// Calcule la durée estimée du déneigement en minutes.
  /// Prend en compte les options de service et la profondeur de neige.
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
    String? workerPhotoUrl,
    bool? workerIsVerified,
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
    String? paymentStatus,
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
      workerPhotoUrl: workerPhotoUrl ?? this.workerPhotoUrl,
      workerIsVerified: workerIsVerified ?? this.workerIsVerified,
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
      paymentStatus: paymentStatus ?? this.paymentStatus,
      snowDepthCm: snowDepthCm ?? this.snowDepthCm,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
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
        workerPhotoUrl,
        workerIsVerified,
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
        paymentStatus,
        snowDepthCm,
        estimatedArrivalMinutes,
        locationLatitude,
        locationLongitude,
        locationAddress,
      ];
}

/// Extension fournissant le libellé d'affichage et l'icône pour chaque statut de réservation.
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
