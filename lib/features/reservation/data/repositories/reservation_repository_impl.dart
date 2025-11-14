
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../datasources/reservation_remote_datasource.dart';
import '../models/reservation_model.dart';

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
      // TODO: Filtrer par userId si nécessaire (côté client ou API)
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
    required DateTime departureTime,
    required DateTime deadlineTime,
    required List<String> serviceOptions,
    int? snowDepthCm,
    required double totalPrice,
    required String paymentMethod,
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
        'paymentMethod': paymentMethod,
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
  Future<Either<Failure, void>> cancelReservation(String reservationId) async {
    try {
      await remoteDataSource.cancelReservation(reservationId);
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
  Future<Either<Failure, Reservation>> getReservationById(String id) async {
    try {
      // TODO: Implémenter l'appel API pour récupérer une réservation par ID
      // Pour l'instant, on récupère toutes les réservations et on filtre
      final reservations = await remoteDataSource.getReservations();
      final reservation = reservations.firstWhere(
        (r) => r.id == id,
        orElse: () => throw ServerException(
          message: 'Réservation non trouvée',
          statusCode: 404,
        ),
      );
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
  Future<Either<Failure, Reservation>> updateReservation(
    Reservation reservation,
  ) async {
    try {
      // TODO: Implémenter l'appel API pour mettre à jour une réservation
      // Pour l'instant, on retourne une erreur
      return Left(ServerFailure(message: 'Mise à jour non implémentée'));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur inattendue: ${e.toString()}'));
    }
  }

  /// Convertit une entité Reservation en Map pour l'API
  Map<String, dynamic> _reservationToMap(Reservation reservation) {
    // Si c'est déjà un ReservationModel, utiliser sa méthode toJson
    if (reservation is ReservationModel) {
      return reservation.toJson();
    }

    // Sinon, créer manuellement le Map
    return {
      'userId': reservation.userId,
      'workerId': reservation.workerId,
      'parkingSpot': {
        'id': reservation.parkingSpot.id,
        'spotNumber': reservation.parkingSpot.spotNumber,
        'level': reservation.parkingSpot.level.name,
      },
      'vehicle': {
        'id': reservation.vehicle.id,
        'make': reservation.vehicle.make,
        'model': reservation.vehicle.model,
        'color': reservation.vehicle.color,
      },
      'departureTime': reservation.departureTime.toIso8601String(),
      'deadlineTime': reservation.deadlineTime?.toIso8601String(),
      'serviceOptions': reservation.serviceOptions.map((e) => e.name).toList(),
      'basePrice': reservation.basePrice,
      'totalPrice': reservation.totalPrice,
      'isPriority': reservation.isPriority,
      'snowDepthCm': reservation.snowDepthCm,
    };
  }
}