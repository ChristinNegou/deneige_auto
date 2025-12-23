import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reservation.dart';
import '../entities/vehicle.dart';
import '../entities/parking_spot.dart';

abstract class ReservationRepository {
  Future<Either<Failure, List<Vehicle>>> getVehicles();

  Future<Either<Failure, List<ParkingSpot>>> getParkingSpots({
    bool availableOnly = false,
  });

  Future<Either<Failure, Reservation>> createReservation({
    required String vehicleId,
    required String parkingSpotId,
    required DateTime departureTime,
    required DateTime deadlineTime,
    required List<String> serviceOptions,
    int? snowDepthCm,
    required double totalPrice,
    required String paymentMethod,
    // Localisation GPS pour le système déneigeur
    double? latitude,
    double? longitude,
    String? address,
  });

  Future<Either<Failure, Vehicle>> addVehicle({
    required String make,
    required String model,
    required int year,
    required String color,
    required String licensePlate,
    required VehicleType type,
    String? photoUrl,
    bool isDefault = false,
  });



  Future<Either<Failure, List<Reservation>>> getReservations({
    bool upcoming,
    String? userId,

  });

  Future<Either<Failure, Reservation>> getReservationById(String id);

  Future<Either<Failure, void>> cancelReservation(String id);

  Future<Either<Failure, Reservation>> updateReservation({
    required String reservationId,
    required String vehicleId,
    required String parkingSpotId,
    required DateTime departureTime,
    required DateTime deadlineTime,
    required List<String> serviceOptions,
    int? snowDepthCm,
    required double totalPrice,
    double? latitude,
    double? longitude,
    String? address,
  });

}