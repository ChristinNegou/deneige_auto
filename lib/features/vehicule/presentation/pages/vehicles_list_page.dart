import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/vehicule_bloc.dart';

class VehiclesListPage extends StatelessWidget {
  const VehiclesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<VehicleBloc>()..add(LoadVehicles()),
      child: const VehiclesListView(),
    );
  }
}

class VehiclesListView extends StatelessWidget {
  const VehiclesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes véhicules'),
        actions: [
      IconButton(
      icon: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.addVehicle,
          );
          if (result == true && context.mounted) {
            context.read<VehicleBloc>().add(LoadVehicles());
          }
        },
    ),
   ],
      ),
      body: BlocConsumer<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.vehicles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun véhicule enregistré',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez votre premier véhicule pour\ncommencer à utiliser le service',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.addVehicle,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un véhicule'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<VehicleBloc>().add(LoadVehicles());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = state.vehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        vehicle.type.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    title: Text(
                      vehicle.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getVehicleColor(vehicle.color),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(vehicle.color),
                          ],
                        ),
                        if (vehicle.licensePlate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            vehicle.licensePlate!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: vehicle.isDefault
                        ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Par défaut',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    )
                        : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: () {
                        _showDeleteConfirmation(context, vehicle.id);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addVehicle),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String vehicleId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le véhicule'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce véhicule ?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<VehicleBloc>().add(DeleteVehicle(vehicleId));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Color _getVehicleColor(String colorName) {
    final colors = {
      'Blanc': Colors.white,
      'Noir': Colors.black,
      'Gris': Colors.grey,
      'Rouge': Colors.red,
      'Bleu': Colors.blue,
      'Vert': Colors.green,
      'Jaune': Colors.yellow,
      'Orange': Colors.orange,
      'Argent': Colors.grey[300]!,
      'Brun': Colors.brown,
      'Beige': const Color(0xFFF5F5DC),
    };
    return colors[colorName] ?? Colors.grey;
  }
}