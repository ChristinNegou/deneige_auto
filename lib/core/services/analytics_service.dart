import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service centralisé pour Firebase Analytics et Crashlytics
/// Utilisation: AnalyticsService.instance.logEvent(...)
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Observer pour la navigation (à utiliser avec MaterialApp)
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ==================== USER IDENTIFICATION ====================

  /// Définir l'ID utilisateur pour le tracking
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId ?? '');
    debugPrint('Analytics: User ID set to $userId');
  }

  /// Définir les propriétés utilisateur
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
    debugPrint('Analytics: User property $name = $value');
  }

  /// Définir le rôle utilisateur
  Future<void> setUserRole(String role) async {
    await setUserProperty(name: 'user_role', value: role);
    await _crashlytics.setCustomKey('user_role', role);
  }

  // ==================== AUTHENTICATION EVENTS ====================

  /// Connexion réussie
  Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method ?? 'email');
  }

  /// Inscription réussie
  Future<void> logSignUp({String? method}) async {
    await _analytics.logSignUp(signUpMethod: method ?? 'email');
  }

  /// Déconnexion
  Future<void> logLogout() async {
    await logEvent(name: 'logout');
    await setUserId(null);
  }

  // ==================== RESERVATION EVENTS ====================

  /// Nouvelle réservation créée
  Future<void> logReservationCreated({
    required String reservationId,
    required double price,
    List<String>? options,
  }) async {
    await _analytics.logEvent(
      name: 'reservation_created',
      parameters: {
        'reservation_id': reservationId,
        'price': price,
        'options': options?.join(',') ?? '',
        'currency': 'CAD',
      },
    );
  }

  /// Réservation complétée
  Future<void> logReservationCompleted({
    required String reservationId,
    required double price,
    double? tip,
  }) async {
    await _analytics.logPurchase(
      currency: 'CAD',
      value: price + (tip ?? 0),
      transactionId: reservationId,
    );

    await logEvent(
      name: 'reservation_completed',
      parameters: {
        'reservation_id': reservationId,
        'price': price,
        'tip': tip ?? 0,
      },
    );
  }

  /// Réservation annulée
  Future<void> logReservationCancelled({
    required String reservationId,
    String? reason,
    String? cancelledBy,
  }) async {
    await logEvent(
      name: 'reservation_cancelled',
      parameters: {
        'reservation_id': reservationId,
        'reason': reason ?? 'unknown',
        'cancelled_by': cancelledBy ?? 'user',
      },
    );
  }

  // ==================== WORKER EVENTS ====================

  /// Déneigeur accepte un job
  Future<void> logJobAccepted({required String jobId}) async {
    await logEvent(name: 'job_accepted', parameters: {'job_id': jobId});
  }

  /// Déneigeur commence un job
  Future<void> logJobStarted({required String jobId}) async {
    await logEvent(name: 'job_started', parameters: {'job_id': jobId});
  }

  /// Déneigeur termine un job
  Future<void> logJobCompleted({
    required String jobId,
    required double earnings,
  }) async {
    await logEvent(
      name: 'job_completed',
      parameters: {
        'job_id': jobId,
        'earnings': earnings,
      },
    );
  }

  /// Changement de disponibilité déneigeur
  Future<void> logWorkerAvailabilityChanged({required bool isAvailable}) async {
    await logEvent(
      name: 'worker_availability_changed',
      parameters: {'is_available': isAvailable},
    );
  }

  // ==================== PAYMENT EVENTS ====================

  /// Méthode de paiement ajoutée
  Future<void> logPaymentMethodAdded({String? type}) async {
    await logEvent(
      name: 'payment_method_added',
      parameters: {'type': type ?? 'card'},
    );
  }

  /// Paiement réussi
  Future<void> logPaymentSuccess({
    required double amount,
    required String transactionId,
  }) async {
    await _analytics.logPurchase(
      currency: 'CAD',
      value: amount,
      transactionId: transactionId,
    );
  }

  /// Paiement échoué
  Future<void> logPaymentFailed({
    required double amount,
    String? errorCode,
  }) async {
    await logEvent(
      name: 'payment_failed',
      parameters: {
        'amount': amount,
        'error_code': errorCode ?? 'unknown',
      },
    );
  }

  // ==================== NAVIGATION EVENTS ====================

  /// Écran affiché
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // ==================== GENERIC EVENTS ====================

  /// Logger un événement personnalisé
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    // Convertir les paramètres en types acceptés par Firebase
    final Map<String, Object>? safeParams = parameters?.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

    await _analytics.logEvent(
      name: name,
      parameters: safeParams,
    );
    debugPrint('Analytics: Event logged - $name');
  }

  // ==================== ERROR TRACKING ====================

  /// Enregistrer une erreur non fatale
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
    debugPrint('Crashlytics: Error recorded - $reason');
  }

  /// Ajouter un log de contexte (breadcrumb)
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Définir une clé personnalisée pour le contexte de crash
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value.toString());
  }

  /// Forcer un crash (pour tester - NE PAS UTILISER EN PRODUCTION)
  void forceCrash() {
    if (kDebugMode) {
      _crashlytics.crash();
    }
  }
}
