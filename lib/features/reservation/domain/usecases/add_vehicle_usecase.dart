import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vehicle.dart';
import '../repositories/reservation_repository.dart';

class AddVehicleUseCase {
  final ReservationRepository repository;

  AddVehicleUseCase(this.repository);

  Future<Either<Failure, Vehicle>> call(AddVehicleParams params) async {
    return await repository.addVehicle(
      make: params.make,
      model: params.model,
      year: params.year,
      color: params.color,
      licensePlate: params.licensePlate,
      type: params.type,
      photoUrl: params.photoUrl,
      isDefault: params.isDefault,
    );
  }
}

class AddVehicleParams {
  final String make;
  final String model;
  final int year;
  final String color;
  final String licensePlate;
  final VehicleType type;
  final String? photoUrl;
  final bool isDefault;

  AddVehicleParams({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.type,
    this.photoUrl,
    this.isDefault = false,
  });
}