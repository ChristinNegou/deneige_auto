import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/config/app_config.dart';
import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class CreateReservationUseCase {
  final ReservationRepository repository;

  CreateReservationUseCase(this.repository);

  Future<Either<Failure, Reservation>> call(CreateReservationParams params) async {
    // Validation supplémentaire côté domaine
    final validation = _validateParams(params);
    if (validation != null) {
      return Left(ValidationFailure(message: validation));
    }

    // Appeler le repository
    return await repository.createReservation(
      vehicleId: params.vehicleId,
      parkingSpotId: params.parkingSpotId,
      departureTime: params.departureTime,
      deadlineTime: params.deadlineTime,
      serviceOptions: params.serviceOptions.map((e) => e.name).toList(),
      snowDepthCm: params.snowDepthCm,
      totalPrice: params.totalPrice,
      paymentMethod: params.paymentMethod,
      latitude: params.latitude,
      longitude: params.longitude,
      address: params.address,
    );
  }

  String? _validateParams(CreateReservationParams params) {
    final now = DateTime.now();
    final minTime = now.add(Duration(minutes: AppConfig.minReservationTimeMinutes));

    if (params.departureTime.isBefore(minTime)) {
      return 'Le départ doit être dans au moins ${AppConfig.minReservationTimeMinutes} minutes';
    }

    if (params.totalPrice <= 0) {
      return 'Le prix doit être supérieur à 0';
    }

    return null;
  }
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
  // Localisation GPS pour le système déneigeur
  final double? latitude;
  final double? longitude;
  final String? address;

  CreateReservationParams({
    required this.vehicleId,
    required this.parkingSpotId,
    required this.departureTime,
    required this.deadlineTime,
    required this.serviceOptions,
    this.snowDepthCm,
    required this.totalPrice,
    required this.paymentMethod,
    this.latitude,
    this.longitude,
    this.address,
  });
}