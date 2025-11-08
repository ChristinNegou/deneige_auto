import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class GetReservationsUseCase {
  final ReservationRepository repository;

  GetReservationsUseCase(this.repository);

  Future<Either<Failure, List<Reservation>>> call({
    bool? upcoming,
    String? userId,
  }) async {
    return await repository.getReservations(
      upcoming: upcoming,
      userId: userId,
    );
  }
}