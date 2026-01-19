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

  /// Auto-save avec debounce de 500ms
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

    // Load equipment from profile
    final equipment = profile.equipmentList;
    _hasShovel = equipment.contains('shovel');
    _hasBrush = equipment.contains('brush');
    _hasIceScraper = equipment.contains('ice_scraper');
    _hasSaltSpreader = equipment.contains('salt_spreader');
    _hasSnowBlower = equipment.contains('snow_blower');
    _hasRoofBroom = equipment.contains('roof_broom');
    _hasMicrofiberCloth = equipment.contains('microfiber_cloth');
    _hasDeicerSpray = equipment.contains('deicer_spray');

    // Load other settings
    _maxActiveJobs = profile.maxActiveJobs;

    // Load notification preferences
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
            setState(() => _isSaving = false);
          } else if (state is WorkerPhotoUploading) {
            setState(() => _isUploadingPhoto = true);
          } else if (state is WorkerPhotoUploaded) {
            setState(() => _isUploadingPhoto = false);
          } else if (state is WorkerAvailabilityError) {
            setState(() {
              _isUploadingPhoto = false;
              _isSaving = false;
            });
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

          // Recuperer photoUrl et phone pour le calcul de completion
          String? photoUrl;
          String userPhone = '';
          if (state is WorkerAvailabilityLoaded) {
            photoUrl = state.profile?.photoUrl;
          }
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            userPhone = authState.user.phoneNumber ?? '';
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.paddingLG),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile completion indicator (hidden when 100%)
                    _buildProfileCompletionCard(
                      photoUrl: photoUrl,
                      phoneNumber: userPhone,
                    ),
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildEquipmentSection(),
                    const SizedBox(height: 16),
                    _buildWorkPreferencesSection(),
                    const SizedBox(height: 16),
                    _buildNotificationsSection(),
                    const SizedBox(height: 16),
                    _buildHelpSupportSection(),
                    const SizedBox(height: 24),
                    _buildLogoutSection(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Calcule le pourcentage de completion du profil
  int _calculateProfileCompletion({
    required String? photoUrl,
    required String phoneNumber,
  }) {
    int score = 0;
    int total = 4; // 4 criteres principaux

    // 1. Photo de profil (25%)
    if (photoUrl != null && photoUrl.isNotEmpty) score++;

    // 2. Equipement de base - pelle et balai (25%)
    if (_hasShovel && _hasBrush) score++;

    // 3. Telephone (25%)
    if (phoneNumber.isNotEmpty) score++;

    // 4. Au moins un equipement supplementaire (25%)
    final hasExtraEquipment = _hasIceScraper ||
        _hasSaltSpreader ||
        _hasSnowBlower ||
        _hasRoofBroom ||
        _hasMicrofiberCloth ||
        _hasDeicerSpray;
    if (hasExtraEquipment) score++;

    return ((score / total) * 100).round();
  }

  /// Retourne les elements manquants du profil
  List<String> _getMissingProfileItems({
    required String? photoUrl,
    required String phoneNumber,
  }) {
    final missing = <String>[];

    if (photoUrl == null || photoUrl.isEmpty) {
      missing.add('Photo de profil');
    }
    if (!_hasShovel || !_hasBrush) {
      missing.add('Equipement de base (pelle, balai)');
    }
    if (phoneNumber.isEmpty) {
      missing.add('Numero de telephone');
    }
    final hasExtraEquipment = _hasIceScraper ||
        _hasSaltSpreader ||
        _hasSnowBlower ||
        _hasRoofBroom ||
        _hasMicrofiberCloth ||
        _hasDeicerSpray;
    if (!hasExtraEquipment) {
      missing.add('Equipement supplementaire');
    }

    return missing;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
            child: Icon(
              Icons.person_rounded,
              color: AppTheme.background,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Mon profil',
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
                Icon(Icons.local_shipping_rounded,
                    size: 14, color: AppTheme.warning),
                const SizedBox(width: 6),
                Text(
                  'Deneigeur',
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

  Widget _buildProfileCompletionCard({
    required String? photoUrl,
    required String phoneNumber,
  }) {
    final completion = _calculateProfileCompletion(
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
    );
    final missing = _getMissingProfileItems(
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
    );

    // Ne pas afficher si le profil est complet
    if (completion == 100) return const SizedBox.shrink();

    final Color progressColor;
    final IconData statusIcon;
    if (completion >= 75) {
      progressColor = AppTheme.success;
      statusIcon = Icons.check_circle_outline;
    } else if (completion >= 50) {
      progressColor = AppTheme.warning;
      statusIcon = Icons.info_outline;
    } else {
      progressColor = AppTheme.error;
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: progressColor.withValues(alpha: 0.3)),
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
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(statusIcon, color: progressColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completez votre profil',
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Augmentez vos chances de recevoir des jobs',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '$completion%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: completion / 100,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Il vous manque:',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missing.map((item) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle_outlined,
                        size: 10,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return BlocBuilder<WorkerAvailabilityBloc, WorkerAvailabilityState>(
      builder: (context, workerState) {
        String? photoUrl;
        if (workerState is WorkerAvailabilityLoaded) {
          photoUrl = workerState.profile?.photoUrl;
        }

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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Photo de profil avec bouton d'édition
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                    child: Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppTheme.background.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                            child: _isUploadingPhoto
                                ? Center(
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        color: AppTheme.background,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : photoUrl != null && photoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: photoUrl,
                                        fit: BoxFit.cover,
                                        width: 70,
                                        height: 70,
                                        placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(
                                            color: AppTheme.background,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            _buildInitialsAvatar(userName),
                                      )
                                    : _buildInitialsAvatar(userName),
                          ),
                        ),
                        // Badge d'édition
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.shadowColor
                                      .withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: AppTheme.primary,
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
                          userName,
                          style: TextStyle(
                            color: AppTheme.background,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (userEmail.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color:
                                    AppTheme.background.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  userEmail,
                                  style: TextStyle(
                                    color: AppTheme.background
                                        .withValues(alpha: 0.9),
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (userPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color:
                                    AppTheme.background.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                userPhone,
                                style: TextStyle(
                                  color: AppTheme.background
                                      .withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInitialsAvatar(String userName) {
    return Center(
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'D',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.background,
        ),
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
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Photo de profil',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child:
                      Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                ),
                title: const Text('Prendre une photo'),
                subtitle: Text(
                  'Utiliser la camera',
                  style: AppTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      color: AppTheme.secondary),
                ),
                title: const Text('Choisir une photo'),
                subtitle: Text(
                  'Depuis la galerie',
                  style: AppTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
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
            content: Text('Erreur lors de la selection de la photo'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
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
                child: const Icon(Icons.build_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mon equipement', style: AppTheme.headlineSmall),
                    Text(
                      'Cochez les outils que vous possedez',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid layout for equipment (2 columns)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: [
              _buildCompactEquipmentItem(
                icon: Icons.hardware_rounded,
                label: 'Pelle',
                value: _hasShovel,
                onChanged: (val) {
                  setState(() => _hasShovel = val);
                  _autoSave();
                },
              ),
              _buildCompactEquipmentItem(
                icon: Icons.brush_rounded,
                label: 'Balai',
                value: _hasBrush,
                onChanged: (val) {
                  setState(() => _hasBrush = val);
                  _autoSave();
                },
              ),
              _buildCompactEquipmentItem(
                icon: Icons.content_cut_rounded,
                label: 'Grattoir',
                value: _hasIceScraper,
                onChanged: (val) {
                  setState(() => _hasIceScraper = val);
                  _autoSave();
                },
              ),
              _buildCompactEquipmentItem(
                icon: Icons.grain_rounded,
                label: 'Sel/Epandeur',
                value: _hasSaltSpreader,
                onChanged: (val) {
                  setState(() => _hasSaltSpreader = val);
                  _autoSave();
                },
              ),
              _buildCompactEquipmentItem(
                icon: Icons.air_rounded,
                label: 'Souffleuse',
                value: _hasSnowBlower,
                onChanged: (val) {
                  setState(() => _hasSnowBlower = val);
                  _autoSave();
                },
              ),
              _buildCompactEquipmentItem(
                icon: Icons.straighten_rounded,
                label: 'Balai toit',
                value: _hasRoofBroom,
                onChanged: (val) {
                  setState(() => _hasRoofBroom = val);
                  _autoSave();
                },
              ),
              _buildCompactEquipmentItem(
                icon: Icons.cleaning_services_rounded,
                label: 'Chiffon',
                value: _hasMicrofiberCloth,
                onChanged: (val) {
                  setState(() => _hasMicrofiberCloth = val);
                  _autoSave();
                },
              ),
              _buildCompactEquipmentItem(
                icon: Icons.water_drop_rounded,
                label: 'Deglacant',
                value: _hasDeicerSpray,
                onChanged: (val) {
                  setState(() => _hasDeicerSpray = val);
                  _autoSave();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEquipmentItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppTheme.primary : AppTheme.border,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value ? AppTheme.primary : AppTheme.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? AppTheme.success : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: value
                    ? null
                    : Border.all(color: AppTheme.border, width: 1.5),
              ),
              child: value
                  ? Icon(Icons.check, size: 12, color: AppTheme.background)
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
                child: const Icon(Icons.tune_rounded,
                    color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Preferences de travail', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Jobs simultanes maximum',
            style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Nombre de jobs actifs en meme temps',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _maxActiveJobs > 1
                    ? () {
                        setState(() => _maxActiveJobs--);
                        _autoSave();
                      }
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
                    ? () {
                        setState(() => _maxActiveJobs++);
                        _autoSave();
                      }
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
                'Recommande: 2-3 jobs',
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
                child: const Icon(Icons.notifications_rounded,
                    color: AppTheme.info, size: 20),
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
            onChanged: (val) {
              setState(() => _notifyNewJobs = val);
              _autoSave();
            },
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _buildNotificationToggle(
            icon: Icons.priority_high_rounded,
            title: 'Jobs urgents',
            subtitle: 'Alertes prioritaires',
            value: _notifyUrgentJobs,
            onChanged: (val) {
              setState(() => _notifyUrgentJobs = val);
              _autoSave();
            },
            iconColor: AppTheme.error,
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _buildNotificationToggle(
            icon: Icons.monetization_on_outlined,
            title: 'Pourboires',
            subtitle: 'Notification de reception',
            value: _notifyTips,
            onChanged: (val) {
              setState(() => _notifyTips = val);
              _autoSave();
            },
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

  Widget _buildHelpSupportSection() {
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
                    'Aide et support',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FAQ et contact',
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
                child: const Icon(Icons.logout_rounded,
                    color: AppTheme.error, size: 20),
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
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Se deconnecter',
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

  void _saveSettings() {
    if (_isSaving) return;
    setState(() => _isSaving = true);

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
            const Text('Deconnexion'),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment vous deconnecter de votre compte deneigeur ?',
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
              context.read<AuthBloc>().add(LogoutRequested());
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
            child: const Text('Deconnexion'),
          ),
        ],
      ),
    );
  }
}
