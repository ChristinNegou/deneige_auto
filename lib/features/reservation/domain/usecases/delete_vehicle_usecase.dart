import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/reservation_repository.dart';

class DeleteVehicleUseCase {
  final ReservationRepository repository;

  DeleteVehicleUseCase(this.repository);

  Future<Either<Failure, void>> call(String vehicleId) async {
    return await repository.deleteVehicle(vehicleId);
  }
}
