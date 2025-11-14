import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vehicle.dart';
import '../repositories/reservation_repository.dart';

class GetVehiclesUseCase {
  final ReservationRepository repository;

  GetVehiclesUseCase(this.repository);

  Future<Either<Failure, List<Vehicle>>> call() async {
    return await repository.getVehicles();
  }
}