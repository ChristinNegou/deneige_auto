class AdminUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final bool isSuspended;
  final DateTime? suspendedUntil;
  final String? suspensionReason;
  final DateTime createdAt;
  final WorkerProfile? workerProfile;
  final int reservationsCount;
  final double totalSpent;

  AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.isSuspended,
    this.suspendedUntil,
    this.suspensionReason,
    required this.createdAt,
    this.workerProfile,
    this.reservationsCount = 0,
    this.totalSpent = 0,
  });

  String get fullName => '$firstName $lastName';

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'snowWorker':
        return 'Déneigeur';
      case 'client':
        return 'Client';
      default:
        return role;
    }
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      role: json['role']?.toString() ?? 'client',
      isActive: json['isActive'] ?? true,
      isSuspended: json['isSuspended'] ?? false,
      suspendedUntil: json['suspendedUntil'] != null
          ? DateTime.tryParse(json['suspendedUntil'].toString())
          : null,
      suspensionReason: json['suspensionReason']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      workerProfile: json['workerProfile'] != null
          ? WorkerProfile.fromJson(json['workerProfile'])
          : null,
      reservationsCount: _toInt(json['reservationsCount'] ?? json['stats']?['totalReservations']),
      totalSpent: _toDouble(json['totalSpent'] ?? json['stats']?['totalSpent']),
    );
  }
}

class WorkerProfile {
  final bool isAvailable;
  final bool isVerified;
  final int totalJobsCompleted;
  final double totalEarnings;
  final double averageRating;
  final int totalRatingsCount;
  final int warningCount;

  WorkerProfile({
    required this.isAvailable,
    required this.isVerified,
    required this.totalJobsCompleted,
    required this.totalEarnings,
    required this.averageRating,
    required this.totalRatingsCount,
    required this.warningCount,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      isAvailable: json['isAvailable'] ?? false,
      isVerified: json['isVerified'] ?? false,
      totalJobsCompleted: _toInt(json['totalJobsCompleted']),
      totalEarnings: _toDouble(json['totalEarnings']),
      averageRating: _toDouble(json['averageRating']),
      totalRatingsCount: _toInt(json['totalRatingsCount']),
      warningCount: _toInt(json['warningCount']),
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

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
