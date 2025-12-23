import 'package:equatable/equatable.dart';

enum JobStatus {
  pending,
  assigned,
  enRoute,
  inProgress,
  completed,
  cancelled,
}

enum ServiceOption {
  windowScraping,
  doorDeicing,
  wheelClearance,
}

class ClientInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  const ClientInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [id, firstName, lastName, phoneNumber];
}

class VehicleInfo extends Equatable {
  final String id;
  final String make;
  final String model;
  final String? color;
  final String? licensePlate;

  const VehicleInfo({
    required this.id,
    required this.make,
    required this.model,
    this.color,
    this.licensePlate,
  });

  String get displayName => '$make $model';

  @override
  List<Object?> get props => [id, make, model, color, licensePlate];
}

class JobLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const JobLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

class JobPhoto extends Equatable {
  final String url;
  final String type; // 'before' or 'after'
  final DateTime uploadedAt;

  const JobPhoto({
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [url, type, uploadedAt];
}

class WorkerJob extends Equatable {
  final String id;
  final ClientInfo client;
  final VehicleInfo vehicle;
  final JobLocation? location;
  final String? parkingSpotNumber;
  final String? customLocation;
  final double? distanceKm;
  final DateTime departureTime;
  final DateTime? deadlineTime;
  final List<ServiceOption> serviceOptions;
  final double totalPrice;
  final bool isPriority;
  final int? snowDepthCm;
  final String? clientNotes;
  final String? workerNotes;
  final JobStatus status;
  final List<JobPhoto> photos;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? estimatedArrivalTime;
  final double? tipAmount;
  final double? rating;
  final String? review;

  const WorkerJob({
    required this.id,
    required this.client,
    required this.vehicle,
    this.location,
    this.parkingSpotNumber,
    this.customLocation,
    this.distanceKm,
    required this.departureTime,
    this.deadlineTime,
    required this.serviceOptions,
    required this.totalPrice,
    required this.isPriority,
    this.snowDepthCm,
    this.clientNotes,
    this.workerNotes,
    required this.status,
    this.photos = const [],
    required this.createdAt,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.estimatedArrivalTime,
    this.tipAmount,
    this.rating,
    this.review,
  });

  /// Returns the display address (parking spot number, custom location, or location address)
  String get displayAddress {
    if (parkingSpotNumber != null && parkingSpotNumber!.isNotEmpty) {
      return 'Place $parkingSpotNumber';
    }
    if (customLocation != null && customLocation!.isNotEmpty) {
      return customLocation!;
    }
    if (location?.address != null) {
      return location!.address!;
    }
    return 'Adresse non spécifiée';
  }

  /// Returns true if the job is urgent (less than 2 hours until departure)
  bool get isUrgent {
    final now = DateTime.now();
    final hoursUntilDeparture = departureTime.difference(now).inMinutes / 60;
    return hoursUntilDeparture < 2;
  }

  /// Returns hours until departure
  double get hoursUntilDeparture {
    final now = DateTime.now();
    return departureTime.difference(now).inMinutes / 60;
  }

  /// Returns the before photo URL if exists
  String? get beforePhotoUrl {
    final beforePhoto = photos.where((p) => p.type == 'before').firstOrNull;
    return beforePhoto?.url;
  }

  /// Returns the after photo URL if exists
  String? get afterPhotoUrl {
    final afterPhoto = photos.where((p) => p.type == 'after').firstOrNull;
    return afterPhoto?.url;
  }

  /// Returns true if job can be started (is assigned)
  bool get canBeStarted => status == JobStatus.assigned;

  /// Returns true if job can be completed (is in progress)
  bool get canBeCompleted => status == JobStatus.inProgress;

  /// Returns the duration of the job in minutes (if completed)
  int? get durationMinutes {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!).inMinutes;
    }
    return null;
  }

  WorkerJob copyWith({
    String? id,
    ClientInfo? client,
    VehicleInfo? vehicle,
    JobLocation? location,
    String? parkingSpotNumber,
    String? customLocation,
    double? distanceKm,
    DateTime? departureTime,
    DateTime? deadlineTime,
    List<ServiceOption>? serviceOptions,
    double? totalPrice,
    bool? isPriority,
    int? snowDepthCm,
    String? clientNotes,
    String? workerNotes,
    JobStatus? status,
    List<JobPhoto>? photos,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? estimatedArrivalTime,
    double? tipAmount,
    double? rating,
    String? review,
  }) {
    return WorkerJob(
      id: id ?? this.id,
      client: client ?? this.client,
      vehicle: vehicle ?? this.vehicle,
      location: location ?? this.location,
      parkingSpotNumber: parkingSpotNumber ?? this.parkingSpotNumber,
      customLocation: customLocation ?? this.customLocation,
      distanceKm: distanceKm ?? this.distanceKm,
      departureTime: departureTime ?? this.departureTime,
      deadlineTime: deadlineTime ?? this.deadlineTime,
      serviceOptions: serviceOptions ?? this.serviceOptions,
      totalPrice: totalPrice ?? this.totalPrice,
      isPriority: isPriority ?? this.isPriority,
      snowDepthCm: snowDepthCm ?? this.snowDepthCm,
      clientNotes: clientNotes ?? this.clientNotes,
      workerNotes: workerNotes ?? this.workerNotes,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      tipAmount: tipAmount ?? this.tipAmount,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  @override
  List<Object?> get props => [
        id,
        client,
        vehicle,
        location,
        parkingSpotNumber,
        customLocation,
        distanceKm,
        departureTime,
        deadlineTime,
        serviceOptions,
        totalPrice,
        isPriority,
        snowDepthCm,
        clientNotes,
        workerNotes,
        status,
        photos,
        createdAt,
        assignedAt,
        startedAt,
        completedAt,
        estimatedArrivalTime,
        tipAmount,
        rating,
        review,
      ];
}
