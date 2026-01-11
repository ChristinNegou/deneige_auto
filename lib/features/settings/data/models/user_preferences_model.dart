import '../../domain/entities/user_preferences.dart';

class UserPreferencesModel extends UserPreferences {
  const UserPreferencesModel({
    super.pushNotificationsEnabled,
    super.soundEnabled,
    super.darkThemeEnabled,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    final notificationSettings =
        json['notificationSettings'] as Map<String, dynamic>?;
    final userPreferences = json['userPreferences'] as Map<String, dynamic>?;

    return UserPreferencesModel(
      pushNotificationsEnabled:
          notificationSettings?['pushEnabled'] as bool? ?? true,
      soundEnabled: userPreferences?['soundEnabled'] as bool? ?? true,
      darkThemeEnabled: userPreferences?['darkThemeEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushNotificationsEnabled,
      'soundEnabled': soundEnabled,
      'darkThemeEnabled': darkThemeEnabled,
    };
  }

  factory UserPreferencesModel.fromEntity(UserPreferences entity) {
    return UserPreferencesModel(
      pushNotificationsEnabled: entity.pushNotificationsEnabled,
      soundEnabled: entity.soundEnabled,
      darkThemeEnabled: entity.darkThemeEnabled,
    );
  }
}
