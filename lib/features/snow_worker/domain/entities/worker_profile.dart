import 'package:equatable/equatable.dart';

class PreferredZone extends Equatable {
  final String name;
  final double centerLat;
  final double centerLng;
  final double radiusKm;

  const PreferredZone({
    required this.name,
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
  });

  PreferredZone copyWith({
    String? name,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
  }) {
    return PreferredZone(
      name: name ?? this.name,
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  @override
  List<Object?> get props => [name, centerLat, centerLng, radiusKm];
}

class WorkerLocation extends Equatable {
  final double latitude;
  final double longitude;

  const WorkerLocation({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

enum VehicleType {
  car,
  truck,
  atv,
  other,
}

class WorkerNotificationPreferences extends Equatable {
  final bool newJobs;
  final bool urgentJobs;
  final bool tips;

  const WorkerNotificationPreferences({
    this.newJobs = true,
    this.urgentJobs = true,
    this.tips = true,
  });

  WorkerNotificationPreferences copyWith({
    bool? newJobs,
    bool? urgentJobs,
    bool? tips,
  }) {
    return WorkerNotificationPreferences(
      newJobs: newJobs ?? this.newJobs,
      urgentJobs: urgentJobs ?? this.urgentJobs,
      tips: tips ?? this.tips,
    );
  }

  @override
  List<Object?> get props => [newJobs, urgentJobs, tips];
}

class WorkerProfile extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? photoUrl;
  final bool isAvailable;
  final WorkerLocation? currentLocation;
  final List<PreferredZone> preferredZones;
  final int maxActiveJobs;
  final VehicleType vehicleType;
  final List<String> equipmentList;
  final WorkerNotificationPreferences notificationPreferences;
  final int totalJobsCompleted;
  final double totalEarnings;
  final double totalTipsReceived;
  final double averageRating;
  final int totalRatingsCount;

  const WorkerProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.photoUrl,
    required this.isAvailable,
    this.currentLocation,
    this.preferredZones = const [],
    this.maxActiveJobs = 3,
    this.vehicleType = VehicleType.car,
    this.equipmentList = const [],
    this.notificationPreferences = const WorkerNotificationPreferences(),
    this.totalJobsCompleted = 0,
    this.totalEarnings = 0,
    this.totalTipsReceived = 0,
    this.averageRating = 0,
    this.totalRatingsCount = 0,
  });

  String get fullName => '$firstName $lastName';

  WorkerProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoUrl,
    bool? isAvailable,
    WorkerLocation? currentLocation,
    List<PreferredZone>? preferredZones,
    int? maxActiveJobs,
    VehicleType? vehicleType,
    List<String>? equipmentList,
    WorkerNotificationPreferences? notificationPreferences,
    int? totalJobsCompleted,
    double? totalEarnings,
    double? totalTipsReceived,
    double? averageRating,
    int? totalRatingsCount,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLocation: currentLocation ?? this.currentLocation,
      preferredZones: preferredZones ?? this.preferredZones,
      maxActiveJobs: maxActiveJobs ?? this.maxActiveJobs,
      vehicleType: vehicleType ?? this.vehicleType,
      equipmentList: equipmentList ?? this.equipmentList,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalTipsReceived: totalTipsReceived ?? this.totalTipsReceived,
      averageRating: averageRating ?? this.averageRating,
      totalRatingsCount: totalRatingsCount ?? this.totalRatingsCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phoneNumber,
        photoUrl,
        isAvailable,
        currentLocation,
        preferredZones,
        maxActiveJobs,
        vehicleType,
        equipmentList,
        notificationPreferences,
        totalJobsCompleted,
        totalEarnings,
        totalTipsReceived,
        averageRating,
        totalRatingsCount,
      ];
}
