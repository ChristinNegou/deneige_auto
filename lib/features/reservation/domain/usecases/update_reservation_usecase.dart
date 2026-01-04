import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/config/app_config.dart';
import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class UpdateReservationUseCase {
  final ReservationRepository repository;

  UpdateReservationUseCase(this.repository);

  Future<Either<Failure, Reservation>> call(
      UpdateReservationParams params) async {
    // Validation supplémentaire côté domaine
    final validation = _validateParams(params);
    if (validation != null) {
      return Left(ValidationFailure(message: validation));
    }

    // Appeler le repository
    return await repository.updateReservation(
      reservationId: params.reservationId,
      vehicleId: params.vehicleId,
      parkingSpotId: params.parkingSpotId,
      departureTime: params.departureTime,
      deadlineTime: params.deadlineTime,
      serviceOptions: params.serviceOptions.map((e) => e.name).toList(),
      snowDepthCm: params.snowDepthCm,
      totalPrice: params.totalPrice,
      latitude: params.latitude,
      longitude: params.longitude,
      address: params.address,
    );
  }

  String? _validateParams(UpdateReservationParams params) {
    final now = DateTime.now();
    final minTime =
        now.add(Duration(minutes: AppConfig.minReservationTimeMinutes));

    if (params.departureTime.isBefore(minTime)) {
      return 'Le départ doit être dans au moins ${AppConfig.minReservationTimeMinutes} minutes';
    }

    if (params.totalPrice <= 0) {
      return 'Le prix doit être supérieur à 0';
    }

    return null;
  }
}

class UpdateReservationParams {
  final String reservationId;
  final String vehicleId;
  final String parkingSpotId;
  final DateTime departureTime;
  final DateTime deadlineTime;
  final List<ServiceOption> serviceOptions;
  final int? snowDepthCm;
  final double totalPrice;
  final double? latitude;
  final double? longitude;
  final String? address;

  UpdateReservationParams({
    required this.reservationId,
    required this.vehicleId,
    required this.parkingSpotId,
    required this.departureTime,
    required this.deadlineTime,
    required this.serviceOptions,
    this.snowDepthCm,
    required this.totalPrice,
    this.latitude,
    this.longitude,
    this.address,
  });
}
