import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../reservation/domain/entities/vehicle.dart';
import '../../../reservation/domain/usecases/add_vehicle_usecase.dart';
import '../bloc/vehicule_bloc.dart';

class AddVehiclePage extends StatelessWidget {
  const AddVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VehicleBloc(
        getVehicles: sl(),
        addVehicle: sl(),
      ),
      child: const AddVehicleView(),
    );
  }
}

class AddVehicleView extends StatefulWidget {
  const AddVehicleView({super.key});

  @override
  State<AddVehicleView> createState() => _AddVehicleViewState();
}

class _AddVehicleViewState extends State<AddVehicleView> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  VehicleType _selectedType = VehicleType.car;
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
    return Scaffold(
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

          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
            // Retourner à la page précédente après succès
            Navigator.pop(context, true); // true = véhicule ajouté
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _makeController,
                  decoration: const InputDecoration(
                    labelText: 'Marque',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Modèle',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'Année',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Champ requis';
                    final year = int.tryParse(value!);
                    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                      return 'Année invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Couleur',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.palette),
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licensePlateController,
                  decoration: const InputDecoration(
                    labelText: 'Plaque d\'immatriculation',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VehicleType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de véhicule',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: VehicleType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text('${type.icon} ${type.displayName}'),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedType = value ?? VehicleType.car),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Définir comme véhicule par défaut'),
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: state.isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Ajouter le véhicule'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final params = AddVehicleParams(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        color: _colorController.text.trim(),
        licensePlate: _licensePlateController.text.trim().toUpperCase(),
        type: _selectedType,
        isDefault: _isDefault,
      );

      context.read<VehicleBloc>().add(AddVehicle(params));
    }
  }
}