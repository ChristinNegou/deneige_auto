
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/vehicule_bloc.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();

  String _selectedType = 'sedan';
  bool _isDefault = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VehicleBloc(getVehicles: sl()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajouter un véhicule'),
        ),
        body: BlocConsumer<VehicleBloc, VehicleState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Instructions
                  Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Remplissez les informations de votre véhicule',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Marque
                  TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(
                      labelText: 'Marque *',
                      hintText: 'Ex: Toyota',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La marque est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Modèle
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Modèle *',
                      hintText: 'Ex: Camry',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le modèle est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Année
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Année *',
                      hintText: 'Ex: 2020',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'année est requise';
                      }
                      final year = int.tryParse(value);
                      if (year == null) {
                        return 'Année invalide';
                      }
                      final currentYear = DateTime.now().year;
                      if (year < 1900 || year > currentYear + 1) {
                        return 'Année invalide (1900-${currentYear + 1})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Couleur
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      labelText: 'Couleur *',
                      hintText: 'Ex: Noir',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.palette),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La couleur est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Plaque d'immatriculation
                  TextFormField(
                    controller: _licensePlateController,
                    decoration: const InputDecoration(
                      labelText: 'Plaque d\'immatriculation *',
                      hintText: 'Ex: ABC 123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La plaque est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type de véhicule
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type de véhicule *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'sedan',
                        child: Row(
                          children: [
                            Text('🚗', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('Berline'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'suv',
                        child: Row(
                          children: [
                            Text('🚙', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('VUS'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'truck',
                        child: Row(
                          children: [
                            Text('🛻', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('Camionnette'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'van',
                        child: Row(
                          children: [
                            Text('🚐', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('Fourgonnette'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'coupe',
                        child: Row(
                          children: [
                            Text('🏎️', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('Coupé'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'hatchback',
                        child: Row(
                          children: [
                            Text('🚗', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('À hayon'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Véhicule par défaut
                  SwitchListTile(
                    title: const Text('Définir comme véhicule par défaut'),
                    subtitle: const Text(
                      'Ce véhicule sera pré-sélectionné lors de nouvelles réservations',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() => _isDefault = value);
                    },
                    secondary: const Icon(Icons.star),
                  ),
                  const SizedBox(height: 32),

                  // Bouton d'ajout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text('Ajouter le véhicule'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Créer l'entité Vehicle et l'ajouter via BLoC
      // Pour l'instant, afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Véhicule ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}