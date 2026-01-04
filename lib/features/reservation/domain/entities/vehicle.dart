import 'package:equatable/equatable.dart';

/// Entity représentant un véhicule
class Vehicle extends Equatable {
  final String id;
  final String userId;
  final String make; // Marque (ex: Honda)
  final String model; // Modèle (ex: Civic)
  final int? year; // Année
  final String color; // Couleur
  final String? licensePlate;
  final String? photoUrl; // Photo du véhicule
  final VehicleType type;
  final bool isDefault; // Véhicule par défaut de l'utilisateur
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    this.year,
    required this.color,
    this.licensePlate,
    this.photoUrl,
    this.type = VehicleType.car,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Affichage formaté du véhicule
  String get displayName {
    if (year != null) {
      return '$make $model $year';
    }
    return '$make $model';
  }

  /// Affichage court (pour les listes)
  String get shortName {
    return '$make $model';
  }

  /// Affichage avec couleur
  String get displayWithColor {
    return '$color $make $model';
  }

  Vehicle copyWith({
    String? id,
    String? userId,
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
    String? photoUrl,
    VehicleType? type,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      photoUrl: photoUrl ?? this.photoUrl,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        make,
        model,
        year,
        color,
        licensePlate,
        photoUrl,
        type,
        isDefault,
        createdAt,
        updatedAt,
      ];
}

/// Types de véhicules
enum VehicleType {
  car, // Voiture
  suv, // VUS
  truck, // Camion
  van, // Fourgonnette
  motorcycle, // Moto (été)
}

extension VehicleTypeExtension on VehicleType {
  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Voiture';
      case VehicleType.suv:
        return 'VUS';
      case VehicleType.truck:
        return 'Camion';
      case VehicleType.van:
        return 'Fourgonnette';
      case VehicleType.motorcycle:
        return 'Moto';
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.car:
        return '🚗';
      case VehicleType.suv:
        return '🚙';
      case VehicleType.truck:
        return '🚚';
      case VehicleType.van:
        return '🚐';
      case VehicleType.motorcycle:
        return '🏍️';
    }
  }

  /// Multiplicateur de prix basé sur le type
  double get priceFactor {
    switch (this) {
      case VehicleType.car:
        return 1.0;
      case VehicleType.suv:
        return 1.2;
      case VehicleType.truck:
        return 1.3;
      case VehicleType.van:
        return 1.25;
      case VehicleType.motorcycle:
        return 0.7;
    }
  }
}
