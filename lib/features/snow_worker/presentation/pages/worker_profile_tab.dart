import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/worker_availability_bloc.dart';
import '../../domain/entities/worker_profile.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart' show LogoutRequested;

/// Profile tab that uses local state management to avoid bloc-related rebuilds.
/// The bloc is only used for:
/// 1. Initial data loading (one-time)
/// 2. Dispatching save events
/// 3. Listening for errors
///
/// The UI is built entirely from local state, not from bloc state.
class WorkerProfileTab extends StatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  State<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends State<WorkerProfileTab>
    with AutomaticKeepAliveClientMixin {
  final _imagePicker = ImagePicker();
  final LocaleService _localeService = sl<LocaleService>();

  // Loading state - managed locally
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Photo upload state
  bool _isUploadingPhoto = false;

  // Profile data - managed locally, NOT from bloc
  String? _photoUrl;

  // Equipment - using ValueNotifiers for granular updates
  final _hasShovel = ValueNotifier<bool>(false);
  final _hasBrush = ValueNotifier<bool>(false);
  final _hasIceScraper = ValueNotifier<bool>(false);
  final _hasSaltSpreader = ValueNotifier<bool>(false);
  final _hasSnowBlower = ValueNotifier<bool>(false);
  final _hasRoofBroom = ValueNotifier<bool>(false);
  final _hasMicrofiberCloth = ValueNotifier<bool>(false);
  final _hasDeicerSpray = ValueNotifier<bool>(false);

  // Preferences - using ValueNotifiers
  final _maxActiveJobs = ValueNotifier<int>(3);
  final _notifyNewJobs = ValueNotifier<bool>(true);
  final _notifyUrgentJobs = ValueNotifier<bool>(true);
  final _notifyTips = ValueNotifier<bool>(true);

  // Auto-save
  Timer? _debounceTimer;
  bool _isSaving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load profile data once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hasShovel.dispose();
    _hasBrush.dispose();
    _hasIceScraper.dispose();
    _hasSaltSpreader.dispose();
    _hasSnowBlower.dispose();
    _hasRoofBroom.dispose();
    _hasMicrofiberCloth.dispose();
    _hasDeicerSpray.dispose();
    _maxActiveJobs.dispose();
    _notifyNewJobs.dispose();
    _notifyUrgentJobs.dispose();
    _notifyTips.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final bloc = context.read<WorkerAvailabilityBloc>();

    // Check if data is already loaded in bloc
    final currentState = bloc.state;
    if (currentState is WorkerAvailabilityLoaded &&
        currentState.profile != null) {
      _initializeFromProfile(currentState.profile!);
      setState(() => _isLoading = false);
    } else {
      // Request data load
      bloc.add(const LoadAvailability());
    }
  }

  void _initializeFromProfile(WorkerProfile profile) {
    _photoUrl = profile.photoUrl;

    final equipment = profile.equipmentList;
    _hasShovel.value = equipment.contains('shovel');
    _hasBrush.value = equipment.contains('brush');
    _hasIceScraper.value = equipment.contains('ice_scraper');
    _hasSaltSpreader.value = equipment.contains('salt_spreader');
    _hasSnowBlower.value = equipment.contains('snow_blower');
    _hasRoofBroom.value = equipment.contains('roof_broom');
    _hasMicrofiberCloth.value = equipment.contains('microfiber_cloth');
    _hasDeicerSpray.value = equipment.contains('deicer_spray');

    _maxActiveJobs.value = profile.maxActiveJobs;
    _notifyNewJobs.value = profile.notificationPreferences.newJobs;
    _notifyUrgentJobs.value = profile.notificationPreferences.urgentJobs;
    _notifyTips.value = profile.notificationPreferences.tips;
  }

  List<String> _getEquipmentList() {
    final equipment = <String>[];
    if (_hasShovel.value) equipment.add('shovel');
    if (_hasBrush.value) equipment.add('brush');
    if (_hasIceScraper.value) equipment.add('ice_scraper');
    if (_hasSaltSpreader.value) equipment.add('salt_spreader');
    if (_hasSnowBlower.value) equipment.add('snow_blower');
    if (_hasRoofBroom.value) equipment.add('roof_broom');
    if (_hasMicrofiberCloth.value) equipment.add('microfiber_cloth');
    if (_hasDeicerSpray.value) equipment.add('deicer_spray');
    return equipment;
  }

  void _autoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_isSaving) {
        _saveSettings();
      }
    });
  }

  void _saveSettings() {
    if (_isSaving) return;
    _isSaving = true;

    final notificationPrefs = WorkerNotificationPreferences(
      newJobs: _notifyNewJobs.value,
      urgentJobs: _notifyUrgentJobs.value,
      tips: _notifyTips.value,
    );

    context.read<WorkerAvailabilityBloc>().add(
          UpdateProfile(
            equipmentList: _getEquipmentList(),
            maxActiveJobs: _maxActiveJobs.value,
            notificationPreferences: notificationPrefs,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      // BlocListener ONLY - no rebuilding from bloc state
      child: BlocListener<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        listener: (context, state) {
          // Handle initial load completion
          if (state is WorkerAvailabilityLoaded && _isLoading) {
            if (state.profile != null) {
              _initializeFromProfile(state.profile!);
            }
            setState(() {
              _isLoading = false;
              _hasError = false;
            });
          }

          // Handle loading state (only for initial load)
          if (state is WorkerAvailabilityLoading && _isLoading) {
            // Keep showing loading
          }

          // Handle errors
          if (state is WorkerAvailabilityError) {
            if (_isLoading) {
              setState(() {
                _hasError = true;
                _errorMessage = state.message;
                _isLoading = false;
              });
            } else {
              // Error during save - just show snackbar
              _isSaving = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }

          // Handle save completion
          if (state is WorkerProfileUpdated) {
            _isSaving = false;
            // Update photo URL if it changed
            _photoUrl = state.profile.photoUrl;
          }

          // Handle photo upload states
          if (state is WorkerPhotoUploading) {
            setState(() => _isUploadingPhoto = true);
          }

          if (state is WorkerPhotoUploaded) {
            setState(() {
              _isUploadingPhoto = false;
              _photoUrl = state.photoUrl;
            });
          }
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;

    // Show loading only for initial load
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    // Show error with retry
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _loadProfile();
              },
              child: Text(l10n.common_retry),
            ),
          ],
        ),
      );
    }

    // Main content - built from local state only
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 16),
        _buildSection(
          title: l10n.worker_myEquipment,
          child: _buildEquipmentGrid(),
        ),
        const SizedBox(height: 12),
        _buildSection(
          title: l10n.worker_workPreferences,
          child: _buildPreferencesContent(),
        ),
        const SizedBox(height: 12),
        _buildSection(
          title: l10n.worker_notifications,
          child: _buildNotificationsContent(),
        ),
        const SizedBox(height: 12),
        _buildActionsList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = l10n.worker_badge;
        String userEmail = '';
        String userPhone = '';

        if (authState is AuthAuthenticated) {
          userName = authState.user.name;
          userEmail = authState.user.email;
          userPhone = authState.user.phoneNumber ?? '';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppTheme.border, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: _isUploadingPhoto
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _photoUrl != null && _photoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _photoUrl!,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                    placeholder: (context, url) =>
                                        _buildInitials(userName),
                                    errorWidget: (context, url, error) =>
                                        _buildInitials(userName),
                                  )
                                : _buildInitials(userName),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (authState is AuthAuthenticated &&
                            authState.user.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified, color: AppTheme.info, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (userEmail.isNotEmpty)
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (userPhone.isNotEmpty)
                      Text(
                        userPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.worker_badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'D',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildEquipmentGrid() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _EquipmentChip(
              label: l10n.worker_equipShovel,
              notifier: _hasShovel,
              onChanged: _autoSave),
          _EquipmentChip(
              label: l10n.worker_equipBroom,
              notifier: _hasBrush,
              onChanged: _autoSave),
          _EquipmentChip(
              label: l10n.worker_equipScraper,
              notifier: _hasIceScraper,
              onChanged: _autoSave),
          _EquipmentChip(
              label: l10n.worker_equipSaltSpreader,
              notifier: _hasSaltSpreader,
              onChanged: _autoSave),
          _EquipmentChip(
              label: l10n.worker_equipSnowBlower,
              notifier: _hasSnowBlower,
              onChanged: _autoSave),
          _EquipmentChip(
              label: l10n.worker_equipRoofBroom,
              notifier: _hasRoofBroom,
              onChanged: _autoSave),
          _EquipmentChip(
              label: l10n.worker_equipCloth,
              notifier: _hasMicrofiberCloth,
              onChanged: _autoSave),
          _EquipmentChip(
              label: l10n.worker_equipDeicer,
              notifier: _hasDeicerSpray,
              onChanged: _autoSave),
        ],
      ),
    );
  }

  Widget _buildPreferencesContent() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.worker_maxSimultaneousJobs,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  l10n.worker_maxSimultaneousJobsDesc,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          _JobCounterWidget(
            notifier: _maxActiveJobs,
            onChanged: _autoSave,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsContent() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _NotificationToggle(
          label: l10n.worker_notifNewJobs,
          notifier: _notifyNewJobs,
          onChanged: _autoSave,
        ),
        Divider(height: 1, color: AppTheme.border, indent: 14, endIndent: 14),
        _NotificationToggle(
          label: l10n.worker_notifUrgentJobs,
          notifier: _notifyUrgentJobs,
          onChanged: _autoSave,
        ),
        Divider(height: 1, color: AppTheme.border, indent: 14, endIndent: 14),
        _NotificationToggle(
          label: l10n.worker_tipsReceived,
          notifier: _notifyTips,
          onChanged: _autoSave,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildActionsList() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildActionItem(
            icon: Icons.help_outline,
            label: l10n.worker_helpSupport,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.workerHelpSupport),
          ),
          Divider(height: 1, color: AppTheme.border, indent: 50),
          _buildLanguageItem(l10n),
          Divider(height: 1, color: AppTheme.border, indent: 50),
          _buildActionItem(
            icon: Icons.logout,
            label: l10n.common_logout,
            isDestructive: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(AppLocalizations l10n) {
    final currentLanguage = _localeService.locale.languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.language, size: 20, color: AppTheme.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.settings_language,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          DropdownButton<String>(
            value: currentLanguage,
            underline: const SizedBox(),
            dropdownColor: AppTheme.surface,
            isDense: true,
            items: [
              DropdownMenuItem(
                value: 'fr',
                child: Text(l10n.settings_languageFrench),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(l10n.settings_languageEnglish),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _localeService.setLocale(Locale(value));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.vehicle_takePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.vehicle_choosePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo != null && mounted) {
        final file = File(photo.path);
        context.read<WorkerAvailabilityBloc>().add(UploadProfilePhoto(file));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.worker_photoSelectionError),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(l10n.common_logout),
        content: Text(
          l10n.common_logoutConfirm,
        ),
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
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.accountType,
                (route) => false,
              );
            },
            child: Text(
              l10n.common_logout,
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Completely isolated equipment chip widget
class _EquipmentChip extends StatelessWidget {
  final String label;
  final ValueNotifier<bool> notifier;
  final VoidCallback onChanged;

  const _EquipmentChip({
    required this.label,
    required this.notifier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return GestureDetector(
          onTap: () {
            notifier.value = !notifier.value;
            onChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value ? AppTheme.primary : AppTheme.border,
                width: value ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  value ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: value ? AppTheme.primary : AppTheme.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                    color:
                        value ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Completely isolated job counter widget
class _JobCounterWidget extends StatelessWidget {
  final ValueNotifier<int> notifier;
  final VoidCallback onChanged;

  const _JobCounterWidget({
    required this.notifier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CounterButton(
                icon: Icons.remove,
                enabled: value > 1,
                onTap: () {
                  if (value > 1) {
                    notifier.value = value - 1;
                    onChanged();
                  }
                },
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _CounterButton(
                icon: Icons.add,
                enabled: value < 5,
                onTap: () {
                  if (value < 5) {
                    notifier.value = value + 1;
                    onChanged();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.textPrimary : AppTheme.textTertiary,
        ),
      ),
    );
  }
}

/// Completely isolated notification toggle widget
class _NotificationToggle extends StatelessWidget {
  final String label;
  final ValueNotifier<bool> notifier;
  final VoidCallback onChanged;

  const _NotificationToggle({
    required this.label,
    required this.notifier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return InkWell(
          onTap: () {
            notifier.value = !notifier.value;
            onChanged();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                _AnimatedSwitch(value: value),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedSwitch extends StatelessWidget {
  final bool value;

  const _AnimatedSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: value ? AppTheme.success : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: value ? null : Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: value ? Colors.white : AppTheme.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
