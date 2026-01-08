import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reservation/domain/entities/vehicle.dart';
import '../../../reservation/domain/usecases/add_vehicle_usecase.dart'
    show AddVehicleParams;
import '../bloc/vehicule_bloc.dart';

class AddVehiclePage extends StatelessWidget {
  const AddVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<VehicleBloc>(),
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
  final _licensePlateController = TextEditingController();
  VehicleType _selectedType = VehicleType.car;
  String _selectedColor = 'Blanc';
  bool _isDefault = false;
  File? _selectedPhoto;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Blanc', 'color': AppTheme.textPrimary},
    {'name': 'Noir', 'color': AppTheme.shadowColor},
    {'name': 'Gris', 'color': AppTheme.textTertiary},
    {'name': 'Argent', 'color': const Color(0xFFC0C0C0)},
    {'name': 'Rouge', 'color': AppTheme.error},
    {'name': 'Bleu', 'color': AppTheme.info},
    {'name': 'Vert', 'color': AppTheme.success},
    {'name': 'Brun', 'color': const Color(0xFF795548)},
    {'name': 'Beige', 'color': const Color(0xFFF5F5DC)},
  ];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocConsumer<VehicleBloc, VehicleState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                ),
              );
            }

            if (state.successMessage != null) {
              // Check if we have a photo to upload after vehicle creation
              if (state.successMessage == 'Véhicule ajouté avec succès' &&
                  _selectedPhoto != null &&
                  state.vehicles.isNotEmpty) {
                // Get the newly created vehicle ID
                final newVehicle = state.vehicles.last;
                context.read<VehicleBloc>().add(
                  UploadVehiclePhoto(vehicleId: newVehicle.id, photo: _selectedPhoto!),
                );
                return; // Wait for photo upload to complete
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                ),
              );
              Navigator.pop(context, true);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.paddingXL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildVehiclePreview(),
                          const SizedBox(height: 24),
                          _buildFormCard(state),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.shadowSM,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Ajouter un véhicule',
            style: AppTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowMD,
      ),
      child: Column(
        children: [
          // Clickable photo/icon area
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedPhoto != null
                      ? Image.file(
                          _selectedPhoto!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        )
                      : Center(
                          child: Text(
                            _selectedType.icon,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                ),
                // Camera icon overlay
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 2),
                      boxShadow: AppTheme.shadowSM,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Touchez pour ajouter une photo',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _makeController.text.isNotEmpty || _modelController.text.isNotEmpty
                ? '${_makeController.text} ${_modelController.text}'.trim()
                : 'Nouveau véhicule',
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _colors.firstWhere(
                      (c) => c['name'] == _selectedColor)['color'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedColor,
                style: AppTheme.bodySmall,
              ),
              if (_licensePlateController.text.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _licensePlateController.text.toUpperCase(),
                    style: AppTheme.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Photo du véhicule',
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cette photo sera visible par le déneigeur',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                  ),
                  title: const Text('Prendre une photo'),
                  subtitle: Text(
                    'Utiliser l\'appareil photo',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppTheme.info),
                  ),
                  title: const Text('Choisir une photo'),
                  subtitle: Text(
                    'Depuis la galerie',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                if (_selectedPhoto != null)
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_rounded, color: AppTheme.error),
                    ),
                    title: const Text('Supprimer la photo'),
                    subtitle: Text(
                      'Retirer la photo sélectionnée',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      setState(() => _selectedPhoto = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }

  Widget _buildFormCard(VehicleState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Marque et Modèle
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _makeController,
                  label: 'Marque',
                  hint: 'Toyota',
                  icon: Icons.directions_car_rounded,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _modelController,
                  label: 'Modèle',
                  hint: 'Camry',
                  icon: Icons.directions_car_outlined,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Année et Plaque
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _yearController,
                  label: 'Année',
                  hint: '2024',
                  icon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Requis';
                    final year = int.tryParse(value!);
                    if (year == null ||
                        year < 1900 ||
                        year > DateTime.now().year + 1) {
                      return 'Invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _licensePlateController,
                  label: 'Plaque',
                  hint: 'ABC 123',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type de véhicule
          Text(
            'Type de véhicule',
            style: AppTheme.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Row(
              children: VehicleType.values.map((type) {
                final isSelected = type == _selectedType;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Column(
                        children: [
                          Text(
                            type.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.background
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Couleur
          Text(
            'Couleur',
            style: AppTheme.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colors.map((colorData) {
              final isSelected = colorData['name'] == _selectedColor;
              return GestureDetector(
                onTap: () => setState(
                    () => _selectedColor = colorData['name'] as String),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorData['color'] as Color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: colorData['name'] == 'Blanc' ||
                                  colorData['name'] == 'Beige'
                              ? AppTheme.primary
                              : AppTheme.background,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Véhicule par défaut
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: CheckboxListTile(
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value ?? false),
              activeColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              title: Text(
                'Définir comme véhicule par défaut',
                style:
                    AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w500),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const SizedBox(height: 24),

          // Bouton Ajouter
          _buildSubmitButton(state),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: AppTheme.bodyMedium.copyWith(fontSize: 14),
          validator: validator,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 10, right: 6),
              child: Icon(icon, color: AppTheme.textTertiary, size: 18),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: AppTheme.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: const BorderSide(color: AppTheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(VehicleState state) {
    return GestureDetector(
      onTap: state.isSubmitting ? null : _submitForm,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: !state.isSubmitting
              ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: state.isSubmitting ? AppTheme.border : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: !state.isSubmitting
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: state.isSubmitting
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppTheme.background,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: AppTheme.background,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ajouter le véhicule',
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final params = AddVehicleParams(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        color: _selectedColor,
        licensePlate: _licensePlateController.text.trim().toUpperCase(),
        type: _selectedType,
        isDefault: _isDefault,
      );

      context.read<VehicleBloc>().add(AddVehicle(params));
    }
  }
}
