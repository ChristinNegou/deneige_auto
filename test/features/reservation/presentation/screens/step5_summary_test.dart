import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_bloc.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_event.dart';
import 'package:deneige_auto/features/reservation/presentation/screens/steps/step5_summary.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';

import '../../../../fixtures/reservation_fixtures.dart';
import '../../../../mocks/mock_usecases.dart';

void main() {
  late NewReservationBloc bloc;

  setUpAll(() => initializeDateFormatting('fr_CA'));

  setUp(() {
    bloc = NewReservationBloc(
      getVehicles: MockGetVehiclesUseCase(),
      getParkingSpots: MockGetParkingSpotsUseCase(),
      createReservation: MockCreateReservationUseCase(),
    );
  });

  tearDown(() => bloc.close());

  Future<void> pumpSummary(WidgetTester tester) async {
    final now = DateTime.now();
    bloc
      ..add(SelectVehicle(ReservationFixtures.createVehicle()))
      ..add(const UpdateParkingSpotNumber('P5'))
      ..add(const SetLocationFromSuggestion(
          address: '12 Rue des Forges, Trois-Rivières',
          latitude: 46.34,
          longitude: -72.54))
      ..add(SelectDateTime(DateTime(now.year, now.month, now.day + 1, 8)))
      ..add(const ToggleServiceOption(ServiceOption.roofClearing))
      ..add(const UpdateSnowDepth(25));
    await tester.pump();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body:
            BlocProvider.value(value: bloc, child: const Step5SummaryScreen()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('lists each choice in plain words', (tester) async {
    await pumpSummary(tester);

    expect(find.text('Place P5'), findsOneWidget);
    expect(find.text('12 Rue des Forges, Trois-Rivières'), findsOneWidget);
    expect(find.text('Véhicule prêt avant 07 h 30'), findsOneWidget);
    expect(find.text('Déneigement du toit'), findsOneWidget);
    expect(find.text('20 à 30 cm'), findsOneWidget);
    expect(find.text('Modifier'), findsNWidgets(6));
  });

  testWidgets('only states what the service really does', (tester) async {
    await pumpSummary(tester);

    expect(
        find.text(
            'Annulation gratuite tant que le déneigeur n’est pas en route.'),
        findsOneWidget);
    expect(find.textContaining('2h avant'), findsNothing);
    expect(find.textContaining('retard'), findsNothing);
  });
}
