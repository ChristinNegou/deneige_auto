// Imports nécessaires pour Flutter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Import du widget racine de l'application
import 'app.dart';

// Import de l'injection de dépendances
import 'core/di/injection_container.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/home/domain/usecases/get_weather_usecase.dart';
import 'features/reservation/domain/usecases/get_reservations_usecase.dart';

/// Point d'entrée principal de l'application Deneige Auto
/// Cette fonction est appelée au démarrage de l'application
void main() {
  // Méthode asynchrone pour permettre l'initialisation des services
  runZonedGuarded(
    () async {
      // S'assure que les bindings Flutter sont initialisés
      // Obligatoire avant toute opération asynchrone dans main()
      WidgetsFlutterBinding.ensureInitialized();

      // Configuration de la gestion des erreurs Flutter
      // Capture toutes les erreurs du framework Flutter
      FlutterError.onError = (FlutterErrorDetails details) {
        // Affiche l'erreur dans la console en mode debug
        FlutterError.presentError(details);
        
        // En mode debug, afficher plus de détails
        if (kDebugMode) {
          print('Flutter Error: ${details.exception}');
          print('Stack trace: ${details.stack}');
        }
        
        // TODO: Envoyer les erreurs à un service de monitoring (ex: Sentry, Firebase Crashlytics)
        // Example: await reportErrorToService(details.exception, details.stack);
      };

      // Initialisation de toutes les dépendances (repositories, use cases, etc.)
      await initializeDependencies();

      // TODO: Initialiser les autres services nécessaires
      // Exemples de services à initialiser :
      // - await Firebase.initializeApp();
      // - await initializeLogger();
      // - await loadAppConfiguration();

      // Démarre l'application Flutter avec le widget racine
      runApp(const DeneigeAutoApp());
    },

    (error, stackTrace) {
      // Capture toutes les erreurs non gérées qui ne sont pas des erreurs Flutter
      // (erreurs Dart asynchrones, erreurs dans les zones, etc.)
      if (kDebugMode) {
        print('❌ Uncaught error: $error');
        print('📍 Stack trace: $stackTrace');
      }
      
      // TODO: Envoyer les erreurs critiques à un service de monitoring
      // Example: await reportCriticalError(error, stackTrace);
    },
  );
}