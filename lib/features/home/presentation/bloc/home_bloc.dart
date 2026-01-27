import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/domain/usecases/get_reservations_usecase.dart';
import '../../domain/usecases/get_weather_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

/// BLoC de la page d'accueil.
/// Charge les données utilisateur, la météo et les prochaines réservations en parallèle.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCurrentUserUseCase getCurrentUser;
  final GetWeatherUseCase getWeather;
  final GetReservationsUseCase getReservations;

  HomeBloc({
    required this.getCurrentUser,
    required this.getWeather,
    required this.getReservations,
  }) : super(const HomeState()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshWeather>(_onRefreshWeather);
    on<RefreshReservations>(_onRefreshReservations);
  }

  /// Charge toutes les données de la page d'accueil (utilisateur, météo, réservations).
  /// Collecte les erreurs individuelles sans bloquer les autres chargements.
  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Exécution séquentielle pour éviter les problèmes de typage
      final userResult = await getCurrentUser();
      final weatherResult = await getWeather();
      final reservationsResult = await getReservations(upcoming: true);

      // Collecter les erreurs
      final errors = <String>[];

      final user = userResult.fold(
        (failure) {
          errors.add('Erreur utilisateur: ${failure.message}');
          return null;
        },
        (user) => user,
      );

      final weather = weatherResult.fold(
        (failure) {
          errors.add('Erreur météo: ${failure.message}');
          return null;
        },
        (weather) => weather,
      );

      final reservations = reservationsResult.fold(
        (failure) {
          errors.add('Erreur réservations: ${failure.message}');
          return <Reservation>[];
        },
        (reservations) => reservations,
      );

      emit(state.copyWith(
        isLoading: false,
        user: user,
        weather: weather,
        upcomingReservations: reservations,
        errorMessage: errors.isNotEmpty ? errors.join('\n') : null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur inattendue: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<HomeState> emit,
  ) async {
    final weatherResult = await getWeather();

    weatherResult.fold(
      (failure) {
        emit(state.copyWith(
          errorMessage: 'Erreur météo: ${failure.message}',
        ));
      },
      (weather) {
        emit(state.copyWith(weather: weather, clearError: true));
      },
    );
  }

  Future<void> _onRefreshReservations(
    RefreshReservations event,
    Emitter<HomeState> emit,
  ) async {
    final reservationsResult = await getReservations(upcoming: true);

    reservationsResult.fold(
      (failure) {
        emit(state.copyWith(
          errorMessage: 'Erreur réservations: ${failure.message}',
        ));
      },
      (reservations) {
        emit(state.copyWith(
          upcomingReservations: reservations,
          clearError: true,
        ));
      },
    );
  }
}
