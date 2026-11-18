import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:deneige_auto/core/constants/app_routes.dart';
import 'package:deneige_auto/features/auth/domain/entities/user.dart';
import 'package:deneige_auto/features/auth/presentation/screens/register_screen.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('parseBirthDate', () {
    test('lit une date JJ/MM/AAAA', () {
      expect(parseBirthDate('12/04/1990'), DateTime(1990, 4, 12));
    });

    test('refuse les dates incompletes ou impossibles', () {
      expect(parseBirthDate('12/04/19'), isNull);
      expect(parseBirthDate('31/02/2000'), isNull);
      expect(parseBirthDate('00/13/2000'), isNull);
    });
  });

  group('ageOn', () {
    test('compte les annees revolues', () {
      final birth = DateTime(2008, 11, 18);
      expect(ageOn(birth, DateTime(2026, 11, 17)), 17);
      expect(ageOn(birth, DateTime(2026, 11, 18)), 18);
    });
  });

  testWidgets('pose une question a la fois puis envoie tout a la verification',
      (tester) async {
    Map<String, dynamic>? sentArgs;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: const RegisterScreen(role: UserRole.snowWorker),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.phoneVerification) {
          sentArgs = settings.arguments as Map<String, dynamic>;
        }
        return MaterialPageRoute(builder: (_) => const SizedBox());
      },
    ));
    await tester.pump();

    Future<void> next() async {
      await tester.pump();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }

    // 1. Nom : seul le nom est demande.
    expect(find.text('Comment vous appelez-vous ?'), findsOneWidget);
    expect(find.text('1/6'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).at(0), 'Marie');
    await tester.enterText(find.byType(TextField).at(1), 'Tremblay');
    await next();

    // 2. Date de naissance : les barres obliques s'ajoutent, les mineurs sont refuses.
    expect(find.text('Quelle est votre date de naissance ?'), findsOneWidget);
    final minor = DateTime.now().year - 16;
    await tester.enterText(find.byType(TextField), '0101$minor');
    await tester.pump();
    expect(find.text('01/01/$minor'), findsOneWidget);
    await next();
    expect(find.text('Vous devez avoir au moins 18 ans pour créer un compte.'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField), '12041990');
    await next();

    // 3. Courriel.
    await tester.enterText(find.byType(TextField), 'pas-un-courriel');
    await next();
    expect(find.text('Quelle est votre adresse courriel ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'marie@example.com');
    await next();

    // 4. Telephone.
    expect(find.text('Quel est votre numéro de téléphone ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '514 555-0101');
    await next();

    // 5. Mot de passe.
    await tester.enterText(find.byType(TextField), 'Secret123');
    await next();

    // 6. Recapitulatif : le bouton attend l'acceptation des conditions.
    expect(find.text('Vérifiez vos informations'), findsOneWidget);
    expect(find.text('Marie Tremblay'), findsOneWidget);
    expect(find.text('12 avril 1990'), findsOneWidget);
    final create = find.widgetWithText(FilledButton, 'Créer mon compte');
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();

    expect(sentArgs, {
      'phoneNumber': '+15145550101',
      'email': 'marie@example.com',
      'password': 'Secret123',
      'firstName': 'Marie',
      'lastName': 'Tremblay',
      'dateOfBirth': '1990-04-12',
      'role': 'snowWorker',
    });
  });

  testWidgets('le retour revient a la question precedente', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: const RegisterScreen(role: UserRole.client),
    ));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'Marc');
    await tester.enterText(find.byType(TextField).at(1), 'Dupont');
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('2/6'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Comment vous appelez-vous ?'), findsOneWidget);
    expect(find.text('Marc'), findsOneWidget);
  });
}
