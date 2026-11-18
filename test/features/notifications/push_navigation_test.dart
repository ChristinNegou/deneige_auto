import 'package:deneige_auto/core/constants/app_routes.dart';
import 'package:deneige_auto/features/notifications/domain/entities/notification.dart';
import 'package:deneige_auto/features/notifications/services/notification_navigation_service.dart';
import 'package:deneige_auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationFromPush', () {
    test('rebuilds the notification from the push data', () {
      final n = NotificationNavigationService.notificationFromPush({
        'notificationId': 'n1',
        'type': 'searchingWorker',
        'reservationId': 'r1',
        'title': 'Nous cherchons encore un déneigeur',
        'body': 'Aucun déneigeur n’a encore accepté.',
      });

      expect(n.type, NotificationType.searchingWorker);
      expect(n.reservationId, 'r1');
      expect(n.title, 'Nous cherchons encore un déneigeur');
      expect(n.message, 'Aucun déneigeur n’a encore accepté.');
    });

    test('keeps the dispute to open', () {
      final n = NotificationNavigationService.notificationFromPush(
          {'type': 'dispute', 'disputeId': 'd42'});
      expect(n.metadata?['disputeId'], 'd42');
    });
  });

  group('openFromPush', () {
    Future<List<RouteSettings>> tap(
        WidgetTester tester, Map<String, dynamic> data) async {
      final opened = <RouteSettings>[];
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: key,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const SizedBox(),
        onGenerateRoute: (settings) {
          opened.add(settings);
          return MaterialPageRoute(builder: (_) => const SizedBox());
        },
      ));
      await NotificationNavigationService()
          .openFromPush(key.currentContext!, data);
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('a new job opens the jobs list for the worker', (tester) async {
      final opened =
          await tap(tester, {'type': 'urgentRequest', 'reservationId': 'r1'});
      expect(opened.single.name, AppRoutes.jobsList);
    });

    testWidgets('a client update opens the reservation', (tester) async {
      final opened =
          await tap(tester, {'type': 'searchingWorker', 'reservationId': 'r1'});
      expect(opened.single.name, AppRoutes.reservationDetails);
      expect(opened.single.arguments, 'r1');
    });

    testWidgets('a dispute notification opens the dispute', (tester) async {
      final opened = await tap(tester, {'type': 'dispute', 'disputeId': 'd42'});
      expect(opened.single.name, AppRoutes.disputeDetails);
      expect(opened.single.arguments, 'd42');
    });
  });
}
