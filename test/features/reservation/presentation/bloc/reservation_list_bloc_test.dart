import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/reservation/data/datasources/reservation_remote_datasource.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/reservation_list_bloc.dart';

import '../../../../mocks/mock_usecases.dart';
import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late ReservationListBloc bloc;
  late MockGetReservationsUseCase mockGetReservations;
  late MockGetReservationByIdUseCase mockGetReservationById;
  late MockCancelReservationUseCase mockCancelReservation;

  setUp(() {
    mockGetReservations = MockGetReservationsUseCase();
    mockGetReservationById = MockGetReservationByIdUseCase();
    mockCancelReservation = MockCancelReservationUseCase();
    bloc = ReservationListBloc(
      getReservations: mockGetReservations,
      getReservationById: mockGetReservationById,
      cancelReservation: mockCancelReservation,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ReservationListBloc', () {
    final tReservations = ReservationFixtures.createList(3);
    final tReservation = ReservationFixtures.createPending();

    group('LoadReservations', () {
      blocTest<ReservationListBloc, ReservationListState>(
        'emits [loading, loaded] when LoadReservations succeeds',
        build: () {
          when(() => mockGetReservations(upcoming: any(named: 'upcoming')))
              .thenAnswer((_) async => Right(tReservations));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadReservations()),
        expect: () => [
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', null),
        ],
        verify: (_) {
          verify(() => mockGetReservations(upcoming: false)).called(1);
        },
      );

      blocTest<ReservationListBloc, ReservationListState>(
        'emits [loading, error] when LoadReservations fails',
        build: () {
          when(() => mockGetReservations(upcoming: any(named: 'upcoming')))
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadReservations()),
        expect: () => [
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having(
                  (s) => s.errorMessage, 'errorMessage', serverFailure.message),
        ],
      );

      blocTest<ReservationListBloc, ReservationListState>(
        'loads upcoming only when upcomingOnly is true',
        build: () {
          when(() => mockGetReservations(upcoming: true))
              .thenAnswer((_) async => Right(tReservations));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadReservations(upcomingOnly: true)),
        verify: (_) {
          verify(() => mockGetReservations(upcoming: true)).called(1);
        },
      );
    });

    group('RefreshReservations', () {
      blocTest<ReservationListBloc, ReservationListState>(
        'emits updated reservations when RefreshReservations succeeds',
        build: () {
          when(() => mockGetReservations(upcoming: false))
              .thenAnswer((_) async => Right(tReservations));
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshReservations()),
        expect: () => [
          isA<ReservationListState>()
              .having((s) => s.errorMessage, 'errorMessage', null),
        ],
      );

      blocTest<ReservationListBloc, ReservationListState>(
        'emits error when RefreshReservations fails',
        build: () {
          when(() => mockGetReservations(upcoming: false))
              .thenAnswer((_) async => const Left(networkFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshReservations()),
        expect: () => [
          isA<ReservationListState>().having(
              (s) => s.errorMessage, 'errorMessage', networkFailure.message),
        ],
      );
    });

    group('LoadReservationById', () {
      blocTest<ReservationListBloc, ReservationListState>(
        'emits selectedReservation when LoadReservationById succeeds',
        build: () {
          when(() => mockGetReservationById('reservation-123'))
              .thenAnswer((_) async => Right(tReservation));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadReservationById('reservation-123')),
        expect: () => [
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.selectedReservation, 'selectedReservation',
                  isNotNull),
        ],
      );

      blocTest<ReservationListBloc, ReservationListState>(
        'emits error when LoadReservationById fails',
        build: () {
          when(() => mockGetReservationById('invalid-id'))
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadReservationById('invalid-id')),
        expect: () => [
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having(
                  (s) => s.errorMessage, 'errorMessage', serverFailure.message),
        ],
      );
    });

    group('CancelReservationEvent', () {
      final tCancellationResult = CancellationResult(
        success: true,
        message: 'Reservation annulee',
        reservationId: 'reservation-123',
        previousStatus: 'pending',
        originalPrice: 25.0,
        cancellationFeePercent: 0.0,
        cancellationFeeAmount: 0.0,
        refundAmount: 25.0,
      );

      blocTest<ReservationListBloc, ReservationListState>(
        'emits success when CancelReservationEvent succeeds',
        build: () {
          when(() => mockCancelReservation('reservation-123',
                  reason: any(named: 'reason')))
              .thenAnswer((_) async => Right(tCancellationResult));
          return bloc;
        },
        act: (bloc) => bloc.add(
            const CancelReservationEvent('reservation-123', reason: 'Test')),
        expect: () => [
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.successMessage, 'successMessage', isNotNull)
              .having((s) => s.lastCancellationResult, 'lastCancellationResult',
                  isNotNull),
        ],
      );

      blocTest<ReservationListBloc, ReservationListState>(
        'emits error when CancelReservationEvent fails',
        build: () {
          when(() => mockCancelReservation('reservation-123',
                  reason: any(named: 'reason')))
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const CancelReservationEvent('reservation-123')),
        expect: () => [
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having(
                  (s) => s.errorMessage, 'errorMessage', serverFailure.message),
        ],
      );
    });

    group('LoadAllReservations', () {
      blocTest<ReservationListBloc, ReservationListState>(
        'emits all reservations when LoadAllReservations succeeds',
        build: () {
          when(() => mockGetReservations(upcoming: false))
              .thenAnswer((_) async => Right(tReservations));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAllReservations()),
        expect: () => [
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<ReservationListState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', null),
        ],
      );
    });
  });
}
