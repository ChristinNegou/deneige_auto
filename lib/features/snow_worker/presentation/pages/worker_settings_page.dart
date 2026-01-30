import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/worker_availability_bloc.dart';
import '../../domain/entities/worker_profile.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart' show LogoutRequested;

class WorkerSettingsPage extends StatelessWidget {
  const WorkerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<WorkerAvailabilityBloc>()..add(const LoadAvailability()),
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
  final LocaleService _localeService = sl<LocaleService>();
  bool _initialized = false;

  // Equipment checkboxes
  bool _hasShovel = false;
  bool _hasBrush = false;
  bool _hasIceScraper = false;
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
  List<String> _zones = [];

  void _initializeFromProfile(WorkerProfile profile) {
    if (_initialized) return;
    _initialized = true;

    // Load equipment from profile
    final equipment = profile.equipmentList;
    _hasShovel = equipment.contains('shovel');
    _hasBrush = equipment.contains('brush');
    _hasIceScraper = equipment.contains('ice_scraper');
    _hasSaltSpreader = equipment.contains('salt_spreader');
    _hasSnowBlower = equipment.contains('snow_blower');

    // Load other settings
    _selectedVehicle = profile.vehicleType;
    _maxActiveJobs = profile.maxActiveJobs;
    _zones = profile.preferredZones.map((z) => z.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocConsumer<WorkerAvailabilityBloc, WorkerAvailabilityState>(
          listener: (context, state) {
            if (state is WorkerAvailabilityError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.background, size: 20),
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

            // Initialize from profile when loaded (use addPostFrameCallback to avoid setState during build)
            if (state is WorkerAvailabilityLoaded &&
                state.profile != null &&
                !_initialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _initializeFromProfile(state.profile!);
                  setState(() {});
                }
              });
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
                          const SizedBox(height: 16),
                          _buildLanguageSection(),
                          const SizedBox(height: 16),
                          _buildHelpSupportSection(context),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.settings_title,
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
                  l10n.worker_badge,
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
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.workerPaymentSetup),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.success, AppTheme.success.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: [
            BoxShadow(
              color: AppTheme.success.withValues(alpha: 0.3),
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
                color: AppTheme.background.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: AppTheme.background,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.worker_myPayments,
                    style: TextStyle(
                      color: AppTheme.background,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.worker_configureBankAccount,
                    style: TextStyle(
                      color: AppTheme.background.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.background,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSection() {
    final l10n = AppLocalizations.of(context)!;
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
              AppIllustration(
                type: IllustrationType.workerEquipment,
                width: 44,
                height: 44,
              ),
              const SizedBox(width: 12),
              Text(l10n.worker_myEquipment, style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildEquipmentItem(
            icon: '🪣',
            label: l10n.worker_snowShovel,
            value: _hasShovel,
            onChanged: (val) => setState(() => _hasShovel = val!),
          ),
          _buildEquipmentItem(
            icon: '🧹',
            label: l10n.worker_snowBroom,
            value: _hasBrush,
            onChanged: (val) => setState(() => _hasBrush = val!),
          ),
          _buildEquipmentItem(
            icon: '🪟',
            label: l10n.worker_iceScraper,
            value: _hasIceScraper,
            onChanged: (val) => setState(() => _hasIceScraper = val!),
          ),
          _buildEquipmentItem(
            icon: '🧂',
            label: l10n.worker_saltSpreaderLabel,
            value: _hasSaltSpreader,
            onChanged: (val) => setState(() => _hasSaltSpreader = val!),
          ),
          _buildEquipmentItem(
            icon: '❄️',
            label: l10n.worker_snowBlowerLabel,
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
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? AppTheme.success : AppTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: value
                        ? null
                        : Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: value
                      ? Icon(Icons.check, color: AppTheme.background, size: 16)
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
    final l10n = AppLocalizations.of(context)!;
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
                child: const Icon(Icons.directions_car_rounded,
                    color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(l10n.worker_myVehicle, style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          ...VehicleType.values.map((type) => _buildVehicleOption(type)),
        ],
      ),
    );
  }

  Widget _buildVehicleOption(VehicleType type) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedVehicle == type;
    final emoji = _getVehicleEmoji(type);

    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.background,
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
                    _getVehicleLabel(l10n, type),
                    style: AppTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getVehicleDescription(l10n, type),
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
                color: isSelected ? AppTheme.primary : AppTheme.background,
                border: isSelected
                    ? null
                    : Border.all(color: AppTheme.textTertiary, width: 2),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: AppTheme.background, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkPreferencesSection() {
    final l10n = AppLocalizations.of(context)!;
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
                child: const Icon(Icons.tune_rounded,
                    color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(l10n.worker_workPreferences, style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.worker_maxSimultaneousJobs,
            style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.worker_maxSimultaneousJobsDesc,
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
                l10n.worker_recommendedJobs,
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
    final l10n = AppLocalizations.of(context)!;
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
                child: const Icon(Icons.location_on_rounded,
                    color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.worker_preferredZones,
                        style: AppTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      l10n.worker_priorityNotifications,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.common_add,
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
    final l10n = AppLocalizations.of(context)!;
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
                child: const Icon(Icons.notifications_rounded,
                    color: AppTheme.info, size: 20),
              ),
              const SizedBox(width: 12),
              Text(l10n.worker_notifications, style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildNotificationToggle(
            icon: Icons.work_outline_rounded,
            title: l10n.worker_notifNewJobs,
            subtitle: l10n.worker_notifNewJobsDesc,
            value: _notifyNewJobs,
            onChanged: (val) => setState(() => _notifyNewJobs = val),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _buildNotificationToggle(
            icon: Icons.priority_high_rounded,
            title: l10n.worker_notifUrgentJobs,
            subtitle: l10n.worker_notifUrgentJobsDesc,
            value: _notifyUrgentJobs,
            onChanged: (val) => setState(() => _notifyUrgentJobs = val),
            iconColor: AppTheme.error,
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _buildNotificationToggle(
            icon: Icons.monetization_on_outlined,
            title: l10n.worker_notifTipsReceived,
            subtitle: l10n.worker_tipsReceived,
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
                  style:
                      AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
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
                border:
                    value ? null : Border.all(color: AppTheme.border, width: 2),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColor.withValues(alpha: 0.1),
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

  void _changeLanguage(String languageCode) {
    _localeService.setLocale(Locale(languageCode));
  }

  Widget _buildLanguageSection() {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = _localeService.locale.languageCode;
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
                child: const Icon(Icons.language_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    Text(l10n.settings_language, style: AppTheme.headlineSmall),
              ),
              DropdownButton<String>(
                value: currentLanguage,
                underline: const SizedBox(),
                dropdownColor: AppTheme.surface,
                items: [
                  DropdownMenuItem(
                      value: 'fr', child: Text(l10n.settings_languageFrench)),
                  DropdownMenuItem(
                      value: 'en', child: Text(l10n.settings_languageEnglish)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _changeLanguage(value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSupportSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.workerHelpSupport),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: AppTheme.info,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.worker_helpSupport,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profile_helpSubtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final l10n = AppLocalizations.of(context)!;
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
            Icon(Icons.save_rounded, color: AppTheme.background, size: 22),
            const SizedBox(width: 10),
            Text(
              l10n.common_save,
              style: TextStyle(
                color: AppTheme.background,
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

  String _getVehicleLabel(AppLocalizations l10n, VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return l10n.worker_vehicleCar;
      case VehicleType.truck:
        return l10n.worker_vehicleTruck;
      case VehicleType.atv:
        return l10n.worker_vehicleAtv;
      case VehicleType.other:
        return l10n.worker_vehicleOther;
    }
  }

  String _getVehicleDescription(AppLocalizations l10n, VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return l10n.worker_vehicleCarDesc;
      case VehicleType.truck:
        return l10n.worker_vehicleTruckDesc;
      case VehicleType.atv:
        return l10n.worker_vehicleAtvDesc;
      case VehicleType.other:
        return l10n.worker_otherVehicleType;
    }
  }

  void _showAddZoneDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          title: Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(dialogL10n.worker_addZone),
            ],
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: dialogL10n.worker_zoneName,
              hintText: dialogL10n.worker_zoneHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                dialogL10n.common_cancel,
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
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              child: Text(dialogL10n.common_add),
            ),
          ],
        );
      },
    );
  }

  void _saveSettings() {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
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
    final l10n = AppLocalizations.of(context)!;
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
                child: const Icon(Icons.logout_rounded,
                    color: AppTheme.error, size: 20),
              ),
              const SizedBox(width: 12),
              Text(l10n.worker_account, style: AppTheme.headlineSmall),
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
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    l10n.common_logout,
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
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
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
                child:
                    Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
              ),
              const SizedBox(width: 12),
              Text(dialogL10n.common_logout),
            ],
          ),
          content: Text(
            dialogL10n.worker_logoutConfirmWorker,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                dialogL10n.common_cancel,
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
                foregroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              child: Text(dialogL10n.common_logout),
            ),
          ],
        );
      },
    );
  }
}
