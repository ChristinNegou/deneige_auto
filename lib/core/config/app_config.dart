import 'package:flutter/foundation.dart';
import 'api_keys.dart';

/// Configuration centrale de l'application Deneige Auto.
/// Centralise les URLs d'API, les cles, les tarifs, les taxes du Quebec,
/// les regles metier et les feature flags selon l'environnement.
class AppConfig {
  // --- Environnement ---
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // --- Configuration API ---

  /// Retourne l'URL de base de l'API selon l'environnement actif.
  static String get apiBaseUrl {
    switch (environment) {
      case 'production':
        return 'https://deneigeauto-production.up.railway.app/api';
      case 'staging':
        return 'https://staging-api.deneige-auto.com/v1';
      default:
        // Pour téléphone physique, utilisez l'adresse IP locale du PC
        return 'http://192.168.40.228:3000/api';
    }
  }

  // --- Cles API externes ---
  static String get openWeatherMapApiKey => ApiKeys.openWeatherMapApiKey;

  // --- Debug & Logging ---
  static bool get enableLogging => kDebugMode || !isProduction;
  static bool get enablePerformanceLogging => kDebugMode;

  // --- Informations de l'application ---
  static const String appName = 'Dénéige-Auto';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // --- Localisation geographique par defaut ---
  static const String defaultCity = 'Trois-Rivières';
  static const String defaultCountryCode = 'CA';
  static const double targetLatitude = 46.3432;
  static const double targetLongitude = -72.5476;

  /// Clé API OpenWeatherMap (GRATUIT - 1000 appels/jour)
  /// Configurez via: flutter run --dart-define=OPENWEATHER_API_KEY=votre_cle
  static String get openWeatherApiKey => openWeatherMapApiKey;

  /// URL de base pour l'API OpenWeatherMap
  static const String openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  /// Coordonnées par défaut (Trois-Rivières, QC)
  static const double defaultLatitude = 46.3432;
  static const double defaultLongitude = -72.5476;

  // --- Regles metier ---
  static const int minReservationTimeMinutes =
      60; // 60 min avant l'heure de sortie
  static const int maxSimultaneousJobsPerWorker = 3;
  static const int lateToleranceMinutes = 15;
  static const double urgencyFeePercentage = 0.40; // +40% si < 45 min
  static const int urgencyThresholdMinutes =
      45; // 45 min avant l'heure de départ

  // --- Tarification (en dollars CAD) ---
  static const double basePrice = 15.0;
  static const double pricePerCm = 0.50;
  static const double iceRemovalSurcharge = 5.0;
  static const double doorDeicingSurcharge = 3.0;
  static const double wheelClearanceSurcharge = 4.0;
  static const double roofClearingSurcharge = 8.0;
  static const double saltSpreadingSurcharge = 5.0;
  static const double lightsCleaningSurcharge = 3.0;
  static const double perimeterClearanceSurcharge = 12.0;
  static const double exhaustCheckSurcharge = 2.0;

  // --- Taxes du Quebec ---
  static const double tpsRate = 0.05; // TPS - Taxe fédérale (5%)
  static const double tvqRate =
      0.09975; // TVQ - Taxe provinciale Québec (9.975%)

  // --- Frais supplementaires ---
  static const double serviceFee = 1.50; // Frais de service fixe
  static const double processingFeeRate = 0.029; // Frais de traitement (2.9%)
  static const double insuranceFee = 0.75; // Frais d'assurance

  // --- Abonnements ---
  static const double weeklySubscriptionPrice = 39.0;
  static const double monthlySubscriptionPrice = 129.0;
  static const double seasonalSubscriptionPrice = 399.0;

  // --- Timeouts & Limites ---
  static const int apiTimeoutSeconds = 30;
  static const int uploadTimeoutSeconds = 60;
  static const int maxPhotoSizeMB = 5;
  static const int photosPerJob = 2; // avant/après

  // --- Firebase ---
  static String get firebaseApiKey {
    return const String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: '',
    );
  }

  static const String firebaseProjectId = 'deneigeauto';

  // --- Stripe (paiement) ---
  static String get stripePublishableKey {
    // Le backend utilise sk_live, donc on doit utiliser pk_live
    return ApiKeys.stripePublishableKeyLive;
  }

  // --- Google Maps ---
  static String get googleMapsApiKey => ApiKeys.googleMapsApiKey;

  /// Vérifie que les clés API critiques sont configurées
  static void validateConfiguration() {
    if (!ApiKeys.isConfigured && isProduction) {
      throw Exception(
        'Configuration incomplète! Clés manquantes: ${ApiKeys.missingKeys.join(", ")}\n'
        'Utilisez --dart-define pour configurer les clés API.',
      );
    }
  }

  // --- Feature Flags ---
  static bool get enableWeatherAPI => true;
  static bool get enableChatFeature => false; // V2
  static bool get enableFamilySharing => false; // V2
  static bool get enableMultiBuilding => false; // V2

  // --- Identifiants App Store / Play Store ---
  static const String appStoreId = 'YOUR_APP_STORE_ID';
  static const String playStoreId = 'com.deneige.auto';
}

/// Roles possibles d'un utilisateur dans l'application.
enum UserRole {
  resident,
  worker,
  admin,
}

/// Statuts possibles d'une reservation de deneigement.
enum ReservationStatus {
  pending, // En attente d'assignation
  assigned, // Assignée à un déneigeur
  enRoute, // Déneigeur en route
  inProgress, // En cours
  completed, // Terminée
  cancelled, // Annulée
  late, // En retard
}

/// Types d'abonnement offerts aux clients.
enum SubscriptionType {
  none,
  weekly,
  monthly,
  seasonal,
}

/// Options de service supplementaires offertes lors d'une reservation.
enum ServiceOption {
  windowScraping, // Grattage vitres
  doorDeicing, // Déglaçage portes
  wheelClearance, // Dégagement roues
  roofClearing, // Déneigement du toit
  saltSpreading, // Épandage de sel
  lightsCleaning, // Nettoyage phares/feux
  perimeterClearance, // Dégagement périmètre complet
  exhaustCheck, // Vérification échappement
}

/// Chaines de caracteres statiques utilisees dans l'interface.
/// Note : ces chaines sont progressivement remplacees par le systeme l10n.
class AppStrings {
  // --- Auth ---
  static const String login = 'Connexion';
  static const String register = 'Inscription';
  static const String email = 'Courriel';
  static const String password = 'Mot de passe';
  static const String forgotPassword = 'Mot de passe oublié?';

  // --- Accueil ---
  static const String welcome = 'Bienvenue';
  static const String planReservation = 'Planifier un déneigement';
  static const String myReservations = 'Mes réservations';
  static const String weatherToday = 'Météo du jour';

  // --- Reservation ---
  static const String parkingSpot = 'Place de stationnement';
  static const String departureTime = 'Heure de départ';
  static const String vehiclePhoto = 'Photo du véhicule';
  static const String serviceOptions = 'Options de service';
  static const String estimatedPrice = 'Prix estimé';
  static const String confirmReservation = 'Confirmer la réservation';

  // --- Erreurs ---
  static const String networkError = 'Erreur de connexion';
  static const String unknownError = 'Une erreur est survenue';
  static const String validationError = 'Veuillez vérifier vos informations';
  static const String weatherLoadError = 'Impossible de charger la météo';
  static const String weatherUnavailable = 'Météo indisponible';
}
