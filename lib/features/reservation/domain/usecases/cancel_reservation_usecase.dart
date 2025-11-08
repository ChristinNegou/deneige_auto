import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/reservation_repository.dart';

class CancelReservationUseCase {
  final ReservationRepository repository;

  CancelReservationUseCase(this.repository);

  Future<Either<Failure, void>> call(String reservationId) async {
    return await repository.cancelReservation(reservationId);
  }
}