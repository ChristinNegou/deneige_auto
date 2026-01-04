import 'package:deneige_auto/features/reservation/domain/entities/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      statusBarIconBrightness: Brightness.dark,
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
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
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
          // Vehicle icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Center(
              child: Text(
                vehicle.type.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
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
