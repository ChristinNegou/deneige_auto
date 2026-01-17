import 'package:deneige_auto/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:deneige_auto/features/vehicule/presentation/pages/vehicles_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/jobslist/jobslist_page.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/payment/presentation/screens/payments_list_screen.dart';
import '../../features/payment/presentation/screens/add_payment_method_screen.dart';
import '../../features/payment/presentation/bloc/payment_methods_bloc.dart';
import '../../features/reservation/presentation/bloc/new_reservation_bloc.dart';
import '../../features/reservation/presentation/pages/reservation_details_page.dart';
import '../../features/reservation/presentation/pages/edit_reservation_page.dart';
import '../../features/reservation/presentation/pages/reservations_page.dart';
import '../../features/reservation/presentation/screens/reservation_success_screen.dart';
import '../../features/reservation/domain/entities/reservation.dart';
import '../../features/settings/page/settings_page.dart';
import '../../features/settings/presentation/pages/privacy_policy_page.dart';
import '../../features/settings/presentation/pages/terms_of_service_page.dart';
import '../../features/support/presentation/pages/help_support_page.dart';
import '../../features/support/presentation/pages/worker_help_support_page.dart';
import '../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../features/ai_chat/presentation/bloc/ai_chat_bloc.dart';
import '../../features/snow_worker/presentation/pages/snowworker_dashboard_page.dart';
import '../../features/snow_worker/presentation/pages/worker_job_details_page.dart';
import '../../features/snow_worker/presentation/pages/active_job_page.dart';
import '../../features/snow_worker/presentation/pages/worker_history_page.dart';
import '../../features/snow_worker/presentation/pages/worker_earnings_page.dart';
import '../../features/snow_worker/presentation/pages/worker_settings_page.dart';
import '../../features/snow_worker/presentation/pages/worker_payment_setup_page.dart';
import '../../features/snow_worker/presentation/pages/worker_bank_accounts_page.dart';
import '../../features/snow_worker/domain/entities/worker_job.dart';
import '../../features/snow_worker/presentation/bloc/worker_jobs_bloc.dart';
import '../../features/subscription/presentation/page/subscription_page.dart';
import '../../features/vehicule/presentation/pages/add_vehicle_page.dart';
import '../../features/weather/presentation/pages/weather_page.dart';
import '../constants/app_routes.dart';
import '../di/injection_container.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/auth/presentation/screens/account_type_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/phone_verification_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/domain/entities/user.dart';
import 'role_based_home_wrapper.dart';
import '../../features/reservation/presentation/screens/new_reservation_screen.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_reservations_page.dart';
import '../../features/admin/presentation/pages/admin_workers_page.dart';
import '../../features/admin/presentation/pages/admin_reports_page.dart';
import '../../features/admin/presentation/pages/admin_support_page.dart';
import '../../features/admin/presentation/pages/admin_stripe_accounts_page.dart';
import '../../features/admin/presentation/pages/admin_ai_page.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/admin/presentation/bloc/admin_event.dart';

/// Classe qui gère la génération et la navigation des routes
class AppRouter {
  // Empêche l'instanciation
  AppRouter._();

  /// Génère les routes de l'application
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Routes d'authentification
      // Routes d'authentification - utilisent le AuthBloc singleton fourni au niveau app
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case AppRoutes.accountType:
        return MaterialPageRoute(
          builder: (_) => const AccountTypeSelectionScreen(),
          settings: settings,
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case AppRoutes.register:
        final role = settings.arguments as UserRole? ?? UserRole.client;
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(role: role),
          settings: settings,
        );

      case AppRoutes.phoneVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PhoneVerificationScreen(
            phoneNumber: args['phoneNumber'] as String,
            email: args['email'] as String,
            password: args['password'] as String,
            firstName: args['firstName'] as String,
            lastName: args['lastName'] as String,
            role: args['role'] as String,
          ),
          settings: settings,
        );

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );

      case AppRoutes.resetPassword:
        final token = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token),
          settings: settings,
        );

      // Routes principales
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<HomeBloc>(),
            child: const RoleBasedHomeWrapper(),
          ),
          settings: settings,
        );

      case AppRoutes.reservations:
        return MaterialPageRoute(
          builder: (_) => const ReservationsPage(),
          settings: settings,
        );

      case AppRoutes.newReservation:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<NewReservationBloc>(),
            child: const NewReservationScreen(),
          ),
          settings: settings,
        );

      case AppRoutes.reservationDetails:
        final reservationId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ReservationDetailsPage(
            reservationId: reservationId ?? '',
          ),
          settings: settings,
        );

      case AppRoutes.editReservation:
        final reservation = settings.arguments as Reservation;
        return MaterialPageRoute(
          builder: (_) => EditReservationPage(
            reservation: reservation,
          ),
          settings: settings,
        );

      case AppRoutes.reservationSuccess:
        final reservationId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ReservationSuccessScreen(
            reservationId: reservationId,
          ),
          settings: settings,
        );

      case AppRoutes.weather:
        return MaterialPageRoute(
          builder: (_) => const WeatherPage(),
          settings: settings,
        );

      case AppRoutes.vehicles:
        return MaterialPageRoute(
          builder: (_) => const VehiclesListPage(),
          settings: settings,
        );

      case AppRoutes.addVehicle:
        return MaterialPageRoute(
          builder: (_) => const AddVehiclePage(),
          settings: settings,
        );

      case AppRoutes.subscription:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionPage(),
          settings: settings,
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
          settings: settings,
        );

      case AppRoutes.editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfilePage(),
          settings: settings,
        );

      case AppRoutes.payments:
        return MaterialPageRoute(
          builder: (_) => const PaymentsListScreen(),
          settings: settings,
        );

      case AppRoutes.addPaymentMethod:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<PaymentMethodsBloc>(),
            child: const AddPaymentMethodScreen(),
          ),
          settings: settings,
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );

      case AppRoutes.privacyPolicy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyPage(),
          settings: settings,
        );

      case AppRoutes.termsOfService:
        return MaterialPageRoute(
          builder: (_) => const TermsOfServicePage(),
          settings: settings,
        );

      case AppRoutes.helpSupport:
        return MaterialPageRoute(
          builder: (_) => const HelpSupportPage(),
          settings: settings,
        );

      case AppRoutes.aiChat:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AIChatBloc>(),
            child: const AIChatPage(),
          ),
          settings: settings,
        );

      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<NotificationBloc>()..add(LoadNotifications()),
            child: const NotificationsPage(),
          ),
          settings: settings,
        );

      // Routes d'activités
      case AppRoutes.activities:
        return MaterialPageRoute(
          builder: (_) => const ActivitiesScreen(),
          settings: settings,
        );

      case AppRoutes.activityDetails:
        final reservationId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ReservationDetailsPage(
            reservationId: reservationId ?? '',
          ),
          settings: settings,
        );

      // Routes déneigeur
      case AppRoutes.snowWorkerDashboard:
        return MaterialPageRoute(
          builder: (_) => const SnowWorkerDashboardPage(),
          settings: settings,
        );

      case AppRoutes.jobsList:
        return MaterialPageRoute(
          builder: (_) => const JobsListPage(),
          settings: settings,
        );

      case AppRoutes.workerJobDetails:
        final job = settings.arguments as WorkerJob;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<WorkerJobsBloc>(),
            child: WorkerJobDetailsPage(job: job),
          ),
          settings: settings,
        );

      case AppRoutes.workerActiveJob:
        final job = settings.arguments as WorkerJob;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<WorkerJobsBloc>(),
            child: ActiveJobPage(job: job),
          ),
          settings: settings,
        );

      case AppRoutes.workerHistory:
        return MaterialPageRoute(
          builder: (_) => const WorkerHistoryPage(),
          settings: settings,
        );

      case AppRoutes.workerEarnings:
        return MaterialPageRoute(
          builder: (_) => const WorkerEarningsPage(),
          settings: settings,
        );

      case AppRoutes.workerSettings:
        return MaterialPageRoute(
          builder: (_) => const WorkerSettingsPage(),
          settings: settings,
        );

      case AppRoutes.workerPaymentSetup:
        return MaterialPageRoute(
          builder: (_) => const WorkerPaymentSetupPage(),
          settings: settings,
        );

      case AppRoutes.workerBankAccounts:
        return MaterialPageRoute(
          builder: (_) => const WorkerBankAccountsPage(),
          settings: settings,
        );

      case AppRoutes.workerHelpSupport:
        return MaterialPageRoute(
          builder: (_) => const WorkerHelpSupportPage(),
          settings: settings,
        );

      // Routes admin
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AdminBloc>()..add(LoadDashboardStats()),
            child: const AdminDashboardPage(),
          ),
          settings: settings,
        );

      case AppRoutes.adminUsers:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AdminBloc>(),
            child: const AdminUsersPage(),
          ),
          settings: settings,
        );

      case AppRoutes.adminReservations:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AdminBloc>(),
            child: const AdminReservationsPage(),
          ),
          settings: settings,
        );

      case AppRoutes.adminWorkers:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AdminBloc>(),
            child: const AdminWorkersPage(),
          ),
          settings: settings,
        );

      case AppRoutes.adminReports:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AdminBloc>(),
            child: const AdminReportsPage(),
          ),
          settings: settings,
        );

      case AppRoutes.adminSupport:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AdminBloc>(),
            child: const AdminSupportPage(),
          ),
          settings: settings,
        );

      case AppRoutes.adminStripeAccounts:
        return MaterialPageRoute(
          builder: (_) => const AdminStripeAccountsPage(),
          settings: settings,
        );

      case AppRoutes.adminAI:
        return MaterialPageRoute(
          builder: (_) => const AdminAIPage(),
          settings: settings,
        );

      default:
        // Fallback pour les anciennes routes de réservation
        if (settings.name != null && settings.name!.contains('reservation')) {
          // Rediriger vers la page des détails de réservation si on a un ID
          final reservationId = settings.arguments as String?;
          if (reservationId != null && reservationId.isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) =>
                  ReservationDetailsPage(reservationId: reservationId),
              settings: settings,
            );
          }
          // Sinon, rediriger vers la liste des réservations
          return MaterialPageRoute(
            builder: (_) => const ReservationsPage(),
            settings: settings,
          );
        }

        // Route non trouvée
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Erreur'),
              backgroundColor: Colors.red,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page non trouvée',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Route: ${settings.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  /// Méthodes utilitaires de navigation

  static Future<T?> navigateTo<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static Future<T?> navigateToAndReplace<T, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> navigateToAndClearStack<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }
}

// ======================= PAGE PLACEHOLDER ===================
