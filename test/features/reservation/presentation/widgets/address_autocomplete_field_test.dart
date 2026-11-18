import 'package:deneige_auto/core/services/address_search_service.dart';
import 'package:deneige_auto/features/reservation/presentation/widgets/address_autocomplete_field.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAddressSearchService extends Mock implements AddressSearchService {}

void main() {
  late MockAddressSearchService search;
  late TextEditingController controller;
  late FocusNode focus;

  const suggestion = AddressSuggestion(
    primary: '3746 Boulevard Jean-XXIII',
    secondary: 'Trois-Rivières, Québec G8Z 3X4',
    latitude: 46.34,
    longitude: -72.58,
  );

  setUp(() {
    search = MockAddressSearchService();
    GetIt.instance.registerSingleton<AddressSearchService>(search);
    controller = TextEditingController();
    focus = FocusNode();
  });

  tearDown(() {
    GetIt.instance.reset();
    controller.dispose();
    focus.dispose();
  });

  Future<void> pumpField(
    WidgetTester tester, {
    String? confirmed,
    required ValueChanged<AddressSuggestion> onSelected,
    required VoidCallback onEdited,
  }) {
    return tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: AddressAutocompleteField(
          controller: controller,
          focusNode: focus,
          confirmedAddress: confirmed,
          onSelected: onSelected,
          onEdited: onEdited,
        ),
      ),
    ));
  }

  testWidgets('shows suggestions while typing and returns the chosen one',
      (tester) async {
    when(() => search.search(any(),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            language: any(named: 'language')))
        .thenAnswer((_) async => [suggestion]);
    AddressSuggestion? picked;
    var edits = 0;
    await pumpField(tester,
        onSelected: (s) => picked = s, onEdited: () => edits++);

    await tester.enterText(find.byType(TextField), '3746 boul');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('3746 Boulevard Jean-XXIII'), findsOneWidget);
    expect(edits, greaterThan(0));

    await tester.tap(find.text('3746 Boulevard Jean-XXIII'));
    await tester.pump();

    expect(picked, suggestion);
    expect(controller.text, suggestion.fullAddress);
  });

  testWidgets('asks to pick a suggestion when text is typed but not chosen',
      (tester) async {
    when(() => search.search(any(),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        language: any(named: 'language'))).thenAnswer((_) async => []);
    await pumpField(tester, onSelected: (_) {}, onEdited: () {});

    await tester.enterText(find.byType(TextField), 'nimporte quoi');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Aucune adresse trouvée. Ajoutez le numéro ou la ville.'),
        findsOneWidget);
  });
}
