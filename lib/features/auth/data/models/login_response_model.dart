import '../../domain/entities/user.dart';
import 'user_model.dart';

class LoginResponseModel {
  final UserModel user;
  final String token;
  final String? refreshToken;

  const LoginResponseModel({
    required this.user,
    required this.token,
    this.refreshToken,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'refreshToken': refreshToken,
    };
  }
}