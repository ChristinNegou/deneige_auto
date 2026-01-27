import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../datasources/reservation_remote_datasource.dart';

export '../datasources/reservation_remote_datasource.dart'
    show CancellationResult, CancellationPolicy, CancellationPolicyItem;

/// Implémentation du repository de réservations.
/// Encapsule les appels au datasource distant et convertit les exceptions en Failure (Either).
class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationRemoteDataSource remoteDataSource;

  ReservationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() async {
    try {
      final vehicles = await remoteDataSource.getVehicles();
      return Right(vehicles);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ParkingSpot>>> getParkingSpots({
    bool availableOnly = false,
  }) async {
    try {
      final parkingSpots = await remoteDataSource.getParkingSpots(
        availableOnly: availableOnly,
      );
      return Right(parkingSpots);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Reservation>>> getReservations({
    bool? upcoming,
    String? userId,
  }) async {
    try {
      final reservations = await remoteDataSource.getReservations(
        upcoming: upcoming,
      );
      // Note: L'API filtre déjà par userId via l'authentification (req.user.id)
      // Ce filtre client-side est une sécurité supplémentaire optionnelle
      if (userId != null) {
        final filtered = reservations.where((r) => r.userId == userId).toList();
        return Right(filtered);
      }
      return Right(reservations);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Reservation>> createReservation({
    required String vehicleId,
    required String parkingSpotId,
    String? parkingSpotNumber,
    String? customLocation,
    required DateTime departureTime,
    required DateTime deadlineTime,
    required List<String> serviceOptions,
    int? snowDepthCm,
    required double totalPrice,
    required String paymentMethod,
    String? paymentIntentId,
    // Localisation GPS pour le système déneigeur
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final data = {
        'vehicleId': vehicleId,
        'parkingSpotId': parkingSpotId,
        if (parkingSpotNumber != null) 'parkingSpotNumber': parkingSpotNumber,
        if (customLocation != null) 'customLocation': customLocation,
        'departureTime': departureTime.toIso8601String(),
        'deadlineTime': deadlineTime.toIso8601String(),
        'serviceOptions': serviceOptions,
        'snowDepthCm': snowDepthCm,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
        // Ajouter les coordonnées GPS si disponibles
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      };

      final createdReservation = await remoteDataSource.createReservation(data);
      return Right(createdReservation);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Vehicle>> addVehicle({
    required String make,
    required String model,
    required int year,
    required String color,
    required String licensePlate,
    required VehicleType type,
    String? photoUrl,
    bool isDefault = false,
  }) async {
    try {
      final data = {
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'licensePlate': licensePlate,
        'type': type.name,
        'photoUrl': photoUrl,
        'isDefault': isDefault,
      };

      final response = await remoteDataSource.addVehicle(data);
      return Right(response);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CancellationResult>> cancelReservation(
    String reservationId, {
    String? reason,
  }) async {
    try {
      final result = await remoteDataSource.cancelReservation(
        reservationId,
        reason: reason,
      );
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CancellationPolicy>> getCancellationPolicy() async {
    try {
      final policy = await remoteDataSource.getCancellationPolicy();
      return Right(policy);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Reservation>> getReservationById(String id) async {
    try {
      final reservation = await remoteDataSource.getReservationById(id);
      return Right(reservation);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
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
  }) async {
    try {
      final data = {
        'vehicleId': vehicleId,
        'parkingSpotId': parkingSpotId,
        'departureTime': departureTime.toIso8601String(),
        'deadlineTime': deadlineTime.toIso8601String(),
        'serviceOptions': serviceOptions,
        'snowDepthCm': snowDepthCm,
        'totalPrice': totalPrice,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      };

      final updatedReservation =
          await remoteDataSource.updateReservation(reservationId, data);
      return Right(updatedReservation);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> rateReservation({
    required String reservationId,
    required int rating,
    String? review,
  }) async {
    try {
      final result = await remoteDataSource.rateReservation(
        reservationId: reservationId,
        rating: rating,
        review: review,
      );
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getReservationRating(
      String reservationId) async {
    try {
      final result = await remoteDataSource.getReservationRating(reservationId);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> addTip({
    required String reservationId,
    required double amount,
  }) async {
    try {
      final result = await remoteDataSource.addTip(
        reservationId: reservationId,
        amount: amount,
      );
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVehicle(String vehicleId) async {
    try {
      await remoteDataSource.deleteVehicle(vehicleId);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadVehiclePhoto({
    required String vehicleId,
    required String photoPath,
  }) async {
    try {
      final photoUrl = await remoteDataSource.uploadVehiclePhoto(
        vehicleId: vehicleId,
        photoPath: photoPath,
      );
      return Right(photoUrl);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }
}
