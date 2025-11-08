/// Classe qui centralise toutes les constantes de routes de l'application
class AppRoutes {
  // Empêche l'instanciation de cette classe
  AppRoutes._();

  // Routes d'authentification
  static const String accountType = '/account-type';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';

  // Routes principales
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // Routes de réservations
  static const String reservations = '/reservations';
  static const String newReservation = '/reservations/new';
  static const String reservationDetails = '/reservations/details';

  // Routes de météo
  static const String weather = '/weather';

  // Routes de véhicules
  static const String vehicles = '/vehicles';
  static const String vehicleDetails = '/vehicles/details';
  static const String addVehicle = '/vehicles/add';

  // Routes d'abonnement
  static const String subscription = '/subscription';

  // Routes de profil
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Routes de paramètres
  static const String settings = '/settings';

  // Routes de notifications
  static const String notifications = '/notifications';

  // Routes déneigeur
  static const String snowWorkerDashboard = '/snow-worker/dashboard';
  static const String jobsList = '/snow-worker/jobs';
  static const String jobDetails = '/snow-worker/jobs/details';

}