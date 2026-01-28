import '../../../../core/config/app_config.dart' show AppConfig;
import '../../../../core/utils/time_utils.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.phoneNumber,
    super.photoUrl,
    required super.createdAt,
    required super.role,
    super.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: _parsePhotoUrl(json['photoUrl']),
      createdAt: TimeUtils.parseUtcToLocal(json['createdAt'] as String?),
      role: _parseRole(json['role'] as String?),
      isVerified: json['workerProfile']?['identityVerification']?['status'] ==
          'approved',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'role': role.toString().split('.').last,
    };
  }

  /// Parse photoUrl - prepend API base URL if relative
  static String? _parsePhotoUrl(dynamic url) {
    if (url == null) return null;
    final urlStr = url.toString();
    if (urlStr.isEmpty) return null;
    if (urlStr.startsWith('/')) {
      return '${AppConfig.apiBaseUrl}$urlStr';
    }
    return urlStr;
  }

  static UserRole _parseRole(String? role) {
    if (role == null) {
      return UserRole.client;
    }

    final roleStr = role.toLowerCase().replaceAll('_', '');

    switch (roleStr) {
      case 'snowworker':
      case 'deneigeur':
        return UserRole.snowWorker;
      case 'admin':
        return UserRole.admin;
      case 'client':
      default:
        return UserRole.client;
    }
  }
}
