import 'dart:math';

import 'package:equatable/equatable.dart';

/// Entity représentant une place de stationnement
class ParkingSpot extends Equatable {
  final String id;
  final String spotNumber;      // Ex: "B-12"
  final String? buildingCode;   // Code de l'immeuble (pour multi-immeubles V2)
  final ParkingLevel level;     // Niveau de stationnement
  final String? section;        // Section (A, B, C, etc.)
  final double? latitude;       // Coordonnées GPS (optionnel)
  final double? longitude;
  final bool isAssigned;        // Assignée à un résident
  final String? assignedUserId; // ID du résident assigné
  final bool isActive;          // Place active (non bloquée)
  final String? notes;          // Notes spéciales (ex: "près de l'ascenseur")
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

  /// Affichage formaté de la place
  String get displayName {
    if (section != null) {
      return '$section-$spotNumber';
    }
    return spotNumber;
  }

  /// Affichage complet avec niveau
  String get fullDisplayName {
    String name = displayName;
    if (level != ParkingLevel.outdoor) {
      name = '${level.displayName} - $name';
    }
    return name;
  }

  /// Vérifie si la place est disponible
  bool get isAvailable => isActive && !isAssigned;

  /// Distance approximative depuis un point (si GPS disponible)
  double? distanceFrom(double lat, double lng) {
    if (latitude == null || longitude == null) return null;

    // Formule haversine pour calculer la distance entre deux points GPS
    const double earthRadius = 6371000; // mètres
    
    double lat1Rad = _toRadians(latitude!);
    double lat2Rad = _toRadians(lat);
    double dLat = _toRadians(lat - latitude!);
    double dLng = _toRadians(lng - longitude!);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(dLng / 2) * sin(dLng / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;

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

/// Niveaux de stationnement
enum ParkingLevel {
  outdoor,      // Extérieur
  underground1, // Sous-sol 1
  underground2, // Sous-sol 2
  underground3, // Sous-sol 3
  covered,      // Couvert (mais pas souterrain)
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

  /// Multiplicateur de prix (souterrain = moins cher car moins exposé)
  double get priceFactor {
    switch (this) {
      case ParkingLevel.outdoor:
        return 1.0;
      case ParkingLevel.underground1:
        return 0.8; // -20% car moins de neige
      case ParkingLevel.underground2:
        return 0.7;
      case ParkingLevel.underground3:
        return 0.6;
      case ParkingLevel.covered:
        return 0.85;
    }
  }
}