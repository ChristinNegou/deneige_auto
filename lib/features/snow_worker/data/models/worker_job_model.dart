import '../../domain/entities/worker_job.dart';

class ClientInfoModel extends ClientInfo {
  const ClientInfoModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.phoneNumber,
  });

  factory ClientInfoModel.fromJson(Map<String, dynamic> json) {
    return ClientInfoModel(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
    };
  }
}

class VehicleInfoModel extends VehicleInfo {
  const VehicleInfoModel({
    required super.id,
    required super.make,
    required super.model,
    super.color,
    super.licensePlate,
    super.photoUrl,
  });

  factory VehicleInfoModel.fromJson(Map<String, dynamic> json) {
    return VehicleInfoModel(
      id: json['_id'] ?? json['id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      color: json['color'],
      licensePlate: json['licensePlate'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'make': make,
      'model': model,
      'color': color,
      'licensePlate': licensePlate,
      'photoUrl': photoUrl,
    };
  }
}

class JobLocationModel extends JobLocation {
  const JobLocationModel({
    required super.latitude,
    required super.longitude,
    super.address,
  });

  factory JobLocationModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List<dynamic>?;
    return JobLocationModel(
      longitude: coordinates != null && coordinates.isNotEmpty
          ? (coordinates[0] as num).toDouble()
          : 0.0,
      latitude: coordinates != null && coordinates.length > 1
          ? (coordinates[1] as num).toDouble()
          : 0.0,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'Point',
      'coordinates': [longitude, latitude],
      'address': address,
    };
  }
}

class JobPhotoModel extends JobPhoto {
  const JobPhotoModel({
    required super.url,
    required super.type,
    required super.uploadedAt,
  });

  factory JobPhotoModel.fromJson(Map<String, dynamic> json) {
    return JobPhotoModel(
      url: json['url'] ?? '',
      type: json['type'] ?? 'before',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class WorkerJobModel extends WorkerJob {
  const WorkerJobModel({
    required super.id,
    required super.client,
    required super.vehicle,
    super.location,
    super.parkingSpotNumber,
    super.customLocation,
    super.distanceKm,
    required super.departureTime,
    super.deadlineTime,
    required super.serviceOptions,
    required super.totalPrice,
    required super.isPriority,
    super.snowDepthCm,
    super.clientNotes,
    super.workerNotes,
    required super.status,
    super.photos = const [],
    required super.createdAt,
    super.assignedAt,
    super.startedAt,
    super.completedAt,
    super.estimatedArrivalTime,
    super.tipAmount,
    super.rating,
    super.review,
    super.requiredEquipment = const [],
    super.workerHasEquipment = true,
  });

  factory WorkerJobModel.fromJson(Map<String, dynamic> json) {
    // Parse service options
    final serviceOptionsJson = json['serviceOptions'] as List<dynamic>? ?? [];
    final serviceOptions = serviceOptionsJson.map((option) {
      switch (option.toString()) {
        case 'windowScraping':
          return ServiceOption.windowScraping;
        case 'doorDeicing':
          return ServiceOption.doorDeicing;
        case 'wheelClearance':
          return ServiceOption.wheelClearance;
        default:
          return ServiceOption.windowScraping;
      }
    }).toList();

    // Parse status
    JobStatus status;
    switch (json['status']?.toString() ?? 'pending') {
      case 'assigned':
        status = JobStatus.assigned;
        break;
      case 'enRoute':
        status = JobStatus.enRoute;
        break;
      case 'inProgress':
        status = JobStatus.inProgress;
        break;
      case 'completed':
        status = JobStatus.completed;
        break;
      case 'cancelled':
        status = JobStatus.cancelled;
        break;
      default:
        status = JobStatus.pending;
    }

    // Parse photos
    final photosJson = json['photos'] as List<dynamic>? ?? [];
    final photos = photosJson
        .map((p) => JobPhotoModel.fromJson(p as Map<String, dynamic>))
        .toList();

    // Parse client
    ClientInfo client;
    if (json['client'] != null) {
      client = ClientInfoModel.fromJson(json['client'] as Map<String, dynamic>);
    } else if (json['userId'] != null && json['userId'] is Map) {
      client = ClientInfoModel.fromJson(json['userId'] as Map<String, dynamic>);
    } else {
      client = const ClientInfoModel(id: '', firstName: 'Client', lastName: '');
    }

    // Parse vehicle
    VehicleInfo vehicle;
    if (json['vehicle'] != null && json['vehicle'] is Map) {
      vehicle =
          VehicleInfoModel.fromJson(json['vehicle'] as Map<String, dynamic>);
    } else if (json['vehicleInfo'] != null) {
      vehicle = VehicleInfoModel.fromJson(
          json['vehicleInfo'] as Map<String, dynamic>);
    } else {
      vehicle = const VehicleInfoModel(id: '', make: 'Véhicule', model: '');
    }

    // Parse location
    JobLocation? location;
    if (json['location'] != null && json['location'] is Map) {
      location =
          JobLocationModel.fromJson(json['location'] as Map<String, dynamic>);
    }

    // Parse tip
    double? tipAmount;
    if (json['tip'] != null && json['tip'] is Map) {
      tipAmount = (json['tip']['amount'] as num?)?.toDouble();
    }

    // Parse required equipment
    final requiredEquipmentJson =
        json['requiredEquipment'] as List<dynamic>? ?? [];
    final requiredEquipment = requiredEquipmentJson
        .map((e) => EquipmentTypeExtension.fromString(e.toString()))
        .whereType<EquipmentType>()
        .toList();

    // Parse worker has equipment flag
    final workerHasEquipment = json['workerHasEquipment'] as bool? ?? true;

    return WorkerJobModel(
      id: json['_id'] ?? json['id'] ?? '',
      client: client,
      vehicle: vehicle,
      location: location,
      parkingSpotNumber: json['parkingSpotNumber'],
      customLocation: json['customLocation'],
      distanceKm: json['distanceKm'] != null
          ? (json['distanceKm'] as num).toDouble()
          : null,
      departureTime: DateTime.parse(json['departureTime']),
      deadlineTime: json['deadlineTime'] != null
          ? DateTime.parse(json['deadlineTime'])
          : null,
      serviceOptions: serviceOptions,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      isPriority: json['isPriority'] ?? false,
      snowDepthCm: json['snowDepthCm'] as int?,
      clientNotes: json['notes'],
      workerNotes: json['workerNotes'],
      status: status,
      photos: photos,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'])
          : null,
      startedAt:
          json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      estimatedArrivalTime: json['estimatedArrivalTime'] != null
          ? DateTime.parse(json['estimatedArrivalTime'])
          : null,
      tipAmount: tipAmount,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'],
      requiredEquipment: requiredEquipment,
      workerHasEquipment: workerHasEquipment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'departureTime': departureTime.toIso8601String(),
      'deadlineTime': deadlineTime?.toIso8601String(),
      'serviceOptions': serviceOptions.map((o) => o.name).toList(),
      'totalPrice': totalPrice,
      'isPriority': isPriority,
      'snowDepthCm': snowDepthCm,
      'notes': clientNotes,
      'workerNotes': workerNotes,
      'status': status.name,
      'parkingSpotNumber': parkingSpotNumber,
      'customLocation': customLocation,
    };
  }
}
