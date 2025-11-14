import 'package:equatable/equatable.dart';
import 'dart:math' show asin, cos, sqrt;

class ParkingSpot extends Equatable {
  final String id;
  final String spotNumber;
  final String? buildingCode;
  final ParkingLevel level;
  final String? section;
  final double? latitude;
  final double? longitude;
  final bool isAssigned;
  final String? assignedUserId;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingSpot({
    required this.id,
    required this.spotNumber,
    this.buildingCode,
    this.level = ParkingLevel.outdoor,
    this.section,
    this.latitude,
    this.longitude,
    this.isAssigned = false,
    this.assignedUserId,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    if (section != null) {
      return '$section-$spotNumber';
    }
    return spotNumber;
  }

  String get fullDisplayName {
    String name = displayName;
    if (level != ParkingLevel.outdoor) {
      name = '${level.displayName} - $name';
    }
    return name;
  }

  bool get isAvailable => isActive && !isAssigned;

  double? distanceFrom(double lat, double lng) {
    if (latitude == null || longitude == null) return null;

    const double earthRadius = 6371000;
    double dLat = _toRadians(lat - latitude!);
    double dLng = _toRadians(lng - longitude!);

    double a = 0.5 - 0.5 * cos(2 * dLat) +
        cos(_toRadians(latitude!)) * cos(_toRadians(lat)) * (1 - cos(2 * dLng)) / 2;

    return earthRadius * 2 * asin(sqrt(a));
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180.0;

  ParkingSpot copyWith({
    String? id,
    String? spotNumber,
    String? buildingCode,
    ParkingLevel? level,
    String? section,
    double? latitude,
    double? longitude,
    bool? isAssigned,
    String? assignedUserId,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      spotNumber: spotNumber ?? this.spotNumber,
      buildingCode: buildingCode ?? this.buildingCode,
      level: level ?? this.level,
      section: section ?? this.section,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAssigned: isAssigned ?? this.isAssigned,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    spotNumber,
    buildingCode,
    level,
    section,
    latitude,
    longitude,
    isAssigned,
    assignedUserId,
    isActive,
    notes,
    createdAt,
    updatedAt,
  ];
}

enum ParkingLevel {
  outdoor,
  underground1,
  underground2,
  underground3,
  covered,
}

extension ParkingLevelExtension on ParkingLevel {
  String get displayName {
    switch (this) {
      case ParkingLevel.outdoor:
        return 'Extérieur';
      case ParkingLevel.underground1:
        return 'Sous-sol 1';
      case ParkingLevel.underground2:
        return 'Sous-sol 2';
      case ParkingLevel.underground3:
        return 'Sous-sol 3';
      case ParkingLevel.covered:
        return 'Couvert';
    }
  }

  String get shortName {
    switch (this) {
      case ParkingLevel.outdoor:
        return 'EXT';
      case ParkingLevel.underground1:
        return 'SS1';
      case ParkingLevel.underground2:
        return 'SS2';
      case ParkingLevel.underground3:
        return 'SS3';
      case ParkingLevel.covered:
        return 'COV';
    }
  }

  String get icon {
    switch (this) {
      case ParkingLevel.outdoor:
        return '🌤️';
      case ParkingLevel.underground1:
      case ParkingLevel.underground2:
      case ParkingLevel.underground3:
        return '🔽';
      case ParkingLevel.covered:
        return '🏠';
    }
  }

  double get priceFactor {
    switch (this) {
      case ParkingLevel.outdoor:
        return 1.0;
      case ParkingLevel.underground1:
        return 0.8;
      case ParkingLevel.underground2:
        return 0.7;
      case ParkingLevel.underground3:
        return 0.6;
      case ParkingLevel.covered:
        return 0.85;
    }
  }
}