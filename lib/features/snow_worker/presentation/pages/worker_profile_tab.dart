import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/worker_availability_bloc.dart';
import '../../domain/entities/worker_profile.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart' show LogoutRequested;

class WorkerProfileTab extends StatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  State<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends State<WorkerProfileTab>
    with AutomaticKeepAliveClientMixin {
  final _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;
  bool _initialized = false;
  Timer? _debounceTimer;
  bool _isSaving = false;

  // Equipment checkboxes
  bool _hasShovel = false;
  bool _hasBrush = false;
  bool _hasIceScraper = false;
  bool _hasSaltSpreader = false;
  bool _hasSnowBlower = false;
  bool _hasRoofBroom = false;
  bool _hasMicrofiberCloth = false;
  bool _hasDeicerSpray = false;

  // Max active jobs
  int _maxActiveJobs = 3;

  // Notifications
  bool _notifyNewJobs = true;
  bool _notifyUrgentJobs = true;
  bool _notifyTips = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerAvailabilityBloc>().add(const LoadAvailability());
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _autoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_isSaving) {
        _saveSettings();
      }
    });
  }

  void _initializeFromProfile(WorkerProfile profile) {
    if (_initialized) return;
    _initialized = true;

    final equipment = profile.equipmentList;
    _hasShovel = equipment.contains('shovel');
    _hasBrush = equipment.contains('brush');
    _hasIceScraper = equipment.contains('ice_scraper');
    _hasSaltSpreader = equipment.contains('salt_spreader');
    _hasSnowBlower = equipment.contains('snow_blower');
    _hasRoofBroom = equipment.contains('roof_broom');
    _hasMicrofiberCloth = equipment.contains('microfiber_cloth');
    _hasDeicerSpray = equipment.contains('deicer_spray');

    _maxActiveJobs = profile.maxActiveJobs;
    _notifyNewJobs = profile.notificationPreferences.newJobs;
    _notifyUrgentJobs = profile.notificationPreferences.urgentJobs;
    _notifyTips = profile.notificationPreferences.tips;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: BlocConsumer<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        listener: (context, state) {
          if (state is WorkerProfileUpdated) {
            _isSaving = false;
          } else if (state is WorkerPhotoUploading) {
            setState(() => _isUploadingPhoto = true);
          } else if (state is WorkerPhotoUploaded) {
            setState(() => _isUploadingPhoto = false);
          } else if (state is WorkerAvailabilityError) {
            final wasUploadingPhoto = _isUploadingPhoto;
            _isUploadingPhoto = false;
            _isSaving = false;
            if (wasUploadingPhoto) {
              setState(() {});
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
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

          String? photoUrl;
          if (state is WorkerAvailabilityLoaded) {
            photoUrl = state.profile?.photoUrl;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildProfileHeader(photoUrl),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Equipement',
                child: _buildEquipmentGrid(),
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: 'Preferences',
                child: _buildPreferencesContent(),
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: 'Notifications',
                child: _buildNotificationsContent(),
              ),
              const SizedBox(height: 12),
              _buildActionsList(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String? photoUrl) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Deneigeur';
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
                            : photoUrl != null && photoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: photoUrl,
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
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
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
                  'Deneigeur',
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
    final items = [
      ('Pelle', _hasShovel, (bool v) => setState(() => _hasShovel = v)),
      ('Balai', _hasBrush, (bool v) => setState(() => _hasBrush = v)),
      (
        'Grattoir',
        _hasIceScraper,
        (bool v) => setState(() => _hasIceScraper = v)
      ),
      (
        'Sel/Epandeur',
        _hasSaltSpreader,
        (bool v) => setState(() => _hasSaltSpreader = v)
      ),
      (
        'Souffleuse',
        _hasSnowBlower,
        (bool v) => setState(() => _hasSnowBlower = v)
      ),
      (
        'Balai toit',
        _hasRoofBroom,
        (bool v) => setState(() => _hasRoofBroom = v)
      ),
      (
        'Chiffon',
        _hasMicrofiberCloth,
        (bool v) => setState(() => _hasMicrofiberCloth = v)
      ),
      (
        'Deglacant',
        _hasDeicerSpray,
        (bool v) => setState(() => _hasDeicerSpray = v)
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final (label, value, onChanged) = item;
          return GestureDetector(
            onTap: () {
              onChanged(!value);
              _autoSave();
            },
            child: Container(
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
        }).toList(),
      ),
    );
  }

  Widget _buildPreferencesContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jobs simultanes max',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Nombre de jobs actifs en meme temps',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCounterButton(
                  icon: Icons.remove,
                  enabled: _maxActiveJobs > 1,
                  onTap: () {
                    setState(() => _maxActiveJobs--);
                    _autoSave();
                  },
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$_maxActiveJobs',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                _buildCounterButton(
                  icon: Icons.add,
                  enabled: _maxActiveJobs < 5,
                  onTap: () {
                    setState(() => _maxActiveJobs++);
                    _autoSave();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
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

  Widget _buildNotificationsContent() {
    return Column(
      children: [
        _buildToggleRow(
          label: 'Nouveaux jobs',
          value: _notifyNewJobs,
          onChanged: (val) {
            setState(() => _notifyNewJobs = val);
            _autoSave();
          },
        ),
        Divider(height: 1, color: AppTheme.border, indent: 14, endIndent: 14),
        _buildToggleRow(
          label: 'Jobs urgents',
          value: _notifyUrgentJobs,
          onChanged: (val) {
            setState(() => _notifyUrgentJobs = val);
            _autoSave();
          },
        ),
        Divider(height: 1, color: AppTheme.border, indent: 14, endIndent: 14),
        _buildToggleRow(
          label: 'Pourboires recus',
          value: _notifyTips,
          onChanged: (val) {
            setState(() => _notifyTips = val);
            _autoSave();
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
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
            _buildSwitch(value),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value) {
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

  Widget _buildActionsList() {
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
            label: 'Aide et support',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.workerHelpSupport),
          ),
          Divider(height: 1, color: AppTheme.border, indent: 50),
          _buildActionItem(
            icon: Icons.logout,
            label: 'Se deconnecter',
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

  void _showPhotoOptions() {
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
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir une photo'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la selection de la photo'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _saveSettings() {
    if (_isSaving) return;
    _isSaving = true;

    final equipment = <String>[];
    if (_hasShovel) equipment.add('shovel');
    if (_hasBrush) equipment.add('brush');
    if (_hasIceScraper) equipment.add('ice_scraper');
    if (_hasSaltSpreader) equipment.add('salt_spreader');
    if (_hasSnowBlower) equipment.add('snow_blower');
    if (_hasRoofBroom) equipment.add('roof_broom');
    if (_hasMicrofiberCloth) equipment.add('microfiber_cloth');
    if (_hasDeicerSpray) equipment.add('deicer_spray');

    final notificationPrefs = WorkerNotificationPreferences(
      newJobs: _notifyNewJobs,
      urgentJobs: _notifyUrgentJobs,
      tips: _notifyTips,
    );

    context.read<WorkerAvailabilityBloc>().add(
          UpdateProfile(
            equipmentList: equipment,
            maxActiveJobs: _maxActiveJobs,
            notificationPreferences: notificationPrefs,
          ),
        );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Deconnexion'),
        content: const Text(
          'Voulez-vous vraiment vous deconnecter ?',
        ),
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
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.accountType,
                (route) => false,
              );
            },
            child: Text(
              'Deconnexion',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
