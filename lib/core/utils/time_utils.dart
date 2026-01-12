/// Utilitaires pour la gestion du temps et des dates
class TimeUtils {
  TimeUtils._(); // Constructeur privé pour empêcher l'instanciation

  /// Parse une date ISO 8601 (UTC) et la convertit en heure locale
  /// Les dates du backend MongoDB sont en UTC, cette fonction assure
  /// la conversion correcte en heure locale de l'utilisateur
  static DateTime parseUtcToLocal(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }
    try {
      // DateTime.parse interprète les dates ISO comme UTC si elles ont un 'Z'
      // ou un offset, sinon comme local. On force la conversion en local.
      final parsed = DateTime.parse(dateString);
      // Si la date est déjà en UTC (termine par Z), convertir en local
      if (dateString.endsWith('Z') ||
          dateString.contains('+') ||
          dateString.contains('-', 10)) {
        return parsed.toLocal();
      }
      // Si pas de timezone info, on assume UTC et on convertit
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      ).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Parse une date ISO 8601 nullable, retourne null si invalide
  static DateTime? parseUtcToLocalOrNull(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      final parsed = DateTime.parse(dateString);
      if (dateString.endsWith('Z') ||
          dateString.contains('+') ||
          dateString.contains('-', 10)) {
        return parsed.toLocal();
      }
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      ).toLocal();
    } catch (e) {
      return null;
    }
  }

  /// Retourne un message de salutation en fonction de l'heure actuelle
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Bonjour';
    } else if (hour < 18) {
      return 'Bon après-midi';
    } else {
      return 'Bonsoir';
    }
  }

  /// Retourne un message de salutation avec un nom
  static String getGreetingWithName(String name) {
    return '${getGreeting()}, $name';
  }
}
