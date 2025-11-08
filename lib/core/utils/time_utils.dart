/// Utilitaires pour la gestion du temps et des dates
class TimeUtils {
  TimeUtils._(); // Constructeur privé pour empêcher l'instanciation

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