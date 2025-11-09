// ============= home_state.dart =============
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart' as auth_entities;
import '../../../reservation/domain/entities/weather.dart';
import '../../../reservation/domain/entities/reservation.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final auth_entities.User? user;
  final Weather? weather;
  final List<Reservation> upcomingReservations;
  final String? errorMessage;

  const HomeState({
    this.isLoading = false,
    this.user,
    this.weather,
    this.upcomingReservations = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    bool? isLoading,
    auth_entities.User? user,
    bool clearUser = false,
    Weather? weather,
    bool clearWeather = false,
    List<Reservation>? upcomingReservations,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      weather: clearWeather ? null : (weather ?? this.weather),
      upcomingReservations: upcomingReservations ?? this.upcomingReservations,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    user,
    weather,
    upcomingReservations,
    errorMessage,
  ];
}