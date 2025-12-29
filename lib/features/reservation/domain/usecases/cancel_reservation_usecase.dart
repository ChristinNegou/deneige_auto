import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/reservation_repository.dart';
import '../../data/datasources/reservation_remote_datasource.dart'
    show CancellationResult;

class CancelReservationUseCase {
  final ReservationRepository repository;

  CancelReservationUseCase(this.repository);

  Future<Either<Failure, CancellationResult>> call(
    String reservationId, {
    String? reason,
  }) async {
    return await repository.cancelReservation(reservationId, reason: reason);
  }
}