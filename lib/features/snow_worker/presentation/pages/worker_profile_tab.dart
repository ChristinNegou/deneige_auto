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
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart' show LogoutRequested;
import '../../../disputes/presentation/pages/my_disputes_page.dart';

/// Profil du deneigeur : equipement, limite de travaux, notifications,
/// theme, langue et compte. Chaque changement est enregistre tout seul.
///
/// L'ecran garde son propre etat : le bloc ne sert qu'au chargement initial,
/// a l'envoi des changements et aux erreurs.
class WorkerProfileTab extends StatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  State<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

/// Les cles d'equipement du serveur, dans l'ordre d'affichage.
const _equipmentKeys = [
  'shovel',
  'brush',
  'ice_scraper',
  'salt_spreader',
  'snow_blower',
  'roof_broom',
  'microfiber_cloth',
  'deicer_spray',
];

class _WorkerProfileTabState extends State<WorkerProfileTab>
    with AutomaticKeepAliveClientMixin {
  final _imagePicker = ImagePicker();
  final LocaleService _localeService = sl<LocaleService>();
  final ThemeService _themeService = sl<ThemeService>();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isUploadingPhoto = false;
  String? _photoUrl;

  final Set<String> _equipment = {};
  int _maxActiveJobs = 3;
  bool _notifyNewJobs = true;
  bool _notifyTips = true;

  Timer? _debounceTimer;
  bool _isSaving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadProfile() {
    final bloc = context.read<WorkerAvailabilityBloc>();
    final currentState = bloc.state;
    if (currentState is WorkerAvailabilityLoaded &&
        currentState.profile != null) {
      _initializeFromProfile(currentState.profile!);
      setState(() => _isLoading = false);
    } else {
      bloc.add(const LoadAvailability());
    }
  }

  void _initializeFromProfile(WorkerProfile profile) {
    _photoUrl = profile.photoUrl;
    _equipment
      ..clear()
      ..addAll(profile.equipmentList.where(_equipmentKeys.contains));
    _maxActiveJobs = profile.maxActiveJobs;
    _notifyNewJobs = profile.notificationPreferences.newJobs;
    _notifyTips = profile.notificationPreferences.tips;
  }

  /// Change une valeur puis enregistre apres une courte pause (plusieurs
  /// touches rapides = un seul envoi).
  void _update(VoidCallback change) {
    setState(change);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_isSaving) _saveSettings();
    });
  }

  void _saveSettings() {
    _isSaving = true;
    context.read<WorkerAvailabilityBloc>().add(
          UpdateProfile(
            equipmentList: _equipmentKeys.where(_equipment.contains).toList(),
            maxActiveJobs: _maxActiveJobs,
            notificationPreferences: WorkerNotificationPreferences(
              newJobs: _notifyNewJobs,
              tips: _notifyTips,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: BlocListener<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        listener: (context, state) {
          if (state is WorkerAvailabilityLoaded && _isLoading) {
            if (state.profile != null) _initializeFromProfile(state.profile!);
            setState(() {
              _isLoading = false;
              _hasError = false;
            });
          }

          if (state is WorkerAvailabilityError) {
            if (_isLoading) {
              setState(() {
                _hasError = true;
                _errorMessage = state.message;
                _isLoading = false;
              });
            } else {
              _isSaving = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }

          if (state is WorkerProfileUpdated) {
            _isSaving = false;
            _photoUrl = state.profile.photoUrl;
          }

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

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 40, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
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
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 28),
        _SectionTitle(l10n.worker_myEquipment),
        _Group(children: [_buildEquipment(l10n)]),
        const SizedBox(height: 24),
        _SectionTitle(l10n.workerP_work),
        _Group(children: [
          _Row(
            title: l10n.workerP_maxJobs,
            subtitle: l10n.workerP_maxJobsHelp,
            trailing: _Counter(
              value: _maxActiveJobs,
              min: 1,
              max: 5,
              onChanged: (v) => _update(() => _maxActiveJobs = v),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _SectionTitle(l10n.worker_notifications),
        _Group(children: [
          _Row(
            title: l10n.workerP_newJobs,
            subtitle: l10n.workerP_newJobsHelp,
            trailing: Switch(
              value: _notifyNewJobs,
              onChanged: (v) => _update(() => _notifyNewJobs = v),
            ),
            onTap: () => _update(() => _notifyNewJobs = !_notifyNewJobs),
          ),
          _Row(
            title: l10n.workerP_tips,
            subtitle: l10n.workerP_tipsHelp,
            trailing: Switch(
              value: _notifyTips,
              onChanged: (v) => _update(() => _notifyTips = v),
            ),
            onTap: () => _update(() => _notifyTips = !_notifyTips),
          ),
        ]),
        const SizedBox(height: 24),
        _SectionTitle(l10n.workerP_app),
        _Group(children: [
          _Row(
            icon: Icons.dark_mode_outlined,
            title: l10n.settings_darkTheme,
            trailing: Switch(
              value: _themeService.isDark,
              onChanged: _themeService.setDark,
            ),
            onTap: () => _themeService.setDark(!_themeService.isDark),
          ),
          _Row(
            icon: Icons.language_rounded,
            title: l10n.settings_language,
            trailing: DropdownButton<String>(
              value: _localeService.locale.languageCode,
              underline: const SizedBox(),
              dropdownColor: AppTheme.surfaceElevated,
              isDense: true,
              style: AppTheme.labelLarge,
              items: [
                DropdownMenuItem(
                    value: 'fr', child: Text(l10n.settings_languageFrench)),
                DropdownMenuItem(
                    value: 'en', child: Text(l10n.settings_languageEnglish)),
              ],
              onChanged: (value) {
                if (value != null) _localeService.setLocale(Locale(value));
              },
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _SectionTitle(l10n.worker_account),
        _Group(children: [
          _Row(
            icon: Icons.gavel_outlined,
            title: l10n.profile_myDisputes,
            trailing:
                Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyDisputesPage()),
            ),
          ),
          _Row(
            icon: Icons.help_outline_rounded,
            title: l10n.worker_helpSupport,
            trailing:
                Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.workerHelpSupport),
          ),
          _Row(
            icon: Icons.logout_rounded,
            title: l10n.common_logout,
            destructive: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ]),
      ],
    );
  }

  Widget _buildEquipment(AppLocalizations l10n) {
    final labels = {
      'shovel': l10n.worker_equipShovel,
      'brush': l10n.worker_equipBroom,
      'ice_scraper': l10n.worker_equipScraper,
      'salt_spreader': l10n.worker_equipSaltSpreader,
      'snow_blower': l10n.worker_equipSnowBlower,
      'roof_broom': l10n.worker_equipRoofBroom,
      'microfiber_cloth': l10n.worker_equipCloth,
      'deicer_spray': l10n.worker_equipDeicer,
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.workerP_equipmentHelp, style: AppTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in _equipmentKeys)
                FilterChip(
                  label: Text(labels[key]!),
                  selected: _equipment.contains(key),
                  showCheckmark: true,
                  checkmarkColor: AppTheme.onPrimary,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  labelStyle: AppTheme.labelMedium.copyWith(
                    color: _equipment.contains(key)
                        ? AppTheme.onPrimary
                        : AppTheme.textPrimary,
                  ),
                  side: BorderSide(
                    color: _equipment.contains(key)
                        ? AppTheme.primary
                        : AppTheme.border,
                  ),
                  onSelected: (selected) => _update(() =>
                      selected ? _equipment.add(key) : _equipment.remove(key)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        var userName = l10n.worker_badge;
        var userEmail = '';
        var userPhone = '';
        if (authState is AuthAuthenticated) {
          userName = authState.user.name;
          userEmail = authState.user.email;
          userPhone = authState.user.phoneNumber ?? '';
        }

        return Row(
          children: [
            GestureDetector(
              onTap: _isUploadingPhoto ? null : _showPhotoOptions,
              child: Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: _isUploadingPhoto
                          ? Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.onPrimary,
                                ),
                              ),
                            )
                          : _photoUrl != null && _photoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _photoUrl!,
                                  fit: BoxFit.cover,
                                  width: 72,
                                  height: 72,
                                  placeholder: (_, __) =>
                                      _buildInitials(userName),
                                  errorWidget: (_, __, ___) =>
                                      _buildInitials(userName),
                                )
                              : _buildInitials(userName),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(Icons.photo_camera_outlined,
                          size: 14, color: AppTheme.textPrimary),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          userName,
                          style: AppTheme.headlineMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isUserVerified(authState)) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.verified_rounded,
                            color: AppTheme.info, size: 18),
                      ],
                    ],
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(userEmail,
                        style: AppTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (userPhone.isNotEmpty)
                    Text(userPhone, style: AppTheme.bodySmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'D',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppTheme.onPrimary,
        ),
      ),
    );
  }

  bool _isUserVerified(AuthState authState) {
    if (authState is AuthAuthenticated && authState.user.isVerified) {
      return true;
    }
    final workerState = context.read<WorkerAvailabilityBloc>().state;
    if (workerState is WorkerAvailabilityLoaded) {
      return workerState.profile?.isVerified ?? false;
    }
    return false;
  }

  void _showPhotoOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.vehicle_takePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.vehicle_choosePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
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
      final photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (photo != null && mounted) {
        context
            .read<WorkerAvailabilityBloc>()
            .add(UploadProfilePhoto(File(photo.path)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.worker_photoSelectionError),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.common_logout),
        content: Text(l10n.common_logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel,
                style: TextStyle(color: AppTheme.textSecondary)),
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
            child: Text(l10n.common_logout,
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: AppTheme.headlineSmall),
    );
  }
}

/// Carte qui regroupe des lignes, separees par un trait fin.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppTheme.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const _Row({
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.error : AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 20,
                  color: destructive ? color : AppTheme.textSecondary),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.labelLarge.copyWith(color: color)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Counter({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, bool enabled, int next) => IconButton(
          onPressed: enabled ? () => onChanged(next) : null,
          icon: Icon(icon, size: 18),
          color: AppTheme.textPrimary,
          disabledColor: AppTheme.textDisabled,
          visualDensity: VisualDensity.compact,
        );
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove_rounded, value > min, value - 1),
          SizedBox(
            width: 28,
            child: Text('$value',
                textAlign: TextAlign.center, style: AppTheme.headlineSmall),
          ),
          button(Icons.add_rounded, value < max, value + 1),
        ],
      ),
    );
  }
}
