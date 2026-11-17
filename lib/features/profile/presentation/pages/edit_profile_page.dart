import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isUpdatingProfile =
      false; // Flag pour savoir si on fait une mise à jour de profil
  bool _photoJustUploaded =
      false; // Flag pour ignorer AuthAuthenticated après photo upload
  String? _originalPhone;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Pour la vérification SMS
  String? _pendingPhoneNumber;
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() {
    final authBloc = context.read<AuthBloc>();
    final state = authBloc.state;
    if (state is AuthAuthenticated) {
      _firstNameController.text = state.user.firstName ?? '';
      _lastNameController.text = state.user.lastName ?? '';
      _phoneController.text = state.user.phoneNumber ?? '';
      _emailController.text = state.user.email;
      _originalPhone = state.user.phoneNumber;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return BlocConsumer<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // Ne reconstruire que pour les états qui affectent l'affichage
        return current is AuthAuthenticated ||
            current is ProfilePhotoUploading ||
            current is ProfilePhotoUploaded;
      },
      listener: (context, state) {
        if (state is AuthError) {
          setState(() {
            _isLoading = false;
            _isUpdatingProfile = false;
            _isUploadingPhoto = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is ProfilePhotoUploading) {
          setState(() => _isUploadingPhoto = true);
        }
        if (state is ProfilePhotoUploaded) {
          setState(() {
            _isUploadingPhoto = false;
            _selectedImage = null;
            _photoJustUploaded =
                true; // Marquer pour ignorer le prochain AuthAuthenticated
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profile_photoUpdated),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        // Code de vérification envoyé - afficher le dialog
        if (state is PhoneChangeCodeSent) {
          setState(() {
            _isLoading = false;
            _pendingPhoneNumber = state.phoneNumber;
            _devCode = state.devCode;
          });
          _showVerificationDialog();
        }
        // Numéro changé avec succès
        if (state is PhoneChangeSuccess) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.profile_phoneVerified),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
        // Profil mis à jour (sans changement de numéro ni photo)
        if (state is AuthAuthenticated) {
          // Si c'est juste après un upload de photo, ignorer et réinitialiser le flag
          if (_photoJustUploaded) {
            setState(() => _photoJustUploaded = false);
            return;
          }
          // Naviguer seulement si c'est une mise à jour de profil (nom, téléphone, etc.)
          if (_isUpdatingProfile) {
            setState(() {
              _isLoading = false;
              _isUpdatingProfile = false;
            });
            Navigator.pop(context);
          }
        }
      },
      builder: (context, state) {
        // Récupérer la photoUrl depuis l'état actuel ou le dernier état AuthAuthenticated
        String? photoUrl;
        if (state is AuthAuthenticated) {
          photoUrl = state.user.photoUrl;
        } else if (state is ProfilePhotoUploaded) {
          photoUrl = state.user.photoUrl;
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _buildAvatarSection(photoUrl),
                        const SizedBox(height: 28),
                        _buildFormSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: SafeArea(top: false, child: _buildSaveButton()),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.profile_editTitle,
            style: AppTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String? photoUrl) {
    final initials = [_firstNameController.text, _lastNameController.text]
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .join();
    final initialsAvatar = Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppTheme.onPrimary,
        ),
      ),
    );

    Widget content;
    if (_isUploadingPhoto) {
      content = const Center(
        child: CircularProgressIndicator(
          color: AppTheme.onPrimary,
          strokeWidth: 2,
        ),
      );
    } else if (_selectedImage != null) {
      content = Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
      );
    } else if (photoUrl != null) {
      content = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorBuilder: (_, __, ___) => initialsAvatar,
      );
    } else {
      content = initialsAvatar;
    }

    return Center(
      child: GestureDetector(
        onTap: _isUploadingPhoto ? null : _changePhoto,
        child: Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: ClipOval(child: content),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppTheme.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.profile_personalInfo,
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _firstNameController,
            label: AppLocalizations.of(context)!.common_firstName,
            icon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.profile_firstNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _lastNameController,
            label: AppLocalizations.of(context)!.common_name,
            icon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.profile_lastNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: AppLocalizations.of(context)!.common_email,
            icon: Icons.email_outlined,
            enabled: false,
            suffixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              AppLocalizations.of(context)!.profile_emailNotEditable,
              style: AppTheme.labelSmall,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: AppLocalizations.of(context)!.common_phone,
            hint: '+1 (514) 123-4567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^\+?1?\d{10,}$')
                    .hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                  return AppLocalizations.of(context)!.profile_phoneInvalid;
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.profile_smsVerificationNote,
                    style: AppTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    IconData? suffixIcon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18) : null,
        fillColor: enabled ? AppTheme.surface : AppTheme.surfaceContainer,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfile,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.onPrimary,
              ),
            )
          : Text(AppLocalizations.of(context)!.profile_saveChanges),
    );
  }

  void _changePhoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.profile_changePhoto,
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildPhotoOption(
                icon: Icons.photo_camera_outlined,
                iconColor: AppTheme.primary,
                title: AppLocalizations.of(context)!.profile_takePhoto,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _buildPhotoOption(
                icon: Icons.photo_library_outlined,
                iconColor: AppTheme.primary,
                title: AppLocalizations.of(context)!.profile_chooseFromGallery,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _buildPhotoOption(
                icon: Icons.delete_outline_rounded,
                iconColor: AppTheme.error,
                title: AppLocalizations.of(context)!.profile_deletePhoto,
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        // Upload immediately
        context
            .read<AuthBloc>()
            .add(UploadProfilePhoto(filePath: pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .profile_photoSelectionError(e.toString())),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deletePhoto() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.profile_deletePhoto),
        content: Text(AppLocalizations.of(context)!.profile_deletePhotoConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(AppLocalizations.of(context)!.common_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthBloc>().add(DeleteProfilePhoto());
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(AppLocalizations.of(context)!.common_delete),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: AppTheme.labelLarge.copyWith(
          color: iconColor == AppTheme.error
              ? AppTheme.error
              : AppTheme.textPrimary,
        ),
      ),
    );
  }

  void _saveProfile() {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      setState(() => _isLoading = true);

      final newPhone =
          _phoneController.text.isEmpty ? null : _phoneController.text;
      final phoneChanged = newPhone != _originalPhone;

      // If phone number changed and is not empty, send verification code
      if (phoneChanged && newPhone != null && newPhone.isNotEmpty) {
        context
            .read<AuthBloc>()
            .add(SendPhoneChangeCode(phoneNumber: newPhone));
      } else {
        // No phone change or phone is being cleared, update profile directly
        _performProfileUpdate();
      }
    }
  }

  void _performProfileUpdate() {
    setState(() => _isUpdatingProfile = true);
    context.read<AuthBloc>().add(
          UpdateProfile(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            phoneNumber:
                _phoneController.text.isEmpty ? null : _phoneController.text,
          ),
        );
  }

  void _showVerificationDialog() {
    final codeController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                setDialogState(() => isVerifying = false);
              }
              if (state is PhoneChangeSuccess) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: AlertDialog(
              title: Text(
                AppLocalizations.of(context)!.profile_smsVerification,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .profile_verificationCodeSentTo,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pendingPhoneNumber ?? '',
                    style: AppTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_devCode != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.developer_mode,
                            size: 16,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Code dev: $_devCode',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    decoration: const InputDecoration(
                      hintText: '000000',
                      counterText: '',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isVerifying
                            ? null
                            : () {
                                Navigator.of(dialogContext).pop();
                                // Reset states after dialog closes
                                setState(() {
                                  _pendingPhoneNumber = null;
                                  _devCode = null;
                                  _isLoading = false;
                                });
                                // Restaurer l'état AuthAuthenticated pour garder les données utilisateur
                                context
                                    .read<AuthBloc>()
                                    .add(RestoreAuthState());
                              },
                        child:
                            Text(AppLocalizations.of(context)!.common_cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isVerifying
                            ? null
                            : () {
                                if (codeController.text.length == 6) {
                                  setDialogState(() => isVerifying = true);
                                  context.read<AuthBloc>().add(
                                        VerifyPhoneChangeCode(
                                          phoneNumber: _pendingPhoneNumber!,
                                          code: codeController.text,
                                        ),
                                      );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        child: isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.profile_verify),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
