import '../../domain/entities/worker_profile.dart';

class PreferredZoneModel extends PreferredZone {
  const PreferredZoneModel({
    required super.name,
    required super.centerLat,
    required super.centerLng,
    required super.radiusKm,
  });

  factory PreferredZoneModel.fromJson(Map<String, dynamic> json) {
    return PreferredZoneModel(
      name: json['name'] as String? ?? '',
      centerLat: (json['centerLat'] as num?)?.toDouble() ?? 0,
      centerLng: (json['centerLng'] as num?)?.toDouble() ?? 0,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'centerLat': centerLat,
      'centerLng': centerLng,
      'radiusKm': radiusKm,
    };
  }
}

class WorkerLocationModel extends WorkerLocation {
  const WorkerLocationModel({
    required super.latitude,
    required super.longitude,
  });

  factory WorkerLocationModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List<dynamic>?;
    return WorkerLocationModel(
      longitude: coordinates != null && coordinates.isNotEmpty
          ? (coordinates[0] as num).toDouble()
          : 0.0,
      latitude: coordinates != null && coordinates.length > 1
          ? (coordinates[1] as num).toDouble()
          : 0.0,
    );
  }
}

class WorkerProfileModel extends WorkerProfile {
  const WorkerProfileModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.phoneNumber,
    super.photoUrl,
    required super.isAvailable,
    super.currentLocation,
    super.preferredZones = const [],
    super.maxActiveJobs = 3,
    super.vehicleType = VehicleType.car,
    super.equipmentList = const [],
    super.totalJobsCompleted = 0,
    super.totalEarnings = 0,
    super.totalTipsReceived = 0,
    super.averageRating = 0,
    super.totalRatingsCount = 0,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    final workerProfile = json['workerProfile'] as Map<String, dynamic>? ?? {};

    // Parse preferred zones
    final zonesJson = workerProfile['preferredZones'] as List<dynamic>? ?? [];
    final preferredZones = zonesJson
        .map((z) => PreferredZoneModel.fromJson(z as Map<String, dynamic>))
        .toList();

    // Parse equipment list
    final equipmentJson = workerProfile['equipmentList'] as List<dynamic>? ?? [];
    final equipmentList = equipmentJson.map((e) => e.toString()).toList();

    // Parse vehicle type
    VehicleType vehicleType;
    switch (workerProfile['vehicleType']?.toString() ?? 'car') {
      case 'truck':
        vehicleType = VehicleType.truck;
        break;
      case 'atv':
        vehicleType = VehicleType.atv;
        break;
      case 'other':
        vehicleType = VehicleType.other;
        break;
      default:
        vehicleType = VehicleType.car;
    }

    // Parse current location
    WorkerLocation? currentLocation;
    if (workerProfile['currentLocation'] != null) {
      currentLocation = WorkerLocationModel.fromJson(
          workerProfile['currentLocation'] as Map<String, dynamic>);
    }

    return WorkerProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
      isAvailable: workerProfile['isAvailable'] as bool? ?? false,
      currentLocation: currentLocation,
      preferredZones: preferredZones,
      maxActiveJobs: workerProfile['maxActiveJobs'] as int? ?? 3,
      vehicleType: vehicleType,
      equipmentList: equipmentList,
      totalJobsCompleted: workerProfile['totalJobsCompleted'] as int? ?? 0,
      totalEarnings: (workerProfile['totalEarnings'] as num?)?.toDouble() ?? 0,
      totalTipsReceived:
          (workerProfile['totalTipsReceived'] as num?)?.toDouble() ?? 0,
      averageRating: (workerProfile['averageRating'] as num?)?.toDouble() ?? 0,
      totalRatingsCount: workerProfile['totalRatingsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'workerProfile': {
        'isAvailable': isAvailable,
        'preferredZones': preferredZones
            .map((z) => (z as PreferredZoneModel).toJson())
            .toList(),
        'maxActiveJobs': maxActiveJobs,
        'vehicleType': vehicleType.name,
        'equipmentList': equipmentList,
        'totalJobsCompleted': totalJobsCompleted,
        'totalEarnings': totalEarnings,
        'totalTipsReceived': totalTipsReceived,
        'averageRating': averageRating,
        'totalRatingsCount': totalRatingsCount,
      },
    };
  }
}
