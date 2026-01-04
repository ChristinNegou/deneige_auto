import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/get_reservations_usecase.dart';
import 'package:deneige_auto/features/home/domain/usecases/get_weather_usecase.dart';
import 'package:deneige_auto/features/home/presentation/bloc/home_bloc.dart';
import 'package:deneige_auto/features/home/presentation/bloc/home_event.dart';
import 'package:deneige_auto/features/home/presentation/bloc/home_state.dart';
import 'package:deneige_auto/features/home/domain/entities/weather.dart';

import '../../../../fixtures/user_fixtures.dart';
import '../../../../fixtures/reservation_fixtures.dart';

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockGetWeatherUseCase extends Mock implements GetWeatherUseCase {}
class MockGetReservationsUseCase extends Mock implements GetReservationsUseCase {}

void main() {
  late HomeBloc bloc;
  late MockGetCurrentUserUseCase mockGetCurrentUser;
  late MockGetWeatherUseCase mockGetWeather;
  late MockGetReservationsUseCase mockGetReservations;

  setUp(() {
    mockGetCurrentUser = MockGetCurrentUserUseCase();
    mockGetWeather = MockGetWeatherUseCase();
    mockGetReservations = MockGetReservationsUseCase();

    bloc = HomeBloc(
      getCurrentUser: mockGetCurrentUser,
      getWeather: mockGetWeather,
      getReservations: mockGetReservations,
    );
  });

  tearDown(() {
    bloc.close();
  });

  Weather createWeather() {
    return Weather(
      location: 'Trois-Rivieres',
      temperature: -5.0,
      condition: 'Neige legere',
      conditionCode: 'snow',
      humidity: 85,
      windSpeed: 15.0,
      snowDepth: 10,
      iconUrl: 'https://example.com/icon.png',
      timestamp: DateTime(2024, 1, 15, 10, 0),
    );
  }

  group('HomeBloc', () {
    test('initial state should be HomeState with defaults', () {
      expect(bloc.state, const HomeState());
      expect(bloc.state.isLoading, false);
      expect(bloc.state.user, isNull);
      expect(bloc.state.weather, isNull);
      expect(bloc.state.upcomingReservations, isEmpty);
    });

    group('LoadHomeData', () {
      final tUser = UserFixtures.createClient();
      final tWeather = createWeather();
      final tReservations = ReservationFixtures.createList(2);

      blocTest<HomeBloc, HomeState>(
        'emits states with data when LoadHomeData succeeds',
        build: () {
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(() => mockGetWeather())
              .thenAnswer((_) async => Right(tWeather));
          when(() => mockGetReservations(upcoming: true))
              .thenAnswer((_) async => Right(tReservations));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadHomeData()),
        expect: () => [
          const HomeState(isLoading: true),
          isA<HomeState>().having((s) => s.isLoading, 'isLoading', false),
        ],
        verify: (bloc) {
          expect(bloc.state.user, tUser);
          expect(bloc.state.weather, tWeather);
          expect(bloc.state.upcomingReservations.length, 2);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits state with error when user fetch fails',
        build: () {
          when(() => mockGetCurrentUser()).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'User error')),
          );
          when(() => mockGetWeather())
              .thenAnswer((_) async => Right(tWeather));
          when(() => mockGetReservations(upcoming: true))
              .thenAnswer((_) async => Right(tReservations));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadHomeData()),
        verify: (bloc) {
          expect(bloc.state.user, isNull);
          expect(bloc.state.errorMessage, contains('Erreur'));
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits state with weather when weather fetch fails but others succeed',
        build: () {
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(() => mockGetWeather()).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Weather error')),
          );
          when(() => mockGetReservations(upcoming: true))
              .thenAnswer((_) async => Right(tReservations));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadHomeData()),
        verify: (bloc) {
          expect(bloc.state.user, tUser);
          expect(bloc.state.weather, isNull);
          expect(bloc.state.errorMessage, contains('météo'));
        },
      );
    });

    group('RefreshWeather', () {
      final tWeather = createWeather();

      blocTest<HomeBloc, HomeState>(
        'updates weather when RefreshWeather succeeds',
        build: () {
          when(() => mockGetWeather())
              .thenAnswer((_) async => Right(tWeather));
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshWeather()),
        verify: (bloc) {
          expect(bloc.state.weather, tWeather);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'sets error when RefreshWeather fails',
        build: () {
          when(() => mockGetWeather()).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Weather error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshWeather()),
        verify: (bloc) {
          expect(bloc.state.errorMessage, contains('météo'));
        },
      );
    });

    group('RefreshReservations', () {
      final tReservations = ReservationFixtures.createList(3);

      blocTest<HomeBloc, HomeState>(
        'updates reservations when RefreshReservations succeeds',
        build: () {
          when(() => mockGetReservations(upcoming: true))
              .thenAnswer((_) async => Right(tReservations));
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshReservations()),
        verify: (bloc) {
          expect(bloc.state.upcomingReservations.length, 3);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'sets error when RefreshReservations fails',
        build: () {
          when(() => mockGetReservations(upcoming: true)).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Reservations error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshReservations()),
        verify: (bloc) {
          expect(bloc.state.errorMessage, contains('réservations'));
        },
      );
    });
  });
}
