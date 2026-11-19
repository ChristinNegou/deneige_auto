import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/snow_worker/presentation/pages/worker_main_dashboard.dart';
import '../../features/auth/presentation/screens/admin_web_notice_screen.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/reservation/presentation/bloc/reservation_list_bloc.dart'
    as reservation_bloc;
import '../di/injection_container.dart';

/// Widget qui affiche le bon dashboard selon le rôle de l'utilisateur
class RoleBasedHomeWrapper extends StatelessWidget {
  const RoleBasedHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // Ne reconstruire que pour AuthAuthenticated ou AuthUnauthenticated
        return current is AuthAuthenticated || current is AuthUnauthenticated;
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          final uniqueKey = ValueKey('${user.id}_${user.role.name}');

          switch (user.role) {
            case UserRole.client:
              return MultiBlocProvider(
                key: uniqueKey,
                providers: [
                  BlocProvider(create: (context) => sl<HomeBloc>()),
                  BlocProvider(
                    create: (context) =>
                        sl<reservation_bloc.ReservationListBloc>()
                          ..add(const reservation_bloc.LoadReservations()),
                  ),
                  BlocProvider(create: (context) => sl<NotificationBloc>()),
                ],
                child: const ClientHomeScreen(),
              );

            case UserRole.snowWorker:
              return WorkerMainDashboard(key: uniqueKey);

            case UserRole.admin:
              // L'administration se fait sur le site admin
              return AdminWebNoticeScreen(key: uniqueKey);
          }
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
