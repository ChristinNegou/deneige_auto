import '../../domain/entities/parking_spot.dart';
import '../../../../core/utils/time_utils.dart';

class ParkingSpotModel extends ParkingSpot {
  const ParkingSpotModel({
    required super.id,
    required super.spotNumber,
    super.buildingCode,
    super.level,
    super.section,
    super.latitude,
    super.longitude,
    super.isAssigned,
    super.assignedUserId,
    super.isActive,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ParkingSpotModel.fromJson(Map<String, dynamic> json) {
    return ParkingSpotModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? 'unknown',
      spotNumber: json['spotNumber'] as String? ?? 'N/A',
      buildingCode: json['buildingCode'] as String?,
      level: _parseParkingLevel(json['level'] as String?),
      section: json['section'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      isAssigned: json['isAssigned'] as bool? ?? false,
      assignedUserId: json['assignedUserId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: TimeUtils.parseUtcToLocal(json['createdAt'] as String?),
      updatedAt: TimeUtils.parseUtcToLocal(json['updatedAt'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotNumber': spotNumber,
      'buildingCode': buildingCode,
      'level': _parkingLevelToString(level),
      'section': section,
      'latitude': latitude,
      'longitude': longitude,
      'isAssigned': isAssigned,
      'assignedUserId': assignedUserId,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ParkingLevel _parseParkingLevel(String? level) {
    if (level == null) return ParkingLevel.outdoor;
    switch (level.toLowerCase()) {
      case 'outdoor':
        return ParkingLevel.outdoor;
      case 'underground1':
      case 'underground_1':
        return ParkingLevel.underground1;
      case 'underground2':
      case 'underground_2':
        return ParkingLevel.underground2;
      case 'underground3':
      case 'underground_3':
        return ParkingLevel.underground3;
      case 'covered':
        return ParkingLevel.covered;
      default:
        return ParkingLevel.outdoor;
    }
  }

  static String _parkingLevelToString(ParkingLevel level) {
    switch (level) {
      case ParkingLevel.outdoor:
        return 'outdoor';
      case ParkingLevel.underground1:
        return 'underground1';
      case ParkingLevel.underground2:
        return 'underground2';
      case ParkingLevel.underground3:
        return 'underground3';
      case ParkingLevel.covered:
        return 'covered';
    }
  }
}
