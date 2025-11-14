import '../../../../core/config/app_config.dart';
import '../entities/parking_spot.dart';
import '../entities/reservation.dart';
import '../entities/vehicle.dart';

abstract class GetVehiclesUseCase {
  Future<Either<Failure, List<Vehicle>>> call();
}

abstract class GetParkingSpotsUseCase {
  Future<Either<Failure, List<ParkingSpot>>> call({bool availableOnly});
}

abstract class CreateReservationUseCase {
  Future<Either<Failure, Reservation>> call(CreateReservationParams params);
}

class CreateReservationParams {
  final String vehicleId;
  final String parkingSpotId;
  final DateTime departureTime;
  final DateTime deadlineTime;
  final List<ServiceOption> serviceOptions;
  final int? snowDepthCm;
  final double totalPrice;
  final String paymentMethod;

  CreateReservationParams({
    required this.vehicleId,
    required this.parkingSpotId,
    required this.departureTime,
    required this.deadlineTime,
    required this.serviceOptions,
    this.snowDepthCm,
    required this.totalPrice,
    required this.paymentMethod,
  });
}

// Either from dartz package
class Either<L, R> {
  final L? _left;
  final R? _right;

  Either.left(this._left) : _right = null;
  Either.right(this._right) : _left = null;

  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    if (_left != null) return onLeft(_left as L);
    return onRight(_right as R);
  }
}

class Failure {
  final String message;
  Failure(this.message);
}