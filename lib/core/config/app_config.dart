import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // API Configuration
  static String get apiBaseUrl {
    switch (environment) {
      case 'production':
        return 'https://api.deneige-auto.com/v1';
      case 'staging':
        return 'https://staging-api.deneige-auto.com/v1';
      default:
        // Pour téléphone physique, utilisez l'adresse IP locale du PC
        return 'http://192.168.40.228:3000/v1';
    }
  }


  // OpenWeatherMap API
  static String get openWeatherMapApiKey {
    if (isProduction) {
      return 'ab72e143d388c56b44d4571dd67697ba';
    }
    return 'ab72e143d388c56b44d4571dd67697ba'; // TODO: Remplacer par votre clé API
  }

  // Debug
  static bool get enableLogging => kDebugMode || !isProduction;
  static bool get enablePerformanceLogging => kDebugMode;

  // App Info
  static const String appName = 'Dénéige-Auto';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Location
  static const String defaultCity = 'Trois-Rivières';
  static const String defaultCountryCode = 'CA';
  static const double targetLatitude = 46.3432;
  static const double targetLongitude = -72.5476;

  /// Clé API OpenWeatherMap (GRATUIT - 1000 appels/jour)
  /// Obtenez votre clé sur: https://openweathermap.org/api
  static const String openWeatherApiKey = 'ab72e143d388c56b44d4571dd67697ba'; // ← METTEZ VOTRE CLÉ ICI

  /// URL de base pour l'API OpenWeatherMap
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Coordonnées par défaut (Trois-Rivières, QC)
  static const double defaultLatitude = 46.3432;
  static const double defaultLongitude = -72.5476;



  // Business Rules
  static const int minReservationTimeMinutes = 60; // 60 min avant l'heure de sortie
  static const int maxSimultaneousJobsPerWorker = 3;
  static const int lateToleranceMinutes = 15;
  static const double urgencyFeePercentage = 0.40; // +40% si < 45 min

  // Pricing (en CAD $)
  static const double basePrice = 15.0;
  static const double pricePerCm = 0.50;
  static const double iceRemovalSurcharge = 5.0;
  static const double doorDeicingSurcharge = 3.0;
  static const double wheelClearanceSurcharge = 4.0;

  // Subscriptions
  static const double weeklySubscriptionPrice = 39.0;
  static const double monthlySubscriptionPrice = 129.0;
  static const double seasonalSubscriptionPrice = 399.0;

  // Timeouts & Limits
  static const int apiTimeoutSeconds = 30;
  static const int uploadTimeoutSeconds = 60;
  static const int maxPhotoSizeMB = 5;
  static const int photosPerJob = 2; // avant/après

  // Firebase
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
  static const String firebaseProjectId = 'deneige-auto';

  // Stripe
  static String get stripePublishableKey {
    if (isProduction) {
      return 'sk_test_51SPfZVKE0PkCEiT4YUctyxg2KKkLpcDBjAcsnHpl58H2tk0hji5xTsJU5kzqctl5MfCD7dDSPLN14Nvn8JXhs5wH00vVV8ajVM';
    }
    return 'pk_test_51SPfZVKE0PkCEiT4bfjgqbPnGY5yVhTyFvEj8vjV9FTeWerXmi4cyt2ARCu1yV2e2AxTYwUzCugCO0V6NNKGqIM300zV3czGnr';
  }

  // Google Maps
  static const String googleMapsApiKey = 'AIzaSyBYGaWXAeRC5ScUL8bM3emRobMMlVQ05VE';



  // Features Flags
  static bool get enableWeatherAPI => true;
  static bool get enableChatFeature => false; // V2
  static bool get enableFamilySharing => false; // V2
  static bool get enableMultiBuilding => false; // V2

  // App Store
  static const String appStoreId = 'YOUR_APP_STORE_ID';
  static const String playStoreId = 'com.deneige.auto';
}

// Enum pour les rôles utilisateurs
enum UserRole {
  resident,
  worker,
  admin,
}

// Enum pour les statuts de réservation
enum ReservationStatus {
  pending,      // En attente d'assignation
  assigned,     // Assignée à un déneigeur
  inProgress,   // En cours
  completed,    // Terminée
  cancelled,    // Annulée
  late,         // En retard
}

// Enum pour les types d'abonnement
enum SubscriptionType {
  none,
  weekly,
  monthly,
  seasonal,
}

// Enum pour les options de service
enum ServiceOption {
  windowScraping,    // Grattage vitres
  doorDeicing,       // Déglaçage portes
  wheelClearance,    // Dégagement roues
}

class AppStrings {
  // Auth
  static const String login = 'Connexion';
  static const String register = 'Inscription';
  static const String email = 'Courriel';
  static const String password = 'Mot de passe';
  static const String forgotPassword = 'Mot de passe oublié?';

  // Home
  static const String welcome = 'Bienvenue';
  static const String planReservation = 'Planifier un déneigement';
  static const String myReservations = 'Mes réservations';
  static const String weatherToday = 'Météo du jour';

  // Reservation
  static const String parkingSpot = 'Place de stationnement';
  static const String departureTime = 'Heure de départ';
  static const String vehiclePhoto = 'Photo du véhicule';
  static const String serviceOptions = 'Options de service';
  static const String estimatedPrice = 'Prix estimé';
  static const String confirmReservation = 'Confirmer la réservation';

  // Errors
  static const String networkError = 'Erreur de connexion';
  static const String unknownError = 'Une erreur est survenue';
  static const String validationError = 'Veuillez vérifier vos informations';
  static const String weatherLoadError = 'Impossible de charger la météo';
  static const String weatherUnavailable = 'Météo indisponible';
}