import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reservation/domain/entities/vehicle.dart';
import '../../../reservation/domain/usecases/add_vehicle_usecase.dart'
    show AddVehicleParams;
import '../bloc/vehicule_bloc.dart';
import '../widgets/vehicle_visuals.dart';

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

  /// Couleurs proposees ; la teinte affichee vient de [vehicleBodyColor].
  /// Rangees des neutres aux teintes chaudes puis froides.
  static const List<String> _colors = [
    'Blanc',
    'Blanc nacré',
    'Argent',
    'Gris',
    'Gris foncé',
    'Noir',
    'Beige',
    'Champagne',
    'Brun',
    'Bronze',
    'Or',
    'Jaune',
    'Orange',
    'Rouge',
    'Bordeaux',
    'Rose',
    'Violet',
    'Bleu ciel',
    'Bleu',
    'Bleu marine',
    'Turquoise',
    'Vert',
    'Vert foncé',
  ];

  /// Couleurs claires : la coche doit etre foncee pour rester visible.
  static const Set<String> _lightColors = {
    'Blanc',
    'Blanc nacré',
    'Argent',
    'Beige',
    'Champagne',
    'Or',
    'Jaune',
    'Rose',
    'Bleu ciel',
  };

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
              if (state.successMessage == 'vehicle_added_flag' &&
                  _selectedPhoto != null &&
                  state.vehicles.isNotEmpty) {
                // Get the newly created vehicle ID
                final newVehicle = state.vehicles.last;
                context.read<VehicleBloc>().add(
                      UploadVehiclePhoto(
                          vehicleId: newVehicle.id, photo: _selectedPhoto!),
                    );
                return; // Wait for photo upload to complete
              }

              Navigator.pop(context, true);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildVehiclePreview(),
                          const SizedBox(height: 28),
                          _buildFormCard(state),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(top: BorderSide(color: AppTheme.divider)),
                  ),
                  child: _buildSubmitButton(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.addVehicle_title,
            style: AppTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  /// Apercu en direct du vehicule saisi : photo ou icone, nom, couleur, plaque.
  Widget _buildVehiclePreview() {
    final name = '${_makeController.text} ${_modelController.text}'.trim();
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedPhoto != null
                      ? Image.file(
                          _selectedPhoto!,
                          fit: BoxFit.cover,
                          width: 76,
                          height: 76,
                        )
                      : Icon(
                          vehicleTypeIcon(_selectedType),
                          size: 34,
                          color: AppTheme.textSecondary,
                        ),
                ),
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty
                      ? name
                      : AppLocalizations.of(context)!.addVehicle_newVehicle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headlineSmall.copyWith(
                    color: name.isNotEmpty
                        ? AppTheme.textPrimary
                        : AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    VehicleColorDot(colorName: _selectedColor),
                    const SizedBox(width: 6),
                    Text(_selectedColor, style: AppTheme.bodySmall),
                    if (_licensePlateController.text.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child:
                            LicensePlate(plate: _licensePlateController.text),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.addVehicle_tapAddPhoto,
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.addVehicle_photoTitle,
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.addVehicle_photoVisibleWorker,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: AppTheme.primary),
                  title:
                      Text(AppLocalizations.of(context)!.addVehicle_takePhoto),
                  subtitle: Text(
                    AppLocalizations.of(context)!.addVehicle_useCamera,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppTheme.primary),
                  title: Text(
                      AppLocalizations.of(context)!.addVehicle_choosePhoto),
                  subtitle: Text(
                    AppLocalizations.of(context)!.addVehicle_fromGallery,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                if (_selectedPhoto != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error),
                    title: Text(
                        AppLocalizations.of(context)!.addVehicle_deletePhoto),
                    subtitle: Text(
                      AppLocalizations.of(context)!.addVehicle_removeSelected,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textSecondary),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Marque et Modèle
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _makeController,
                label: AppLocalizations.of(context)!.addVehicle_make,
                hint: 'Toyota',
                icon: Icons.directions_car_rounded,
                validator: (value) => value?.isEmpty ?? true
                    ? AppLocalizations.of(context)!.addVehicle_required
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _modelController,
                label: AppLocalizations.of(context)!.addVehicle_model,
                hint: 'Camry',
                icon: Icons.directions_car_outlined,
                validator: (value) => value?.isEmpty ?? true
                    ? AppLocalizations.of(context)!.addVehicle_required
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Année et Plaque
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _yearController,
                label: AppLocalizations.of(context)!.addVehicle_year,
                hint: '2024',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return AppLocalizations.of(context)!.addVehicle_required;
                  }
                  final year = int.tryParse(value!);
                  if (year == null ||
                      year < 1900 ||
                      year > DateTime.now().year + 1) {
                    return AppLocalizations.of(context)!.addVehicle_invalid;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _licensePlateController,
                label: AppLocalizations.of(context)!.addVehicle_plate,
                hint: 'ABC 123',
                icon: Icons.badge_outlined,
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value?.isEmpty ?? true
                    ? AppLocalizations.of(context)!.addVehicle_required
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Type de véhicule
        Text(
          AppLocalizations.of(context)!.addVehicle_vehicleType,
          style: AppTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(
            children: VehicleType.values.map((type) {
              final isSelected = type == _selectedType;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      boxShadow: isSelected ? AppTheme.shadowSM : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          vehicleTypeIcon(type),
                          size: 22,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppTheme.textPrimary
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
        const SizedBox(height: 24),

        // Couleur
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.addVehicle_color,
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(width: 8),
            Text(_selectedColor, style: AppTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((name) {
            final isSelected = name == _selectedColor;
            return Semantics(
              label: name,
              selected: isSelected,
              button: true,
              child: GestureDetector(
                onTap: () => setState(() => _selectedColor = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: vehicleBodyColor(name),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: _lightColors.contains(name)
                                ? AppTheme.primary
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Véhicule par défaut
        GlassCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              AppLocalizations.of(context)!.addVehicle_setDefault,
              style: AppTheme.labelLarge,
            ),
          ),
        ),
      ],
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
          style: AppTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: AppTheme.bodyLarge,
          validator: validator,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(VehicleState state) {
    return SafeArea(
      top: false,
      child: ElevatedButton(
        onPressed: state.isSubmitting ? null : _submitForm,
        child: state.isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(AppLocalizations.of(context)!.addVehicle_addBtn),
      ),
    );
  }

  void _submitForm() {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
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
