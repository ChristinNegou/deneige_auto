import 'package:equatable/equatable.dart';
import '../../../../core/config/app_config.dart';

/// Entity représentant un utilisateur
class User extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final UserRole role;
  final String? profileImageUrl;
  final SubscriptionType subscriptionType;
  final DateTime? subscriptionEndDate;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    this.subscriptionType = SubscriptionType.none,
    this.subscriptionEndDate,
    this.isEmailVerified = false,
    required this.createdAt,
    this.lastLoginAt,
  });

  String get fullName => '$firstName $lastName';

  bool get hasActiveSubscription {
    if (subscriptionType == SubscriptionType.none) return false;
    if (subscriptionEndDate == null) return false;
    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phoneNumber,
        role,
        profileImageUrl,
        subscriptionType,
        subscriptionEndDate,
        isEmailVerified,
        createdAt,
        lastLoginAt,
      ];
}
