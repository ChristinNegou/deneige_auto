import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_preferences.dart';
import '../repositories/settings_repository.dart';

class UpdatePreferencesUseCase {
  final SettingsRepository repository;

  UpdatePreferencesUseCase(this.repository);

  Future<Either<Failure, UserPreferences>> call(UserPreferences preferences) async {
    return await repository.updatePreferences(preferences);
  }
}
