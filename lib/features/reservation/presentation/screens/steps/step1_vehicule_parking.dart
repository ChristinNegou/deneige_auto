import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../../domain/entities/vehicle.dart';

class Step1VehicleParkingScreen extends StatefulWidget {
  const Step1VehicleParkingScreen({super.key});

  @override
  State<Step1VehicleParkingScreen> createState() => _Step1VehicleParkingScreenState();
}

class _Step1VehicleParkingScreenState extends State<Step1VehicleParkingScreen> {
  final TextEditingController _parkingSpotController = TextEditingController();
  final TextEditingController _customLocationController = TextEditingController();
  int _selectedLocationOption = 0; // 0 = none, 1 = parking spot, 2 = custom

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Véhicule
              _buildSectionHeader('Véhicule', Icons.directions_car_rounded),
              const SizedBox(height: 12),

              if (state.availableVehicles.isEmpty)
                _buildEmptyVehicles(context)
              else
                _buildVehicleList(context, state),

              const SizedBox(height: 32),

              // Section Emplacement
              _buildSectionHeader('Emplacement', Icons.location_on_rounded),
              const SizedBox(height: 12),

              _buildLocationOptions(context),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleList(BuildContext context, NewReservationState state) {
    return Column(
      children: [
        ...state.availableVehicles.map((vehicle) {
          final isSelected = state.selectedVehicle?.id == vehicle.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _VehicleCard(
              vehicle: vehicle,
              isSelected: isSelected,
              onTap: () => context.read<NewReservationBloc>().add(SelectVehicle(vehicle)),
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildAddVehicleButton(context),
      ],
    );
  }

  Widget _buildAddVehicleButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _navigateToAddVehicle(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Ajouter un véhicule'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildLocationOptions(BuildContext context) {
    return Column(
      children: [
        // Option 1: Place assignée
        _buildLocationOption(
          title: 'Place assignée',
          subtitle: 'J\'ai un numéro de place',
          icon: Icons.local_parking_rounded,
          isSelected: _selectedLocationOption == 1,
          onTap: () => setState(() => _selectedLocationOption = 1),
          child: _selectedLocationOption == 1
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _parkingSpotController,
                    decoration: InputDecoration(
                      hintText: 'Ex: P32, A-15, 205...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1),
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        _customLocationController.clear();
                        context.read<NewReservationBloc>().add(UpdateParkingSpotNumber(value.trim()));
                      }
                    },
                  ),
                )
              : null,
        ),

        const SizedBox(height: 10),

        // Option 2: Emplacement libre
        _buildLocationOption(
          title: 'Emplacement libre',
          subtitle: 'Décrivez où se trouve le véhicule',
          icon: Icons.edit_location_alt_rounded,
          isSelected: _selectedLocationOption == 2,
          onTap: () => setState(() => _selectedLocationOption = 2),
          child: _selectedLocationOption == 2
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _customLocationController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Devant le bâtiment A...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          if (value.trim().isNotEmpty) {
                            _parkingSpotController.clear();
                            context.read<NewReservationBloc>().add(UpdateCustomLocation(value.trim()));
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildQuickChip('Devant le bâtiment'),
                          _buildQuickChip('Près de l\'entrée'),
                          _buildQuickChip('Zone visiteurs'),
                          _buildQuickChip('Stationnement arrière'),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildLocationOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isSelected ? AppTheme.primary : Colors.grey[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _customLocationController.text = label;
        });
        context.read<NewReservationBloc>().add(UpdateCustomLocation(label));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildEmptyVehicles(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'Aucun véhicule',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajoutez votre premier véhicule',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddVehicle(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddVehicle(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/vehicles/add');
    if (result != null && result is bool && result == true && context.mounted) {
      context.read<NewReservationBloc>().add(LoadInitialData());
    }
  }
}

// Carte véhicule compacte
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icône véhicule
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: vehicle.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        vehicle.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildIcon(),
                      ),
                    )
                  : _buildIcon(),
            ),
            const SizedBox(width: 12),

            // Infos véhicule
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getColor(vehicle.color),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!, width: 0.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vehicle.color,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (vehicle.licensePlate != null) ...[
                        Text(' · ', style: TextStyle(color: Colors.grey[400])),
                        Text(
                          vehicle.licensePlate!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Checkbox
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Center(
      child: Text(vehicle.type.icon, style: const TextStyle(fontSize: 20)),
    );
  }

  Color _getColor(String colorName) {
    final colors = {
      'Blanc': Colors.white,
      'Noir': Colors.black87,
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
