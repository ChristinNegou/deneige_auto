import 'package:equatable/equatable.dart';

enum UserRole { client, snowWorker, admin }

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final UserRole role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    required this.role,
  });

  @override
  List<Object?> get props =>
      [id, email, name, phoneNumber, photoUrl, createdAt, role];

  String? get firstName {
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }

  String? get lastName {
    final parts = name.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : null;
  }
}
