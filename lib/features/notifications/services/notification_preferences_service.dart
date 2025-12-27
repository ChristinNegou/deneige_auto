import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/notification.dart';

/// Service de gestion des préférences de notification
/// Inspiré des patterns Apple/Android pour les paramètres de notification
class NotificationPreferencesService {
  static const String _keyPrefix = 'notification_pref_';
  static const String _keyEnabled = '${_keyPrefix}enabled';
  static const String _keySoundEnabled = '${_keyPrefix}sound';
  static const String _keyVibrationEnabled = '${_keyPrefix}vibration';
  static const String _keyQuietHoursEnabled = '${_keyPrefix}quiet_hours';
  static const String _keyQuietHoursStart = '${_keyPrefix}quiet_start';
  static const String _keyQuietHoursEnd = '${_keyPrefix}quiet_end';
  static const String _keyBadgeEnabled = '${_keyPrefix}badge';
  static const String _keyPreviewEnabled = '${_keyPrefix}preview';

  final SharedPreferences _prefs;

  NotificationPreferencesService(this._prefs);

  // ===== Préférences globales =====

  /// Notifications activées globalement
  bool get isEnabled => _prefs.getBool(_keyEnabled) ?? true;
  Future<void> setEnabled(bool value) => _prefs.setBool(_keyEnabled, value);

  /// Son activé
  bool get isSoundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) => _prefs.setBool(_keySoundEnabled, value);

  /// Vibration activée
  bool get isVibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  Future<void> setVibrationEnabled(bool value) => _prefs.setBool(_keyVibrationEnabled, value);

  /// Badge sur l'icône de l'app
  bool get isBadgeEnabled => _prefs.getBool(_keyBadgeEnabled) ?? true;
  Future<void> setBadgeEnabled(bool value) => _prefs.setBool(_keyBadgeEnabled, value);

  /// Aperçu du contenu dans les notifications
  bool get isPreviewEnabled => _prefs.getBool(_keyPreviewEnabled) ?? true;
  Future<void> setPreviewEnabled(bool value) => _prefs.setBool(_keyPreviewEnabled, value);

  // ===== Mode silencieux (Quiet Hours) =====

  bool get isQuietHoursEnabled => _prefs.getBool(_keyQuietHoursEnabled) ?? false;
  Future<void> setQuietHoursEnabled(bool value) => _prefs.setBool(_keyQuietHoursEnabled, value);

  /// Heure de début du mode silencieux (format: "HH:mm")
  String get quietHoursStart => _prefs.getString(_keyQuietHoursStart) ?? '22:00';
  Future<void> setQuietHoursStart(String time) => _prefs.setString(_keyQuietHoursStart, time);

  /// Heure de fin du mode silencieux (format: "HH:mm")
  String get quietHoursEnd => _prefs.getString(_keyQuietHoursEnd) ?? '07:00';
  Future<void> setQuietHoursEnd(String time) => _prefs.setString(_keyQuietHoursEnd, time);

  /// Vérifie si on est actuellement en mode silencieux
  bool get isCurrentlyQuietHours {
    if (!isQuietHoursEnabled) return false;

    final now = DateTime.now();
    final startParts = quietHoursStart.split(':');
    final endParts = quietHoursEnd.split(':');

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    final startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
    var endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);

    // Si l'heure de fin est avant l'heure de début, c'est le lendemain
    if (endTime.isBefore(startTime)) {
      endTime = endTime.add(const Duration(days: 1));
    }

    // Si on est après minuit mais avant l'heure de fin
    if (now.hour < endHour || (now.hour == endHour && now.minute < endMinute)) {
      final adjustedStart = startTime.subtract(const Duration(days: 1));
      return now.isAfter(adjustedStart) && now.isBefore(endTime);
    }

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // ===== Préférences par type de notification =====

  /// Obtient si un type de notification est activé
  bool isTypeEnabled(NotificationType type) {
    return _prefs.getBool('${_keyPrefix}type_${type.name}') ?? true;
  }

  /// Active/désactive un type de notification
  Future<void> setTypeEnabled(NotificationType type, bool enabled) {
    return _prefs.setBool('${_keyPrefix}type_${type.name}', enabled);
  }

  /// Obtient la priorité personnalisée pour un type
  NotificationPriority? getTypeCustomPriority(NotificationType type) {
    final value = _prefs.getString('${_keyPrefix}priority_${type.name}');
    if (value == null) return null;
    return NotificationPriority.values.firstWhere(
      (p) => p.name == value,
      orElse: () => NotificationPriority.normal,
    );
  }

  /// Définit une priorité personnalisée pour un type
  Future<void> setTypeCustomPriority(NotificationType type, NotificationPriority? priority) {
    if (priority == null) {
      return _prefs.remove('${_keyPrefix}priority_${type.name}');
    }
    return _prefs.setString('${_keyPrefix}priority_${type.name}', priority.name);
  }

  // ===== Catégories de notifications =====

  /// Catégories pour regrouper les types de notifications
  static const Map<String, List<NotificationType>> categories = {
    'Réservations': [
      NotificationType.reservationAssigned,
      NotificationType.workerEnRoute,
      NotificationType.workStarted,
      NotificationType.workCompleted,
      NotificationType.reservationCancelled,
    ],
    'Paiements': [
      NotificationType.paymentSuccess,
      NotificationType.paymentFailed,
      NotificationType.refundProcessed,
    ],
    'Alertes': [
      NotificationType.weatherAlert,
      NotificationType.urgentRequest,
    ],
    'Communications': [
      NotificationType.workerMessage,
      NotificationType.systemNotification,
    ],
  };

  /// Active/désactive une catégorie entière
  Future<void> setCategoryEnabled(String category, bool enabled) async {
    final types = categories[category];
    if (types != null) {
      for (final type in types) {
        await setTypeEnabled(type, enabled);
      }
    }
  }

  /// Vérifie si une catégorie est entièrement activée
  bool isCategoryFullyEnabled(String category) {
    final types = categories[category];
    if (types == null) return false;
    return types.every((type) => isTypeEnabled(type));
  }

  /// Vérifie si une catégorie est partiellement activée
  bool isCategoryPartiallyEnabled(String category) {
    final types = categories[category];
    if (types == null) return false;
    final enabledCount = types.where((type) => isTypeEnabled(type)).length;
    return enabledCount > 0 && enabledCount < types.length;
  }

  // ===== Méthodes utilitaires =====

  /// Vérifie si une notification doit être affichée selon les préférences
  bool shouldShowNotification(AppNotification notification) {
    // Désactivé globalement?
    if (!isEnabled) return false;

    // Type désactivé?
    if (!isTypeEnabled(notification.type)) return false;

    // En mode silencieux? (sauf urgentes)
    if (isCurrentlyQuietHours && notification.priority != NotificationPriority.urgent) {
      return false;
    }

    return true;
  }

  /// Vérifie si le son doit être joué pour une notification
  bool shouldPlaySound(AppNotification notification) {
    if (!shouldShowNotification(notification)) return false;
    if (!isSoundEnabled) return false;
    if (isCurrentlyQuietHours && notification.priority != NotificationPriority.urgent) {
      return false;
    }
    return true;
  }

  /// Vérifie si la vibration doit être activée pour une notification
  bool shouldVibrate(AppNotification notification) {
    if (!shouldShowNotification(notification)) return false;
    if (!isVibrationEnabled) return false;
    if (isCurrentlyQuietHours && notification.priority != NotificationPriority.urgent) {
      return false;
    }
    return true;
  }

  /// Réinitialise toutes les préférences par défaut
  Future<void> resetToDefaults() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Exporte les préférences (pour backup/sync)
  Map<String, dynamic> exportPreferences() {
    final Map<String, dynamic> prefs = {};
    final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

    for (final key in keys) {
      prefs[key] = _prefs.get(key);
    }

    return prefs;
  }

  /// Importe les préférences (depuis backup/sync)
  Future<void> importPreferences(Map<String, dynamic> prefs) async {
    for (final entry in prefs.entries) {
      if (!entry.key.startsWith(_keyPrefix)) continue;

      final value = entry.value;
      if (value is bool) {
        await _prefs.setBool(entry.key, value);
      } else if (value is String) {
        await _prefs.setString(entry.key, value);
      } else if (value is int) {
        await _prefs.setInt(entry.key, value);
      }
    }
  }
}

/// Extension pour obtenir des informations sur les types de notification
extension NotificationTypeInfo on NotificationType {
  /// Description du type pour l'affichage dans les paramètres
  String get settingsDescription {
    switch (this) {
      case NotificationType.reservationAssigned:
        return 'Quand un déneigeur accepte votre demande';
      case NotificationType.workerEnRoute:
        return 'Quand le déneigeur est en route';
      case NotificationType.workStarted:
        return 'Quand le déneigement commence';
      case NotificationType.workCompleted:
        return 'Quand le déneigement est terminé';
      case NotificationType.reservationCancelled:
        return 'Quand une réservation est annulée';
      case NotificationType.paymentSuccess:
        return 'Confirmation de paiement réussi';
      case NotificationType.paymentFailed:
        return 'Alerte de paiement échoué';
      case NotificationType.refundProcessed:
        return 'Confirmation de remboursement';
      case NotificationType.weatherAlert:
        return 'Alertes météo neige';
      case NotificationType.urgentRequest:
        return 'Demandes urgentes';
      case NotificationType.workerMessage:
        return 'Messages du déneigeur';
      case NotificationType.systemNotification:
        return 'Mises à jour système';
    }
  }

  /// Indique si ce type est critique et ne devrait pas être désactivé
  bool get isCritical {
    return this == NotificationType.paymentFailed ||
        this == NotificationType.urgentRequest;
  }
}
