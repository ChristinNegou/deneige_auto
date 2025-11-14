
// lib/features/reservation/presentation/screens/steps/step1_vehicle_parking.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../../domain/entities/vehicle.dart';

class Step1VehicleParkingScreen extends StatefulWidget {
  const Step1VehicleParkingScreen({Key? key}) : super(key: key);

  @override
  State<Step1VehicleParkingScreen> createState() => _Step1VehicleParkingScreenState();
}

class _Step1VehicleParkingScreenState extends State<Step1VehicleParkingScreen> {
  final TextEditingController _parkingSpotController = TextEditingController();
  final TextEditingController _customLocationController = TextEditingController();

  @override
  void dispose() {
    _parkingSpotController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Choisissez votre véhicule',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez le véhicule à déneiger et indiquez son emplacement',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              // Section: Véhicule
              _buildSectionHeader(
                context,
                icon: Icons.directions_car,
                title: 'Véhicule',
                isRequired: true,
              ),

              const SizedBox(height: 12),

              if (state.availableVehicles.isEmpty)
                _buildEmptyVehicles(context)
              else
                _buildVehicleSelector(context, state),

              const SizedBox(height: 32),

              // Section: Emplacement du véhicule
              _buildSectionHeader(
                context,
                icon: Icons.location_on,
                title: 'Emplacement du véhicule',
                isRequired: true,
              ),

              const SizedBox(height: 12),

              // ✅ Option 1 : Numéro de place
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_parking,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Numéro de place de stationnement',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _parkingSpotController,
                        decoration: InputDecoration(
                          hintText: 'Ex: P32, A-15, 205...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixText: '🅿️  ',
                          helperText: 'Le numéro se trouve généralement peint au sol',
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (value) {
                          // Mettre à jour et effacer l'autre champ
                          if (value.trim().isNotEmpty) {
                            _customLocationController.clear();
                            context.read<NewReservationBloc>().add(
                              UpdateParkingSpotNumber(value.trim()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Séparateur "OU"
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ Option 2 : Emplacement libre
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_location,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Emplacement libre (sans place assignée)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customLocationController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Devant le bâtiment A, rue principale...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.edit_location),
                          helperText: 'Décrivez où se trouve votre véhicule',
                          helperMaxLines: 2,
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          // Mettre à jour et effacer l'autre champ
                          if (value.trim().isNotEmpty) {
                            _parkingSpotController.clear();
                            context.read<NewReservationBloc>().add(
                              UpdateCustomLocation(value.trim()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Message informatif
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choisissez l\'option qui correspond à votre situation',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, {
        required IconData icon,
        required String title,
        bool isRequired = false,
      }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleSelector(
      BuildContext context,
      NewReservationState state,
      ) {
    return Column(
      children: state.availableVehicles.map((vehicle) {
        final isSelected = state.selectedVehicle?.id == vehicle.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _VehicleCard(
            vehicle: vehicle,
            isSelected: isSelected,
            onTap: () {
              context.read<NewReservationBloc>().add(
                SelectVehicle(vehicle),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyVehicles(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun véhicule enregistré',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un véhicule pour continuer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/vehicles/add');
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un véhicule'),
          ),
        ],
      ),
    );
  }
}


// ============= VEHICLE CARD =============
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: vehicle.photoUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  vehicle.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildVehicleIcon(),
                ),
              )
                  : _buildVehicleIcon(),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getColorFromString(vehicle.color),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vehicle.color,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (vehicle.licensePlate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.licensePlate!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  if (vehicle.isDefault) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Par défaut',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleIcon() {
    return Center(
      child: Text(
        vehicle.type.icon,
        style: const TextStyle(fontSize: 32),
      ),
    );
  }

  Color _getColorFromString(String colorName) {
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