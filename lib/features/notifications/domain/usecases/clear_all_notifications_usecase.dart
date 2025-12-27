import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

class ClearAllNotificationsUseCase {
  final NotificationRepository repository;

  ClearAllNotificationsUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.clearAllNotifications();
  }
}
