
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reservation.dart';

/// Interface du repository pour la gestion des réservations
/// Suit le principe de Clean Architecture - Domain Layer
abstract class ReservationRepository {
  /// Récupère la liste des réservations
  ///
  /// [upcoming] - Si true, récupère uniquement les réservations à venir
  /// [userId] - ID de l'utilisateur pour filtrer ses réservations
  ///
  /// Retourne Either<Failure, List<Reservation>>
  Future<Either<Failure, List<Reservation>>> getReservations({
    bool? upcoming,
    String? userId,
  });

  /// Crée une nouvelle réservation
  Future<Either<Failure, Reservation>> createReservation(
      Reservation reservation,
      );

  /// Annule une réservation existante
  Future<Either<Failure, void>> cancelReservation(String reservationId);

  /// Récupère une réservation par son ID
  Future<Either<Failure, Reservation>> getReservationById(String id);

  /// Met à jour une réservation
  Future<Either<Failure, Reservation>> updateReservation(
      Reservation reservation,
      );
}