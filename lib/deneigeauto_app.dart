import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routing/app_router.dart';
import 'core/constants/app_routes.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/services/analytics_service.dart';
import 'core/widgets/suspension_dialog.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/domain/entities/user.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/home/presentation/bloc/home_bloc.dart';

/// Clé globale pour le navigator afin de pouvoir naviguer depuis n'importe où
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DeneigeAutoApp extends StatelessWidget {
  const DeneigeAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => sl<AuthBloc>()..add(CheckAuthStatus()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Écouter l'état de suspension pour afficher le dialog
          if (state is UserSuspended) {
            _showSuspensionDialog(state);
          }
        },
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Deneige Auto',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.onboarding,
          debugShowCheckedModeBanner: false,

          // Analytics observer pour tracker les navigations automatiquement
          navigatorObservers: [
            AnalyticsService.instance.observer,
          ],

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('fr', 'FR'),

          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }

  /// Affiche le dialog de suspension et redirige vers la page de connexion
  void _showSuspensionDialog(UserSuspended state) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    SuspensionDialog.show(
      context,
      message: state.message,
      reason: state.reason,
      suspendedUntilDisplay: state.suspendedUntilDisplay,
      onDismiss: () {
        // Rediriger vers la page de sélection de compte (déconnexion)
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.accountType,
          (route) => false,
        );
      },
    );
  }
}

/// Widget qui gère la navigation initiale selon l'état d'authentification
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Navigation basée sur l'état d'authentification
        if (state is AuthAuthenticated) {
          _navigateBasedOnRole(context, state.user.role);
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.accountType,
                (route) => false,
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return _getHomeScreenForRole(state.user.role);
        }

        // Par défaut, afficher l'écran de sélection de type de compte
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  /// Navigation basée sur le rôle de l'utilisateur
  void _navigateBasedOnRole(BuildContext context, UserRole role) {
    // Tous les rôles utilisent /home qui délègue à RoleBasedHomeWrapper
    // RoleBasedHomeWrapper affiche le bon dashboard selon le rôle
    const String route = AppRoutes.home;

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
          (route) => false,
    );
  }

  /// Retourne l'écran d'accueil selon le rôle
  Widget _getHomeScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.client:
        return BlocProvider<HomeBloc>(
          create: (context) => sl<HomeBloc>(),
          child: const Scaffold(body: Center(child: Text('Client Home'))),
        );
      case UserRole.snowWorker:
        return const Scaffold(body: Center(child: Text('Snow Worker Dashboard')));
      case UserRole.admin:
        return const Scaffold(body: Center(child: Text('Admin Dashboard')));
    }
  }
}