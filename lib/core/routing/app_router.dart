import 'package:deneige_auto/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:deneige_auto/features/vehicule/presentation/pages/vehicles_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/jobslist/jobslist_page.dart';
import '../../features/notifications/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reservation/presentation/bloc/new_reservation_bloc.dart';
import '../../features/reservation/presentation/pages/reservation_details_page.dart';
import '../../features/reservation/presentation/pages/reservations_page.dart';
import '../../features/reservation/presentation/screens/reservation_success_screen.dart';
import '../../features/settings/page/settings_page.dart';
import '../../features/snow_worker/presentation/pages/snowworker_dashboard_page.dart';
import '../../features/subscription/presentation/page/subscription_page.dart';
import '../../features/vehicule/presentation/pages/add_vehicle_page.dart';
import '../../features/weather/presentation/pages/weather_page.dart';
import '../constants/app_routes.dart';
import '../di/injection_container.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/auth/presentation/screens/account_type_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/user.dart';
import 'role_based_home_wrapper.dart';
import '../../features/reservation/presentation/screens/new_reservation_screen.dart';


/// Classe qui gère la génération et la navigation des routes
class AppRouter {
  // Empêche l'instanciation
  AppRouter._();

  /// Génère les routes de l'application
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // Routes d'authentification
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>(),
            child: const OnboardingScreen(),
          ),
          settings: settings,
        );

      case AppRoutes.accountType:
        return MaterialPageRoute(
          builder: (_) => const AccountTypeSelectionScreen(),
          settings: settings,
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>(),
            child: const LoginScreen(),
          ),
          settings: settings,
        );

      case AppRoutes.register:
        final role = settings.arguments as UserRole? ?? UserRole.client;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>(),
            child: RegisterScreen(role: role),
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
          builder: (_) => BlocProvider(
            create: (context) => sl<AuthBloc>(),
            child: ResetPasswordScreen(token: token),
          ),
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

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
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

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );

      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsPage(),
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

      default:
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

  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
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




