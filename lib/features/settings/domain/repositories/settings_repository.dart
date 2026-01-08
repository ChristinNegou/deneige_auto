import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_preferences.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserPreferences>> getPreferences();
  Future<Either<Failure, UserPreferences>> updatePreferences(UserPreferences preferences);
  Future<Either<Failure, void>> deleteAccount(String password);
}
