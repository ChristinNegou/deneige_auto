/// Point d'entree de l'application Deneige Auto.
/// Initialise Firebase, Stripe, l'injection de dependances, le cache offline
/// et les notifications push avant de lancer le widget racine.
library;

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/push_notification_service.dart';
import 'core/cache/reservation_cache.dart';
import 'core/cache/sync_queue.dart';
import 'core/cache/network_status.dart';
import 'deneigeauto_app.dart';

import 'core/di/injection_container.dart';

/// Fonction main enveloppee dans [runZonedGuarded] pour capturer
/// toutes les erreurs non gerees et les envoyer a Crashlytics.
void main() {
  runZonedGuarded(
    () async {
      // Garantir l'initialisation des bindings Flutter
      WidgetsFlutterBinding.ensureInitialized();

      // Initialiser Firebase
      try {
        await Firebase.initializeApp();
        debugPrint('Firebase initialisé');

        // Initialiser Crashlytics
        await _initializeCrashlytics();

        // Initialiser Analytics
        await _initializeAnalytics();
      } catch (e, stack) {
        debugPrint('Erreur initialisation Firebase: $e');
        debugPrint('Stack: $stack');
      }

      // Initialiser Stripe
      try {
        Stripe.publishableKey = AppConfig.stripePublishableKey;
        await Stripe.instance.applySettings();
        debugPrint('Stripe initialisé');
      } catch (e, stack) {
        debugPrint('Erreur initialisation Stripe: $e');
        debugPrint('Stack: $stack');
      }

      // Initialiser les dépendances
      await di.initializeDependencies();

      // Initialiser les services de cache et offline
      try {
        final reservationCache = sl<ReservationCache>();
        await reservationCache.init();

        final syncQueue = sl<SyncQueue>();
        await syncQueue.init();

        final networkStatus = sl<NetworkStatus>();
        await networkStatus.init();

        debugPrint('Cache et services offline initialisés');
      } catch (e) {
        debugPrint('Erreur initialisation cache: $e');
      }

      // Initialiser les notifications push
      try {
        final pushService = sl<PushNotificationService>();
        await pushService.initialize();
        debugPrint('Push notifications initialisées');
      } catch (e) {
        debugPrint('Erreur initialisation push notifications: $e');
      }

      // Capturer les erreurs Flutter avec Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Capturer les erreurs asynchrones
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Lancer l'app
      runApp(const DeneigeAutoApp());
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    },
  );
}

/// Configure Firebase Crashlytics.
/// Desactive la collecte en mode debug pour eviter le bruit dans les rapports.
Future<void> _initializeCrashlytics() async {
  // Désactiver en mode debug pour éviter le bruit
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    debugPrint('Crashlytics désactivé en mode debug');
  } else {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    debugPrint('Crashlytics activé');
  }
}

/// Configure Firebase Analytics et enregistre l'ouverture de l'application.
/// La collecte est desactivee en mode debug.
Future<void> _initializeAnalytics() async {
  final analytics = FirebaseAnalytics.instance;

  // Activer la collecte de données
  await analytics.setAnalyticsCollectionEnabled(!kDebugMode);

  // Logger l'ouverture de l'app
  await analytics.logAppOpen();

  debugPrint('Analytics initialisé (collecte: ${!kDebugMode})');
}
