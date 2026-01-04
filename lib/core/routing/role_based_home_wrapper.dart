import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/snow_worker/presentation/pages/worker_main_dashboard.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/admin/presentation/bloc/admin_event.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/reservation/presentation/bloc/reservation_list_bloc.dart';
import '../di/injection_container.dart';

/// Widget qui affiche le bon dashboard selon le rôle de l'utilisateur
class RoleBasedHomeWrapper extends StatelessWidget {
  const RoleBasedHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;

          // Utiliser une Key unique basée sur l'ID utilisateur et le rôle
          // pour forcer une reconstruction complète lors du changement de compte
          final uniqueKey = ValueKey('${user.id}_${user.role.name}');

          // Rediriger vers le bon dashboard selon le rôle
          switch (user.role) {
            case UserRole.client:
              return MultiBlocProvider(
                key: uniqueKey,
                providers: [
                  BlocProvider(create: (context) => sl<HomeBloc>()),
                  BlocProvider(create: (context) => sl<ReservationListBloc>()),
                  BlocProvider(create: (context) => sl<NotificationBloc>()),
                ],
                child: const ClientHomeScreen(),
              );

            case UserRole.snowWorker:
              // WorkerMainDashboard gère ses propres BlocProviders
              return WorkerMainDashboard(key: uniqueKey);

            case UserRole.admin:
              return BlocProvider(
                key: uniqueKey,
                create: (context) => sl<AdminBloc>()..add(LoadDashboardStats()),
                child: const AdminDashboardPage(),
              );

            default:
              return MultiBlocProvider(
                key: uniqueKey,
                providers: [
                  BlocProvider(create: (context) => sl<HomeBloc>()),
                  BlocProvider(create: (context) => sl<ReservationListBloc>()),
                  BlocProvider(create: (context) => sl<NotificationBloc>()),
                ],
                child: const ClientHomeScreen(),
              );
          }
        }

        // Si pas authentifié, afficher un loader
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
