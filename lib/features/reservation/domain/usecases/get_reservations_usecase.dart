// lib/features/reservation/domain/usecases/get_reservations_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

class GetReservationsUseCase {
  final ReservationRepository repository;

  GetReservationsUseCase(this.repository);

  /// Récupère les réservations de l'utilisateur connecté
  /// [upcoming] : si true, récupère seulement les réservations à venir
  Future<Either<Failure, List<Reservation>>> call({
    bool upcoming = false,
  }) async {
    return await repository.getReservations(upcoming: upcoming);
  }
}