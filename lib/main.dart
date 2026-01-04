// Imports nécessaires pour Flutter
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// Import du widget racine de l'application
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/push_notification_service.dart';
import 'core/cache/reservation_cache.dart';
import 'core/cache/sync_queue.dart';
import 'core/cache/network_status.dart';
import 'deneigeauto_app.dart';

// Import de l'injection de dépendances
import 'core/di/injection_container.dart';

/// Point d'entrée principal de l'application Deneige Auto
/// Cette fonction est appelée au démarrage de l'application
void main() async {
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
  Stripe.publishableKey = AppConfig.stripePublishableKey;
  await Stripe.instance.applySettings();
  debugPrint('Stripe initialisé');

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

  // Lancer l'app avec zone d'erreur
  runZonedGuarded(
    () => runApp(const DeneigeAutoApp()),
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    },
  );
}

/// Initialise Firebase Crashlytics
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

/// Initialise Firebase Analytics
Future<void> _initializeAnalytics() async {
  final analytics = FirebaseAnalytics.instance;

  // Activer la collecte de données
  await analytics.setAnalyticsCollectionEnabled(!kDebugMode);

  // Logger l'ouverture de l'app
  await analytics.logAppOpen();

  debugPrint('Analytics initialisé (collecte: ${!kDebugMode})');
}
