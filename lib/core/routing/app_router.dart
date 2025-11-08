import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_routes.dart';
import '../di/injection_container.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/auth/presentation/screens/account_type_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/user.dart';

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

    // Routes principales
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => sl<HomeBloc>(),
            child: const HomeScreen(),
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
          builder: (_) => const NewReservationPage(),
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

      case AppRoutes.weather:
        return MaterialPageRoute(
          builder: (_) => const WeatherPage(),
          settings: settings,
        );

      case AppRoutes.vehicles:
        return MaterialPageRoute(
          builder: (_) => const VehiclesPage(),
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

// Pages placeholder - Remplacez-les par vos vraies pages au fur et à mesure

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Dashboard')));
}

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Réservations')));
}

class NewReservationPage extends StatelessWidget {
  const NewReservationPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Nouvelle réservation')));
}

class ReservationDetailsPage extends StatelessWidget {
  final String reservationId;
  const ReservationDetailsPage({Key? key, required this.reservationId}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Détails: $reservationId')));
}

class WeatherPage extends StatelessWidget {
  const WeatherPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Météo')));
}

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Véhicules')));
}

class AddVehiclePage extends StatelessWidget {
  const AddVehiclePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Ajouter véhicule')));
}

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Abonnement')));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profil')));
}

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Éditer profil')));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Paramètres')));
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Notifications')));
}

class SnowWorkerDashboardPage extends StatelessWidget {
  const SnowWorkerDashboardPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Dashboard Déneigeur')));
}

class JobsListPage extends StatelessWidget {
  const JobsListPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Liste des jobs')));
}