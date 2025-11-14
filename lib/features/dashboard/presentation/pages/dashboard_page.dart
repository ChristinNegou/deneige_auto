import 'package:deneige_auto/features/reservation/domain/entities/reservation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../reservation/presentation/bloc/reservation_list_bloc.dart';
import '../../../vehicule/presentation/bloc/vehicule_bloc.dart';

// Page d'accueil de l'application
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ReservationListBloc(
            getReservations: sl(),
            cancelReservation: sl(),
          )..add(const LoadReservations(upcomingOnly: true)),
        ),
        BlocProvider(
          create: (context) => VehicleBloc(
            getVehicles: sl(),
          )..add(LoadVehicles()),
        ),
      ],
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ReservationListBloc>().add(RefreshReservations());
          context.read<VehicleBloc>().add(LoadVehicles());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue !',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Statistiques avec données réelles
              BlocBuilder<ReservationListBloc, ReservationListState>(
                builder: (context, reservationState) {
                  return _buildStatCard(
                    context,
                    icon: Icons.event_available,
                    title: 'Réservations actives',
                    value: '${reservationState.reservations.length}',
                    color: Colors.blue,
                  );
                },
              ),
              const SizedBox(height: 16),

              BlocBuilder<VehicleBloc, VehicleState>(
                builder: (context, vehicleState) {
                  return _buildStatCard(
                    context,
                    icon: Icons.directions_car,
                    title: 'Véhicules enregistrés',
                    value: '${vehicleState.vehicles.length}',
                    color: Colors.green,
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildStatCard(
                context,
                icon: Icons.history,
                title: 'Historique',
                value: '0',
                color: Colors.orange,
              ),

              const SizedBox(height: 24),

              // Liste des prochaines réservations
              BlocBuilder<ReservationListBloc, ReservationListState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.reservations.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Aucune réservation à venir',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prochaines réservations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.reservations.take(3).map((reservation) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.event,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(reservation.vehicle.displayName),
                            subtitle: Text(
                              'Place ${reservation.parkingSpot.displayName}',
                            ),
                            trailing: Text(
                              reservation.status.displayName,
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.newReservation),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle réservation'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        required Color color,
      }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}