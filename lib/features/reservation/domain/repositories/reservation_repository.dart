import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reservation.dart';
import '../entities/vehicle.dart';
import '../entities/parking_spot.dart';
import '../../data/datasources/reservation_remote_datasource.dart'
    show CancellationResult, CancellationPolicy;

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

  Future<Either<Failure, CancellationResult>> cancelReservation(
    String id, {
    String? reason,
  });

  Future<Either<Failure, CancellationPolicy>> getCancellationPolicy();

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

  /// Noter un déneigeur après un job complété
  Future<Either<Failure, Map<String, dynamic>>> rateReservation({
    required String reservationId,
    required int rating,
    String? review,
  });

  /// Récupérer la note d'une réservation
  Future<Either<Failure, Map<String, dynamic>>> getReservationRating(
      String reservationId);

  /// Ajouter un pourboire à une réservation complétée
  Future<Either<Failure, Map<String, dynamic>>> addTip({
    required String reservationId,
    required double amount,
  });

  /// Supprimer un véhicule
  Future<Either<Failure, void>> deleteVehicle(String vehicleId);

  /// Upload vehicle photo
  Future<Either<Failure, String>> uploadVehiclePhoto({
    required String vehicleId,
    required String photoPath,
  });
}
