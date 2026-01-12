import '../../domain/entities/vehicle.dart';
import '../../../../core/utils/time_utils.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.userId,
    required super.make,
    required super.model,
    super.year,
    required super.color,
    super.licensePlate,
    super.photoUrl,
    super.type,
    super.isDefault,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int?,
      color: json['color'] as String,
      licensePlate: json['licensePlate'] as String?,
      photoUrl: json['photoUrl'] as String?,
      type: _parseVehicleType(json['type'] as String?),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: TimeUtils.parseUtcToLocal(json['createdAt'] as String?),
      updatedAt: TimeUtils.parseUtcToLocal(json['updatedAt'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'licensePlate': licensePlate,
      'photoUrl': photoUrl,
      'type': _vehicleTypeToString(type),
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static VehicleType _parseVehicleType(String? type) {
    if (type == null) return VehicleType.car;
    switch (type.toLowerCase()) {
      case 'car':
        return VehicleType.car;
      case 'suv':
        return VehicleType.suv;
      case 'truck':
        return VehicleType.truck;
      case 'van':
        return VehicleType.van;
      case 'motorcycle':
        return VehicleType.motorcycle;
      default:
        return VehicleType.car;
    }
  }

  static String _vehicleTypeToString(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'car';
      case VehicleType.suv:
        return 'suv';
      case VehicleType.truck:
        return 'truck';
      case VehicleType.van:
        return 'van';
      case VehicleType.motorcycle:
        return 'motorcycle';
    }
  }
}
