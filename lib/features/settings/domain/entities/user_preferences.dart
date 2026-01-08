import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final bool pushNotificationsEnabled;
  final bool soundEnabled;
  final bool darkThemeEnabled;

  const UserPreferences({
    this.pushNotificationsEnabled = true,
    this.soundEnabled = true,
    this.darkThemeEnabled = true,
  });

  UserPreferences copyWith({
    bool? pushNotificationsEnabled,
    bool? soundEnabled,
    bool? darkThemeEnabled,
  }) {
    return UserPreferences(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      darkThemeEnabled: darkThemeEnabled ?? this.darkThemeEnabled,
    );
  }

  @override
  List<Object?> get props => [
        pushNotificationsEnabled,
        soundEnabled,
        darkThemeEnabled,
      ];
}
