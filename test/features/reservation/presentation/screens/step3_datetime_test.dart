import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_bloc.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_event.dart';
import 'package:deneige_auto/features/reservation/presentation/screens/steps/step3_datetime.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';

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

  Future<void> pumpStep(WidgetTester tester, DateTime departure) async {
    bloc.add(SelectDateTime(departure));
    await tester.pump();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: const Step3DateTimeScreen(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows when the vehicle will be ready, without a green banner',
      (tester) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 7);
    await pumpStep(tester, tomorrow);

    expect(find.text('Véhicule prêt avant 06 h 30'), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('explains why a departure too soon is refused', (tester) async {
    await pumpStep(tester, DateTime.now().add(const Duration(minutes: 10)));

    expect(
      find.text('Choisissez une heure de départ au moins 60 min à l’avance.'),
      findsOneWidget,
    );
    expect(find.textContaining('Véhicule prêt avant'), findsNothing);
  });
}
