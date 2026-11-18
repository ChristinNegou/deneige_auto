import 'package:bloc_test/bloc_test.dart';
import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/features/reservation/domain/entities/reservation.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/reservation_list_bloc.dart';
import 'package:deneige_auto/features/reservation/presentation/pages/reservation_details_page.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/reservation_fixtures.dart';

class MockReservationListBloc
    extends MockBloc<ReservationListEvent, ReservationListState>
    implements ReservationListBloc {}

void main() {
  late MockReservationListBloc bloc;

  setUpAll(() => initializeDateFormatting('fr_CA'));
  setUp(() => bloc = MockReservationListBloc());

  Future<void> pumpDetails(WidgetTester tester, Reservation reservation) async {
    when(() => bloc.state)
        .thenReturn(ReservationListState(selectedReservation: reservation));
    // Ecran haut : toute la liste est construite
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: BlocProvider<ReservationListBloc>.value(
        value: bloc,
        child: ReservationDetailsView(reservationId: reservation.id),
      ),
    ));
    await tester.pump();
  }

  testWidgets('pending: plain details, amount paid, edit and cancel',
      (tester) async {
    await pumpDetails(
      tester,
      ReservationFixtures.createPending(
        serviceOptions: [ServiceOption.doorDeicing, ServiceOption.roofClearing],
        totalPrice: 33.63,
        snowDepthCm: 25,
      ).copyWith(paymentStatus: 'paid'),
    );

    expect(
        find.text('Déglaçage des portes, Déneigement du toit'), findsOneWidget);
    expect(find.text('20 à 30 cm'), findsOneWidget);
    expect(find.text('Prix payé'), findsOneWidget);
    expect(find.textContaining('33,63'), findsOneWidget);
    expect(find.text('Modifier la réservation'), findsOneWidget);
    expect(find.text('Annuler la réservation'), findsOneWidget);
    // Plus de fausse ventilation du prix ni de badge clignotant
    expect(find.textContaining('Déneigement de base'), findsNothing);
    expect(find.text('Signaler un problème'), findsNothing);
  });

  testWidgets('completed: rating prompt and problem report, no edit',
      (tester) async {
    await pumpDetails(
      tester,
      ReservationFixtures.createCompleted().copyWith(
          completedAt: DateTime.now().subtract(const Duration(hours: 2))),
    );

    expect(find.text('Modifier la réservation'), findsNothing);
    expect(find.text('Annuler la réservation'), findsNothing);
    expect(find.text('Signaler un problème'), findsOneWidget);
  });
}
