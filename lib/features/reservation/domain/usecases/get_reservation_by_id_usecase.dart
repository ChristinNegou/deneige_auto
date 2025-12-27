import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class GetReservationByIdUseCase {
  final ReservationRepository repository;

  GetReservationByIdUseCase(this.repository);

  Future<Either<Failure, Reservation>> call(String reservationId) async {
    return await repository.getReservationById(reservationId);
  }
}
