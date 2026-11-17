import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/vehicule_bloc.dart';
import '../widgets/vehicle_visuals.dart';

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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.vehicle_myVehicles,
            style: AppTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  /// Ouvre l'ajout de vehicule et recharge la liste au retour.
  Future<void> _openAddVehicle(BuildContext context) async {
    final result = await Navigator.pushNamed(context, AppRoutes.addVehicle);
    if (result == true && context.mounted) {
      context.read<VehicleBloc>().add(LoadVehicles());
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateWidget(
      illustrationType: IllustrationType.emptyVehicles,
      title: l10n.vehicle_empty,
      subtitle: l10n.vehicle_emptySubtitle,
      buttonText: l10n.vehicle_add,
      onButtonPressed: () => _openAddVehicle(context),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            _buildVehiclePhoto(context, vehicle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vehicle.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.headlineSmall,
                        ),
                      ),
                      if (vehicle.isDefault) ...[
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: l10n.common_default,
                          color: AppTheme.textSecondary,
                          small: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      VehicleColorDot(colorName: vehicle.color),
                      const SizedBox(width: 6),
                      Text(vehicle.color, style: AppTheme.bodySmall),
                      if (vehicle.licensePlate != null) ...[
                        const SizedBox(width: 10),
                        LicensePlate(plate: vehicle.licensePlate!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!vehicle.isDefault)
              IconButton(
                onPressed: () => _showDeleteConfirmation(context, vehicle.id),
                tooltip: l10n.common_delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclePhoto(BuildContext context, Vehicle vehicle) {
    final hasPhoto = vehicle.photoUrl != null && vehicle.photoUrl!.isNotEmpty;
    final photoUrl =
        hasPhoto ? '${AppConfig.apiBaseUrl}${vehicle.photoUrl}' : null;
    final typeIcon = Center(
      child: Icon(
        vehicleTypeIcon(vehicle.type),
        size: 26,
        color: AppTheme.textSecondary,
      ),
    );

    return GestureDetector(
      onTap: () => _showPhotoOptions(context, vehicle),
      child: Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => typeIcon,
                    errorWidget: (context, url, error) => typeIcon,
                  )
                : typeIcon,
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, Vehicle vehicle) {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.vehicle_photoTitle,
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.vehicle_photoDescription,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: AppTheme.primary),
                  title: Text(l10n.vehicle_takePhoto),
                  subtitle: Text(
                    l10n.vehicle_takePhotoSubtitle,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickAndUploadPhoto(context, vehicle, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppTheme.primary),
                  title: Text(l10n.vehicle_choosePhoto),
                  subtitle: Text(
                    l10n.vehicle_choosePhotoSubtitle,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
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
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton.icon(
        onPressed: () => _openAddVehicle(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context)!.vehicle_add),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String vehicleId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vehicle_deleteTitle),
        content: Text(l10n.vehicle_deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<VehicleBloc>().add(DeleteVehicle(vehicleId));
              Navigator.pop(dialogContext);
            },
            child: Text(
              l10n.common_delete,
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
