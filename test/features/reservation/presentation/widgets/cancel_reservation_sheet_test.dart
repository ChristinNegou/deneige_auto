import 'package:dartz/dartz.dart';
import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/core/errors/failures.dart';
import 'package:deneige_auto/features/reservation/data/datasources/reservation_remote_datasource.dart';
import 'package:deneige_auto/features/reservation/domain/entities/reservation.dart';
import 'package:deneige_auto/features/reservation/domain/usecases/cancel_reservation_usecase.dart';
import 'package:deneige_auto/features/reservation/presentation/widgets/cancel_reservation_sheet.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../mocks/mock_usecases.dart';

void main() {
  late MockCancelReservationUseCase cancel;
  CancellationResult? returned;

  setUp(() {
    cancel = MockCancelReservationUseCase();
    GetIt.instance.registerSingleton<CancelReservationUseCase>(cancel);
    returned = null;
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> openSheet(WidgetTester tester, Reservation reservation) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => returned =
                await showCancelReservationSheet(context, reservation),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  CancellationResult result({double refund = 29.03}) => CancellationResult(
        success: true,
        message: 'ok',
        reservationId: 'r1',
        previousStatus: 'pending',
        originalPrice: 29.03,
        cancellationFeePercent: 0,
        cancellationFeeAmount: 0,
        refundAmount: refund,
      );

  testWidgets('announces a full refund before the worker is on the way',
      (tester) async {
    await openSheet(
        tester, ReservationFixtures.createPending(totalPrice: 29.03));

    expect(find.text('Annuler cette réservation ?'), findsOneWidget);
    expect(find.textContaining('29,03'), findsOneWidget);
    expect(find.textContaining('au complet'), findsOneWidget);
  });

  testWidgets('announces the 50% fee when the worker is on the way',
      (tester) async {
    await openSheet(
      tester,
      ReservationFixtures.createPending(totalPrice: 30)
          .copyWith(status: ReservationStatus.enRoute),
    );

    expect(find.textContaining('15,00'), findsOneWidget);
    expect(find.textContaining('50 %'), findsOneWidget);
  });

  testWidgets('sends the chosen reason and closes with the result',
      (tester) async {
    when(() => cancel(any(), reason: any(named: 'reason')))
        .thenAnswer((_) async => Right(result()));
    await openSheet(tester, ReservationFixtures.createPending());

    await tester.tap(find.text('J’ai déneigé moi-même'));
    await tester.tap(find.text('Annuler la réservation'));
    await tester.pumpAndSettle();

    verify(() => cancel('reservation-123', reason: 'J’ai déneigé moi-même'))
        .called(1);
    expect(returned?.refundAmount, 29.03);
    expect(find.text('Annuler cette réservation ?'), findsNothing);
  });

  testWidgets('keeps the sheet open and explains a server error',
      (tester) async {
    when(() => cancel(any(), reason: any(named: 'reason'))).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Erreur lors de l’annulation')));
    await openSheet(tester, ReservationFixtures.createPending());

    await tester.tap(find.text('Annuler la réservation'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur lors de l’annulation'), findsOneWidget);
    expect(find.text('Annuler cette réservation ?'), findsOneWidget);
    expect(returned, isNull);
  });
}
