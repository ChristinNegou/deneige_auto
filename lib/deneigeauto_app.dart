import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routing/app_router.dart';
import 'core/constants/app_routes.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/services/analytics_service.dart';
import 'core/services/locale_service.dart';
import 'core/widgets/suspension_dialog.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/domain/entities/user.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'l10n/app_localizations.dart';

/// Cle globale pour le navigator afin de pouvoir naviguer depuis n'importe ou
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DeneigeAutoApp extends StatefulWidget {
  const DeneigeAutoApp({super.key});

  @override
  State<DeneigeAutoApp> createState() => _DeneigeAutoAppState();
}

class _DeneigeAutoAppState extends State<DeneigeAutoApp> {
  bool _hasNavigatedToHome = false;
  final LocaleService _localeService = sl<LocaleService>();

  @override
  void initState() {
    super.initState();
    _localeService.loadLocale();
    _localeService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => sl<AuthBloc>()..add(CheckAuthStatus()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is UserSuspended) {
            _showSuspensionDialog(state);
          } else if (state is AuthAuthenticated && !_hasNavigatedToHome) {
            _hasNavigatedToHome = true;
            _navigateToHome(state.user.role);
          } else if (state is AuthUnauthenticated) {
            _hasNavigatedToHome = false;
          }
        },
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Deneige Auto',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.onboarding,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [
            AnalyticsService.instance.observer,
          ],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _localeService.locale,
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }

  void _navigateToHome(UserRole role) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }
    });
  }

  void _showSuspensionDialog(UserSuspended state) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    SuspensionDialog.show(
      context,
      message: state.message,
      reason: state.reason,
      suspendedUntilDisplay: state.suspendedUntilDisplay,
      onDismiss: () {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.accountType,
          (route) => false,
        );
      },
    );
  }
}

/// Widget qui gere la navigation initiale selon l'etat d'authentification
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
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

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  void _navigateBasedOnRole(BuildContext context, UserRole role) {
    const String route = AppRoutes.home;

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (route) => false,
    );
  }

  Widget _getHomeScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.client:
        return BlocProvider<HomeBloc>(
          create: (context) => sl<HomeBloc>(),
          child: const Scaffold(body: Center(child: Text('Client Home'))),
        );
      case UserRole.snowWorker:
        return const Scaffold(
            body: Center(child: Text('Snow Worker Dashboard')));
      case UserRole.admin:
        return const Scaffold(body: Center(child: Text('Admin Dashboard')));
    }
  }
}
