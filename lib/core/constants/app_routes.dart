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
  static const String dashboard = '/dashboard';

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
  static const String vehicleDetails = '/vehicles/details';
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
  static const String chat = '/chat';
  static const String aiChat = '/ai-chat';

  // Routes déneigeur
  static const String snowWorkerDashboard = '/snow-worker/dashboard';
  static const String jobsList = '/snow-worker/jobs';
  static const String jobDetails = '/snow-worker/jobs/details';
  static const String workerJobDetails = '/snow-worker/jobs/details';
  static const String workerActiveJob = '/snow-worker/active-job';
  static const String workerHistory = '/snow-worker/history';
  static const String workerEarnings = '/snow-worker/earnings';
  static const String workerSettings = '/snow-worker/settings';
  static const String workerPaymentSetup = '/snow-worker/payment-setup';
  static const String workerBankAccounts = '/snow-worker/bank-accounts';
  static const String workerHelpSupport = '/snow-worker/help-support';

  //Routes pour le dashboard client
  static const String clientHome = '/client-home';

  // Routes admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminReservations = '/admin/reservations';
  static const String adminWorkers = '/admin/workers';
  static const String adminReports = '/admin/reports';
  static const String adminSupport = '/admin/support';
  static const String adminStripeAccounts = '/admin/stripe-accounts';
  static const String adminAI = '/admin/ai';
}
