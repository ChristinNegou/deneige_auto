/// Classe qui centralise toutes les constantes de routes de l'application
class AppRoutes {
  // Empêche l'instanciation de cette classe
  AppRoutes._();

  // Routes d'authentification
  static const String accountType = '/account-type';
  static const String login = '/login';
  static const String register = '/register';
  static const String phoneVerification = '/phone-verification';
  static const String onboarding = '/onboarding';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Routes principales
  static const String home = '/home';

  // Routes de réservations
  static const String reservations = '/reservations';
  static const String newReservation = '/reservations/new';
  static const String reservationDetails = '/reservations/details';
  static const String editReservation = '/reservations/edit';
  static const String reservationSuccess = '/reservation/success';

  // Routes de météo
  static const String weather = '/weather';

  // Routes de véhicules
  static const String vehicles = '/vehicles';
  static const String addVehicle = '/vehicles/add';

  // Routes d'abonnement
  static const String subscription = '/subscription';

  // Routes de profil
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Routes de paiements
  static const String payments = '/payments';
  static const String addPaymentMethod = '/payments/add-method';

  // Routes d'activités
  static const String activities = '/activities';
  static const String activityDetails = '/activities/details';

  // Routes de paramètres
  static const String settings = '/settings';
  static const String privacyPolicy = '/settings/privacy';
  static const String termsOfService = '/settings/terms';

  // Routes d'aide et support
  static const String helpSupport = '/help-support';

  // Routes de notifications
  static const String notifications = '/notifications';

  // Routes de chat
  static const String aiChat = '/ai-chat';

  // Routes déneigeur
  static const String jobsList = '/snow-worker/jobs';
  static const String workerJobDetails = '/snow-worker/jobs/details';
  static const String workerActiveJob = '/snow-worker/active-job';
  static const String workerHistory = '/snow-worker/history';
  static const String workerHelpSupport = '/snow-worker/help-support';
  static const String identityVerification =
      '/snow-worker/identity-verification';

  // Routes de litiges
  static const String disputes = '/disputes';
  static const String disputeDetails = '/disputes/details';
  static const String createDispute = '/disputes/create';
  static const String respondDispute = '/disputes/respond';
  static const String addEvidence = '/disputes/add-evidence';
  static const String reportNoShow = '/disputes/report-no-show';
}
