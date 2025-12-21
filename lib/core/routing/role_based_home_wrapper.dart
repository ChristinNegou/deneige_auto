import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/snow_worker/screens/snow_worker_homescreen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
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

          // Rediriger vers le bon dashboard selon le rôle
          switch (user.role) {
            case UserRole.client:
              return BlocProvider(
                create: (context) => sl<HomeBloc>(),
                child: const ClientHomeScreen(),
              );

            case UserRole.snowWorker:
              return BlocProvider(
                create: (context) => sl<HomeBloc>(),
                child: const SnowWorkerHomeScreen(),
              );

            case UserRole.admin:
              return BlocProvider(
                create: (context) => sl<HomeBloc>(),
                child: const AdminDashboardScreen(),
              );

            default:
              return BlocProvider(
                create: (context) => sl<HomeBloc>(),
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