import 'package:deneige_auto/core/config/app_config.dart';
import 'package:deneige_auto/features/auth/presentation/screens/admin_web_notice_screen.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('un compte admin est envoyé vers le site admin', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: const AdminWebNoticeScreen(),
    ));

    expect(find.text('Espace administrateur'), findsOneWidget);
    expect(find.text('Ouvrir le site admin'), findsOneWidget);
    expect(find.text(AppConfig.adminWebUrl), findsOneWidget);
    expect(AppConfig.adminWebUrl, endsWith('/admin'));
  });
}
