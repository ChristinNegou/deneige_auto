import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocConsumer<VehicleBloc, VehicleState>(
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  if (state.successMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.successMessage!),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state.isLoading && state.vehicles.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  if (state.vehicles.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<VehicleBloc>().add(LoadVehicles());
                    },
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.paddingLG),
                      itemCount: state.vehicles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.vehicles.length) {
                          return _buildAddButton(context);
                        }
                        final vehicle = state.vehicles[index];
                        return _buildVehicleCard(context, vehicle);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'Mes véhicules',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final result =
                  await Navigator.pushNamed(context, AppRoutes.addVehicle);
              if (result == true && context.mounted) {
                context.read<VehicleBloc>().add(LoadVehicles());
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: AppTheme.background,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      illustrationType: IllustrationType.emptyVehicles,
      title: 'Aucun véhicule enregistré',
      subtitle:
          'Ajoutez votre premier véhicule pour\ncommencer à utiliser le service',
      buttonText: 'Ajouter un véhicule',
      onButtonPressed: () => Navigator.pushNamed(context, AppRoutes.addVehicle),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: vehicle.isDefault
            ? Border.all(
                color: AppTheme.success.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Row(
        children: [
          // Vehicle photo or icon
          _buildVehiclePhoto(context, vehicle),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.displayName,
                        style: AppTheme.labelLarge
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (vehicle.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          'Par défaut',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getVehicleColor(vehicle.color),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vehicle.color,
                      style: AppTheme.bodySmall,
                    ),
                    if (vehicle.licensePlate != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vehicle.licensePlate!,
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
          ),
          // Delete button
          if (!vehicle.isDefault)
            GestureDetector(
              onTap: () => _showDeleteConfirmation(context, vehicle.id),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehiclePhoto(BuildContext context, Vehicle vehicle) {
    final hasPhoto = vehicle.photoUrl != null && vehicle.photoUrl!.isNotEmpty;
    final photoUrl = hasPhoto
        ? '${AppConfig.apiBaseUrl}${vehicle.photoUrl}'
        : null;

    return GestureDetector(
      onTap: () => _showPhotoOptions(context, vehicle),
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        vehicle.type.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      vehicle.type.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
          ),
          // Camera icon overlay
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 1.5),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, Vehicle vehicle) {
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
                    _pickAndUploadPhoto(context, vehicle, ImageSource.camera);
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
                    _pickAndUploadPhoto(context, vehicle, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(
    BuildContext context,
    Vehicle vehicle,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null && context.mounted) {
      final file = File(pickedFile.path);
      context.read<VehicleBloc>().add(
        UploadVehiclePhoto(vehicleId: vehicle.id, photo: file),
      );
    }
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addVehicle),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ajouter un véhicule',
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String vehicleId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: const Text('Supprimer le véhicule'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce véhicule ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<VehicleBloc>().add(DeleteVehicle(vehicleId));
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Color _getVehicleColor(String colorName) {
    final colors = {
      'Blanc': AppTheme.textPrimary,
      'Noir': AppTheme.shadowColor,
      'Gris': AppTheme.textTertiary,
      'Rouge': AppTheme.error,
      'Bleu': AppTheme.info,
      'Vert': AppTheme.success,
      'Jaune': AppTheme.warning,
      'Orange': AppTheme.warning,
      'Argent': AppTheme.textSecondary,
      'Brun': const Color(0xFF795548),
      'Beige': const Color(0xFFF5F5DC),
    };
    return colors[colorName] ?? AppTheme.textTertiary;
  }
}
