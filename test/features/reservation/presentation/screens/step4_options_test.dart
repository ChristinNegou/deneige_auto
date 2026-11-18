import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_bloc.dart';
import 'package:deneige_auto/features/reservation/presentation/bloc/new_reservation_event.dart';
import 'package:deneige_auto/features/reservation/presentation/screens/steps/step4_options.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';

import '../../../../mocks/mock_usecases.dart';

void main() {
  late NewReservationBloc bloc;

  setUp(() {
    bloc = NewReservationBloc(
      getVehicles: MockGetVehiclesUseCase(),
      getParkingSpots: MockGetParkingSpotsUseCase(),
      createReservation: MockCreateReservationUseCase(),
    );
  });

  tearDown(() => bloc.close());

  Future<void> pumpStep(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body:
            BlocProvider.value(value: bloc, child: const Step4OptionsScreen()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the 3 main options and reveals the others on demand',
      (tester) async {
    await pumpStep(tester);

    expect(find.text('Grattage des vitres'), findsOneWidget);
    expect(find.text('Déneigement du toit'), findsNothing);

    await tester.tap(find.text('Plus d’options (5)'));
    await tester.pumpAndSettle();

    expect(find.text('Déneigement du toit'), findsOneWidget);
    expect(find.text('Moins d’options'), findsOneWidget);
  });

  testWidgets('keeps secondary options open when one is already selected',
      (tester) async {
    bloc.add(const ToggleServiceOption(ServiceOption.roofClearing));
    await tester.pump();
    await pumpStep(tester);

    expect(find.text('Déneigement du toit'), findsOneWidget);
  });

  testWidgets('snow chips set and clear the depth', (tester) async {
    await pumpStep(tester);

    await tester.tap(find.text('20 à 30 cm'));
    await tester.pumpAndSettle();
    expect(bloc.state.snowDepthCm, 25);

    await tester.tap(find.text('Je ne sais pas'));
    await tester.pumpAndSettle();
    expect(bloc.state.snowDepthCm, isNull);
  });
}
