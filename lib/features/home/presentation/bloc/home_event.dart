// ============= home_event.dart =============
import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class RefreshWeather extends HomeEvent {}

class RefreshReservations extends HomeEvent {}