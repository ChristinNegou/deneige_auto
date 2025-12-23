import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/snow_worker/screens/snow_worker_homescreen.dart';
import '../../features/snow_worker/presentation/bloc/worker_jobs_bloc.dart';
import '../../features/snow_worker/presentation/bloc/worker_stats_bloc.dart';
import '../../features/snow_worker/presentation/bloc/worker_availability_bloc.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
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

          // Rediriger vers le bon dashboard selon le rôle
          switch (user.role) {
            case UserRole.client:
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => sl<HomeBloc>()),
                  BlocProvider(create: (context) => sl<ReservationListBloc>()),
                  BlocProvider(create: (context) => sl<NotificationBloc>()),
                ],
                child: const ClientHomeScreen(),
              );

            case UserRole.snowWorker:
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => sl<WorkerJobsBloc>()),
                  BlocProvider(create: (context) => sl<WorkerStatsBloc>()),
                  BlocProvider(create: (context) => sl<WorkerAvailabilityBloc>()),
                ],
                child: const SnowWorkerHomeScreen(),
              );

            case UserRole.admin:
              return BlocProvider(
                create: (context) => sl<HomeBloc>(),
                child: const AdminDashboardScreen(),
              );

            default:
              return MultiBlocProvider(
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