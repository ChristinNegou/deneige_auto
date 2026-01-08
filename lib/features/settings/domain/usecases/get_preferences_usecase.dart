import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_preferences.dart';
import '../repositories/settings_repository.dart';

class GetPreferencesUseCase {
  final SettingsRepository repository;

  GetPreferencesUseCase(this.repository);

  Future<Either<Failure, UserPreferences>> call() async {
    return await repository.getPreferences();
  }
}
