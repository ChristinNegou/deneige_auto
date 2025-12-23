import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/worker_availability_bloc.dart';
import '../../domain/entities/worker_profile.dart';
import '../../../../core/di/injection_container.dart';

class WorkerSettingsPage extends StatelessWidget {
  const WorkerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WorkerAvailabilityBloc>()..add(const LoadAvailability()),
      child: const _WorkerSettingsView(),
    );
  }
}

class _WorkerSettingsView extends StatefulWidget {
  const _WorkerSettingsView();

  @override
  State<_WorkerSettingsView> createState() => _WorkerSettingsViewState();
}

class _WorkerSettingsViewState extends State<_WorkerSettingsView> {
  final _formKey = GlobalKey<FormState>();

  // Equipment checkboxes
  bool _hasShovel = true;
  bool _hasBrush = true;
  bool _hasIceScraper = true;
  bool _hasSaltSpreader = false;
  bool _hasSnowBlower = false;

  // Vehicle selection
  VehicleType _selectedVehicle = VehicleType.car;

  // Max active jobs
  int _maxActiveJobs = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres déneigeur'),
        backgroundColor: Colors.orange[600],
      ),
      body: BlocConsumer<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        listener: (context, state) {
          if (state is WorkerProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paramètres sauvegardés'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is WorkerAvailabilityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WorkerAvailabilityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equipment Section
                  _buildSectionCard(
                    title: 'Mon équipement',
                    icon: Icons.build,
                    child: Column(
                      children: [
                        _buildEquipmentCheckbox(
                          'Pelle à neige',
                          Icons.cleaning_services,
                          _hasShovel,
                          (val) => setState(() => _hasShovel = val!),
                        ),
                        _buildEquipmentCheckbox(
                          'Balai à neige',
                          Icons.brush,
                          _hasBrush,
                          (val) => setState(() => _hasBrush = val!),
                        ),
                        _buildEquipmentCheckbox(
                          'Grattoir à glace',
                          Icons.hardware,
                          _hasIceScraper,
                          (val) => setState(() => _hasIceScraper = val!),
                        ),
                        _buildEquipmentCheckbox(
                          'Épandeur de sel',
                          Icons.grain,
                          _hasSaltSpreader,
                          (val) => setState(() => _hasSaltSpreader = val!),
                        ),
                        _buildEquipmentCheckbox(
                          'Souffleuse',
                          Icons.air,
                          _hasSnowBlower,
                          (val) => setState(() => _hasSnowBlower = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Section
                  _buildSectionCard(
                    title: 'Mon véhicule',
                    icon: Icons.directions_car,
                    child: Column(
                      children: VehicleType.values.map((type) {
                        return RadioListTile<VehicleType>(
                          title: Text(_getVehicleLabel(type)),
                          subtitle: Text(_getVehicleDescription(type)),
                          value: type,
                          groupValue: _selectedVehicle,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedVehicle = val);
                            }
                          },
                          activeColor: Colors.orange[600],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Work Preferences
                  _buildSectionCard(
                    title: 'Préférences de travail',
                    icon: Icons.settings,
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Jobs simultanés max'),
                          subtitle: Text(
                            'Vous pouvez avoir $_maxActiveJobs jobs actifs en même temps',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _maxActiveJobs > 1
                                    ? () => setState(() => _maxActiveJobs--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '$_maxActiveJobs',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _maxActiveJobs < 5
                                    ? () => setState(() => _maxActiveJobs++)
                                    : null,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preferred Zones
                  _buildSectionCard(
                    title: 'Zones préférées',
                    icon: Icons.location_on,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Définissez vos zones de travail préférées pour recevoir des notifications prioritaires.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildZoneChip('Trois-Rivières Centre'),
                        _buildZoneChip('Cap-de-la-Madeleine'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showAddZoneDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une zone'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notifications
                  _buildSectionCard(
                    title: 'Notifications',
                    icon: Icons.notifications,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Nouveaux jobs'),
                          subtitle: const Text('Recevoir une alerte pour les nouveaux jobs'),
                          value: true,
                          onChanged: (val) {},
                          activeColor: Colors.orange[600],
                        ),
                        SwitchListTile(
                          title: const Text('Jobs urgents'),
                          subtitle: const Text('Alertes prioritaires pour jobs urgents'),
                          value: true,
                          onChanged: (val) {},
                          activeColor: Colors.orange[600],
                        ),
                        SwitchListTile(
                          title: const Text('Pourboires'),
                          subtitle: const Text('Notification lors de la réception d\'un pourboire'),
                          value: true,
                          onChanged: (val) {},
                          activeColor: Colors.orange[600],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sauvegarder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildEquipmentCheckbox(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.orange[600],
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget _buildZoneChip(String zoneName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        label: Text(zoneName),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          // Remove zone
        },
        backgroundColor: Colors.orange[50],
        deleteIconColor: Colors.orange[600],
      ),
    );
  }

  String _getVehicleLabel(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'Voiture';
      case VehicleType.truck:
        return 'Camionnette';
      case VehicleType.atv:
        return 'VTT / Quad';
      case VehicleType.other:
        return 'Autre';
    }
  }

  String _getVehicleDescription(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'Petites entrées, stationnements';
      case VehicleType.truck:
        return 'Grandes entrées, équipement lourd';
      case VehicleType.atv:
        return 'Accès difficile, terrains variés';
      case VehicleType.other:
        return 'Autre type de véhicule';
    }
  }

  void _showAddZoneDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une zone'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom de la zone',
            hintText: 'Ex: Trois-Rivières Ouest',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add zone logic
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      // Build equipment list
      final equipment = <String>[];
      if (_hasShovel) equipment.add('shovel');
      if (_hasBrush) equipment.add('brush');
      if (_hasIceScraper) equipment.add('ice_scraper');
      if (_hasSaltSpreader) equipment.add('salt_spreader');
      if (_hasSnowBlower) equipment.add('snow_blower');

      context.read<WorkerAvailabilityBloc>().add(
        UpdateProfile(
          vehicleType: _selectedVehicle,
          equipmentList: equipment,
          maxActiveJobs: _maxActiveJobs,
        ),
      );
    }
  }
}
