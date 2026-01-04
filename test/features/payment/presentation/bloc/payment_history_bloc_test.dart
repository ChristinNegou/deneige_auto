import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:deneige_auto/features/payment/presentation/bloc/payment_history_bloc.dart';
import 'package:deneige_auto/features/payment/domain/entities/payment.dart';

import '../../../../mocks/mock_usecases.dart';
import '../../../../fixtures/payment_fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late PaymentHistoryBloc bloc;
  late MockGetPaymentHistoryUseCase mockGetPaymentHistory;

  setUp(() {
    mockGetPaymentHistory = MockGetPaymentHistoryUseCase();
    bloc = PaymentHistoryBloc(getPaymentHistory: mockGetPaymentHistory);
  });

  tearDown(() {
    bloc.close();
  });

  group('PaymentHistoryBloc', () {
    final tPayments = PaymentFixtures.createList(5);
    final tMixedPayments = PaymentFixtures.createMixedList();

    group('LoadPaymentHistory', () {
      blocTest<PaymentHistoryBloc, PaymentHistoryState>(
        'emits [loading, loaded] when LoadPaymentHistory succeeds',
        build: () {
          when(() => mockGetPaymentHistory())
              .thenAnswer((_) async => Right(tPayments));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadPaymentHistory()),
        expect: () => [
          isA<PaymentHistoryState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<PaymentHistoryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.payments.length, 'payments.length', 5)
              .having((s) => s.filteredPayments.length,
                  'filteredPayments.length', 5)
              .having((s) => s.errorMessage, 'errorMessage', null),
        ],
        verify: (_) {
          verify(() => mockGetPaymentHistory()).called(1);
        },
      );

      blocTest<PaymentHistoryBloc, PaymentHistoryState>(
        'emits [loading, error] when LoadPaymentHistory fails',
        build: () {
          when(() => mockGetPaymentHistory())
              .thenAnswer((_) async => const Left(serverFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadPaymentHistory()),
        expect: () => [
          isA<PaymentHistoryState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<PaymentHistoryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having(
                  (s) => s.errorMessage, 'errorMessage', serverFailure.message),
        ],
      );

      blocTest<PaymentHistoryBloc, PaymentHistoryState>(
        'emits empty list when no payments',
        build: () {
          when(() => mockGetPaymentHistory())
              .thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadPaymentHistory()),
        expect: () => [
          isA<PaymentHistoryState>()
              .having((s) => s.isLoading, 'isLoading', true),
          isA<PaymentHistoryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.payments, 'payments', isEmpty),
        ],
      );
    });

    group('RefreshPaymentHistory', () {
      blocTest<PaymentHistoryBloc, PaymentHistoryState>(
        'emits updated payments when RefreshPaymentHistory succeeds',
        build: () {
          when(() => mockGetPaymentHistory())
              .thenAnswer((_) async => Right(tPayments));
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshPaymentHistory()),
        expect: () => [
          isA<PaymentHistoryState>()
              .having((s) => s.payments.length, 'payments.length', 5)
              .having((s) => s.errorMessage, 'errorMessage', null),
        ],
      );

      blocTest<PaymentHistoryBloc, PaymentHistoryState>(
        'emits error when RefreshPaymentHistory fails',
        build: () {
          when(() => mockGetPaymentHistory())
              .thenAnswer((_) async => const Left(networkFailure));
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshPaymentHistory()),
        expect: () => [
          isA<PaymentHistoryState>().having(
              (s) => s.errorMessage, 'errorMessage', networkFailure.message),
        ],
      );
    });

    group('FilterPaymentsByStatus', () {
      blocTest<PaymentHistoryBloc, PaymentHistoryState>(
        'filters payments by succeeded status',
        build: () => bloc,
        seed: () => PaymentHistoryState(
          payments: tMixedPayments,
          filteredPayments: tMixedPayments,
        ),
        act: (bloc) =>
            bloc.add(FilterPaymentsByStatus(PaymentStatus.succeeded)),
        expect: () => [
          isA<PaymentHistoryState>()
              .having((s) => s.currentFilter, 'currentFilter',
                  PaymentStatus.succeeded)
              .having(
                  (s) => s.filteredPayments
                      .every((p) => p.status == PaymentStatus.succeeded),
                  'all succeeded',
                  true),
        ],
      );

      blocTest<PaymentHistoryBloc, PaymentHistoryState>(
        'shows all payments when filter is null',
        build: () => bloc,
        seed: () => PaymentHistoryState(
          payments: tMixedPayments,
          filteredPayments: [tMixedPayments.first],
        ),
        act: (bloc) => bloc.add(FilterPaymentsByStatus(null)),
        expect: () => [
          isA<PaymentHistoryState>().having((s) => s.filteredPayments.length,
              'filteredPayments.length', tMixedPayments.length),
        ],
      );

      blocTest<PaymentHistoryBloc, PaymentHistoryState>(
        'filters payments by failed status',
        build: () => bloc,
        seed: () => PaymentHistoryState(
          payments: tMixedPayments,
          filteredPayments: tMixedPayments,
        ),
        act: (bloc) => bloc.add(FilterPaymentsByStatus(PaymentStatus.failed)),
        expect: () => [
          isA<PaymentHistoryState>().having(
              (s) => s.currentFilter, 'currentFilter', PaymentStatus.failed),
        ],
      );
    });

    group('State statistics', () {
      test('totalSpent calculates correctly', () {
        final state = PaymentHistoryState(payments: tMixedPayments);
        final succeededPayments = tMixedPayments
            .where((p) => p.status == PaymentStatus.succeeded)
            .fold(0.0, (sum, p) => sum + p.amount);
        expect(state.totalSpent, succeededPayments);
      });

      test('transactionCount returns correct count', () {
        final state = PaymentHistoryState(payments: tMixedPayments);
        final count = tMixedPayments
            .where((p) => p.status == PaymentStatus.succeeded)
            .length;
        expect(state.transactionCount, count);
      });
    });
  });
}
