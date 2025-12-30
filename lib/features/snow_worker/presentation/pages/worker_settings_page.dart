import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/worker_availability_bloc.dart';
import '../../domain/entities/worker_profile.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart' show LogoutRequested;

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

  // Notifications
  bool _notifyNewJobs = true;
  bool _notifyUrgentJobs = true;
  bool _notifyTips = true;

  // Zones
  List<String> _zones = ['Trois-Rivières Centre', 'Cap-de-la-Madeleine'];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocConsumer<WorkerAvailabilityBloc, WorkerAvailabilityState>(
          listener: (context, state) {
            if (state is WorkerProfileUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Text('Paramètres sauvegardés'),
                    ],
                  ),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
              );
            } else if (state is WorkerAvailabilityError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is WorkerAvailabilityLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.paddingLG),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildPaymentSection(context),
                          const SizedBox(height: 16),
                          _buildEquipmentSection(),
                          const SizedBox(height: 16),
                          _buildVehicleSection(),
                          const SizedBox(height: 16),
                          _buildWorkPreferencesSection(),
                          const SizedBox(height: 16),
                          _buildZonesSection(),
                          const SizedBox(height: 16),
                          _buildNotificationsSection(),
                          const SizedBox(height: 24),
                          _buildSaveButton(),
                          const SizedBox(height: 24),
                          _buildLogoutSection(),
                          const SizedBox(height: 32),
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
            'Paramètres',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ac_unit, size: 14, color: AppTheme.warning),
                const SizedBox(width: 6),
                Text(
                  'Déneigeur',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.workerPaymentSetup),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[600]!, Colors.green[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes paiements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configurer mon compte bancaire',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.build_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Mon équipement', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildEquipmentItem(
            icon: '🪣',
            label: 'Pelle à neige',
            value: _hasShovel,
            onChanged: (val) => setState(() => _hasShovel = val!),
          ),
          _buildEquipmentItem(
            icon: '🧹',
            label: 'Balai à neige',
            value: _hasBrush,
            onChanged: (val) => setState(() => _hasBrush = val!),
          ),
          _buildEquipmentItem(
            icon: '🪟',
            label: 'Grattoir à glace',
            value: _hasIceScraper,
            onChanged: (val) => setState(() => _hasIceScraper = val!),
          ),
          _buildEquipmentItem(
            icon: '🧂',
            label: 'Épandeur de sel',
            value: _hasSaltSpreader,
            onChanged: (val) => setState(() => _hasSaltSpreader = val!),
          ),
          _buildEquipmentItem(
            icon: '❄️',
            label: 'Souffleuse',
            value: _hasSnowBlower,
            onChanged: (val) => setState(() => _hasSnowBlower = val!),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentItem({
    required String icon,
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? AppTheme.success : AppTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: value ? null : Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: value
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }

  Widget _buildVehicleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.directions_car_rounded, color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Mon véhicule', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          ...VehicleType.values.map((type) => _buildVehicleOption(type)),
        ],
      ),
    );
  }

  Widget _buildVehicleOption(VehicleType type) {
    final isSelected = _selectedVehicle == type;
    final emoji = _getVehicleEmoji(type);

    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: isSelected
              ? Border.all(color: AppTheme.primary, width: 2)
              : Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getVehicleLabel(type),
                    style: AppTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getVehicleDescription(type),
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(color: AppTheme.textTertiary, width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.tune_rounded, color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Préférences de travail', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Jobs simultanés maximum',
            style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Nombre de jobs actifs en même temps',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _maxActiveJobs > 1
                    ? () => setState(() => _maxActiveJobs--)
                    : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _maxActiveJobs > 1
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: _maxActiveJobs > 1
                        ? AppTheme.primary
                        : AppTheme.textTertiary,
                    size: 24,
                  ),
                ),
              ),
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  '$_maxActiveJobs',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _maxActiveJobs < 5
                    ? () => setState(() => _maxActiveJobs++)
                    : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _maxActiveJobs < 5
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: _maxActiveJobs < 5
                        ? AppTheme.primary
                        : AppTheme.textTertiary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.infoLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'Recommandé: 2-3 jobs',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.info,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zones préférées', style: AppTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Notifications prioritaires',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._zones.map((zone) => _buildZoneChip(zone)),
              GestureDetector(
                onTap: () => _showAddZoneDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Ajouter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneChip(String zoneName) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            zoneName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _zones.remove(zoneName);
              });
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.notifications_rounded, color: AppTheme.info, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Notifications', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildNotificationToggle(
            icon: Icons.work_outline_rounded,
            title: 'Nouveaux jobs',
            subtitle: 'Alerte pour les nouveaux jobs disponibles',
            value: _notifyNewJobs,
            onChanged: (val) => setState(() => _notifyNewJobs = val),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _buildNotificationToggle(
            icon: Icons.priority_high_rounded,
            title: 'Jobs urgents',
            subtitle: 'Alertes prioritaires',
            value: _notifyUrgentJobs,
            onChanged: (val) => setState(() => _notifyUrgentJobs = val),
            iconColor: AppTheme.error,
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _buildNotificationToggle(
            icon: Icons.monetization_on_outlined,
            title: 'Pourboires',
            subtitle: 'Notification de réception',
            value: _notifyTips,
            onChanged: (val) => setState(() => _notifyTips = val),
            iconColor: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor ?? AppTheme.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: value ? AppTheme.success : AppTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: value ? null : Border.all(color: AppTheme.border, width: 2),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveSettings,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Sauvegarder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVehicleEmoji(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return '🚗';
      case VehicleType.truck:
        return '🛻';
      case VehicleType.atv:
        return '🏍️';
      case VehicleType.other:
        return '🚙';
    }
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Row(
          children: [
            Icon(Icons.add_location_alt_rounded, color: AppTheme.primary),
            const SizedBox(width: 10),
            const Text('Ajouter une zone'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nom de la zone',
            hintText: 'Ex: Trois-Rivières Ouest',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _zones.add(controller.text);
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
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

  Widget _buildLogoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Compte', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Se déconnecter',
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion'),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de votre compte déneigeur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Déclencher la déconnexion via AuthBloc
              context.read<AuthBloc>().add(LogoutRequested());
              // Naviguer vers la page de sélection de compte
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.accountType,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
