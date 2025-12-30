class AdminReservation {
  final String id;
  final String status;
  final DateTime departureTime;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final double totalPrice;
  final double platformFee;
  final double workerPayout;
  final String? paymentStatus;
  final String? paymentIntentId;
  final ReservationClient? client;
  final ReservationWorker? worker;
  final ReservationVehicle? vehicle;
  final String? parkingSpotNumber;
  final String? notes;
  final List<String> serviceOptions;
  final DateTime createdAt;
  final String? cancellationReason;
  final bool isRefunded;
  final double? refundAmount;

  AdminReservation({
    required this.id,
    required this.status,
    required this.departureTime,
    this.completedAt,
    this.cancelledAt,
    required this.totalPrice,
    required this.platformFee,
    required this.workerPayout,
    this.paymentStatus,
    this.paymentIntentId,
    this.client,
    this.worker,
    this.vehicle,
    this.parkingSpotNumber,
    this.notes,
    required this.serviceOptions,
    required this.createdAt,
    this.cancellationReason,
    this.isRefunded = false,
    this.refundAmount,
  });

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'assigned':
        return 'Assignée';
      case 'enRoute':
        return 'En route';
      case 'inProgress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'assigned':
        return 'blue';
      case 'enRoute':
        return 'purple';
      case 'inProgress':
        return 'indigo';
      case 'completed':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  bool get canRefund =>
      (status == 'completed' || status == 'cancelled') &&
      !isRefunded &&
      paymentIntentId != null;

  factory AdminReservation.fromJson(Map<String, dynamic> json) {
    return AdminReservation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      departureTime: DateTime.tryParse(json['departureTime']?.toString() ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      totalPrice: _toDouble(json['totalPrice']),
      platformFee: _toDouble(json['platformFee']),
      workerPayout: _toDouble(json['workerPayout']),
      paymentStatus: json['paymentStatus']?.toString(),
      paymentIntentId: json['paymentIntentId']?.toString(),
      client: json['userId'] != null ? ReservationClient.fromJson(
          json['userId'] is Map ? json['userId'] : {'_id': json['userId']}
      ) : null,
      worker: json['workerId'] != null ? ReservationWorker.fromJson(
          json['workerId'] is Map ? json['workerId'] : {'_id': json['workerId']}
      ) : null,
      vehicle: json['vehicle'] != null ? ReservationVehicle.fromJson(
          json['vehicle'] is Map ? json['vehicle'] : {'_id': json['vehicle']}
      ) : null,
      parkingSpotNumber: json['parkingSpotNumber']?.toString(),
      notes: json['notes']?.toString(),
      serviceOptions: (json['serviceOptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      cancellationReason: json['cancellationReason']?.toString(),
      isRefunded: json['isRefunded'] ?? false,
      refundAmount: _toDouble(json['refundAmount']),
    );
  }
}

class ReservationClient {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;

  ReservationClient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
  });

  String get fullName => '$firstName $lastName';

  factory ReservationClient.fromJson(Map<String, dynamic> json) {
    return ReservationClient(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }
}

class ReservationWorker {
  final String id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final double? rating;

  ReservationWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.rating,
  });

  String get fullName => '$firstName $lastName';

  factory ReservationWorker.fromJson(Map<String, dynamic> json) {
    return ReservationWorker(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      rating: _toDouble(json['workerProfile']?['averageRating']),
    );
  }
}

class ReservationVehicle {
  final String id;
  final String make;
  final String model;
  final String? color;
  final String? licensePlate;

  ReservationVehicle({
    required this.id,
    required this.make,
    required this.model,
    this.color,
    this.licensePlate,
  });

  String get displayName => '$make $model';

  factory ReservationVehicle.fromJson(Map<String, dynamic> json) {
    return ReservationVehicle(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      color: json['color']?.toString(),
      licensePlate: json['licensePlate']?.toString(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
