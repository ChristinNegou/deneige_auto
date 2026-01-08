import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/worker_availability_bloc.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;

  // Equipment checkboxes
  bool _hasShovel = true;
  bool _hasBrush = true;
  bool _hasIceScraper = true;
  bool _hasSaltSpreader = false;
  bool _hasSnowBlower = false;

  // Max active jobs
  int _maxActiveJobs = 3;

  // Notifications
  bool _notifyNewJobs = true;
  bool _notifyUrgentJobs = true;
  bool _notifyTips = true;

  // Zones
  final List<String> _zones = ['Trois-Rivieres Centre', 'Cap-de-la-Madeleine'];

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
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: BlocConsumer<WorkerAvailabilityBloc, WorkerAvailabilityState>(
        listener: (context, state) {
          if (state is WorkerProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.background, size: 20),
                    SizedBox(width: 12),
                    Text('Parametres sauvegardes'),
                  ],
                ),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            );
          } else if (state is WorkerPhotoUploading) {
            setState(() => _isUploadingPhoto = true);
          } else if (state is WorkerPhotoUploaded) {
            setState(() => _isUploadingPhoto = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.background, size: 20),
                    SizedBox(width: 12),
                    Text('Photo de profil mise à jour'),
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
            setState(() => _isUploadingPhoto = false);
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
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildEquipmentSection(),
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
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
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
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
                                  color: AppTheme.shadowColor.withValues(alpha: 0.2),
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
                                color: AppTheme.background.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  userEmail,
                                  style: TextStyle(
                                    color: AppTheme.background.withValues(alpha: 0.9),
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
                                color: AppTheme.background.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                userPhone,
                                style: TextStyle(
                                  color: AppTheme.background.withValues(alpha: 0.9),
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
                  child: Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
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
                  child: Icon(Icons.photo_library_rounded, color: AppTheme.secondary),
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
              Text('Mon equipement', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildEquipmentItem(
            icon: '🪣',
            label: 'Pelle a neige',
            value: _hasShovel,
            onChanged: (val) => setState(() => _hasShovel = val!),
          ),
          _buildEquipmentItem(
            icon: '🧹',
            label: 'Balai a neige',
            value: _hasBrush,
            onChanged: (val) => setState(() => _hasBrush = val!),
          ),
          _buildEquipmentItem(
            icon: '🪟',
            label: 'Grattoir a glace',
            value: _hasIceScraper,
            onChanged: (val) => setState(() => _hasIceScraper = val!),
          ),
          _buildEquipmentItem(
            icon: '🧂',
            label: 'Epandeur de sel',
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
                child: const Icon(Icons.location_on_rounded,
                    color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zones preferees', style: AppTheme.headlineSmall),
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
            subtitle: 'Notification de reception',
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
            Icon(Icons.save_rounded, color: AppTheme.background, size: 22),
            SizedBox(width: 10),
            Text(
              'Sauvegarder',
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
            hintText: 'Ex: Trois-Rivieres Ouest',
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
    if (_formKey.currentState?.validate() ?? true) {
      final equipment = <String>[];
      if (_hasShovel) equipment.add('shovel');
      if (_hasBrush) equipment.add('brush');
      if (_hasIceScraper) equipment.add('ice_scraper');
      if (_hasSaltSpreader) equipment.add('salt_spreader');
      if (_hasSnowBlower) equipment.add('snow_blower');

      context.read<WorkerAvailabilityBloc>().add(
            UpdateProfile(
              equipmentList: equipment,
              maxActiveJobs: _maxActiveJobs,
            ),
          );
    }
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
