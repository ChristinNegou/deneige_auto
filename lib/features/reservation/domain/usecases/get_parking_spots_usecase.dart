import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/parking_spot.dart';
import '../repositories/reservation_repository.dart';

class GetParkingSpotsUseCase {
  final ReservationRepository repository;

  GetParkingSpotsUseCase(this.repository);

  Future<Either<Failure, List<ParkingSpot>>> call({
    bool availableOnly = false,
  }) async {
    return await repository.getParkingSpots(availableOnly: availableOnly);
  }
}