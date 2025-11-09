
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/snow_worker/screens/snow_worker_homescreen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';


/// Widget qui affiche le bon dashboard selon le rôle de l'utilisateur
class RoleBasedHomeWrapper extends StatelessWidget {
  const RoleBasedHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('[DEBUG] RoleBasedHomeWrapper - État actuel: ${state.runtimeType}');

        if (state is AuthAuthenticated) {
          final user = state.user;

          print('========================================');
          print('[DEBUG] Utilisateur authentifié:');
          print('[DEBUG] - ID: ${user.id}');
          print('[DEBUG] - Email: ${user.email}');
          print('[DEBUG] - Nom: ${user.name}');
          print('[DEBUG] - Rôle: ${user.role}');
          print('[DEBUG] - Rôle toString: ${user.role.toString()}');
          print('[DEBUG] - Rôle == UserRole.client: ${user.role == UserRole.client}');
          print('[DEBUG] - Rôle == UserRole.snowWorker: ${user.role == UserRole.snowWorker}');
          print('[DEBUG] - Rôle == UserRole.admin: ${user.role == UserRole.admin}');
          print('========================================');

          // Rediriger vers le bon dashboard selon le rôle
          switch (user.role) {
            case UserRole.client:
              print('[DEBUG] ➡️ Affichage du ClientHomeScreen');
              return const ClientHomeScreen();

            case UserRole.snowWorker:
              print('[DEBUG] ➡️ Affichage du SnowWorkerHomeScreen');
              return const SnowWorkerHomeScreen();

            case UserRole.admin:
              print('[DEBUG] ➡️ Affichage du AdminDashboardScreen');
              return const AdminDashboardScreen();

            default:
              print('[DEBUG] ⚠️ Rôle non reconnu, affichage du ClientHomeScreen par défaut');
              return const ClientHomeScreen();
          }
        }

        print('[DEBUG] ⏳ Utilisateur non authentifié, affichage du loader');
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