import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/user_preferences_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserPreferences>> getPreferences() async {
    try {
      final preferences = await remoteDataSource.getPreferences();
      return Right(preferences);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> updatePreferences(
      UserPreferences preferences) async {
    try {
      final model = UserPreferencesModel.fromEntity(preferences);
      final result = await remoteDataSource.updatePreferences(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(String password) async {
    try {
      await remoteDataSource.deleteAccount(password);
      return const Right(null);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Mot de passe incorrect')) {
        return Left(AuthFailure(message: message));
      }
      return Left(ServerFailure(message: message));
    }
  }
}
