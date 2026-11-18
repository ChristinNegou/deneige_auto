import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:deneige_auto/features/reservation/presentation/screens/reservation_success_screen.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_CA'));

  Future<void> pumpSuccess(WidgetTester tester, ReservationSuccessArgs args) {
    return tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: ReservationSuccessScreen(args: args),
    ));
  }

  testWidgets('confirms the payment and the key details', (tester) async {
    await pumpSuccess(
      tester,
      ReservationSuccessArgs(
        reservationId: '6afd4e60a7af02d61cb42574',
        amount: 31.47,
        departure: DateTime(2026, 11, 20, 8),
        readyBy: DateTime(2026, 11, 20, 7, 30),
        address: '12 Rue des Forges, Trois-Rivières',
      ),
    );

    expect(find.text('Réservation confirmée'), findsOneWidget);
    expect(find.textContaining('31,47'), findsOneWidget);
    expect(find.text('07 h 30'), findsOneWidget);
    expect(find.text('12 Rue des Forges, Trois-Rivières'), findsOneWidget);
    expect(find.text('#B42574'), findsOneWidget);
    expect(find.text('Voir ma réservation'), findsOneWidget);
  });

  testWidgets('step texts are not numbered twice', (tester) async {
    await pumpSuccess(
        tester, const ReservationSuccessArgs(reservationId: 'abc123'));

    expect(find.textContaining('1.'), findsNothing);
    expect(find.text('Un déneigeur accepte votre demande.'), findsOneWidget);
  });
}
