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
                      padding: const EdgeInsets.all(AppTheme.paddingLG),
                      children: [
                        _buildAvatarSection(photoUrl),
                        const SizedBox(height: 24),
                        _buildFormSection(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            AppLocalizations.of(context)!.profile_editTitle,
            style: AppTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String? photoUrl) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isUploadingPhoto
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      )
                    : photoUrl != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXL),
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                color: AppTheme.background,
                                size: 50,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: AppTheme.background,
                            size: 50,
                          ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _changePhoto,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: AppTheme.surface, width: 3),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.background,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.profile_personalInfo,
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
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
            label: 'Email',
            icon: Icons.email_outlined,
            enabled: false,
            suffixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              AppLocalizations.of(context)!.profile_emailNotEditable,
              style: AppTheme.labelSmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
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
                    style: AppTheme.labelSmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textTertiary,
                    ),
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
      style: AppTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: AppTheme.textTertiary, size: 18)
            : null,
        filled: true,
        fillColor: enabled ? AppTheme.background : AppTheme.divider,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.background,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.background),
                ),
              )
            : Text(
                AppLocalizations.of(context)!.profile_saveChanges,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _changePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
              AppLocalizations.of(context)!.profile_changePhoto,
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildPhotoOption(
              icon: Icons.camera_alt_rounded,
              iconColor: AppTheme.primary,
              title: AppLocalizations.of(context)!.profile_takePhoto,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildPhotoOption(
              icon: Icons.photo_library_rounded,
              iconColor: AppTheme.secondary,
              title: AppLocalizations.of(context)!.profile_chooseFromGallery,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            _buildPhotoOption(
              icon: Icons.delete_rounded,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: AppTheme.labelLarge.copyWith(
                color: iconColor == AppTheme.error
                    ? AppTheme.error
                    : AppTheme.textPrimary,
              ),
            ),
          ],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.profile_smsVerification,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
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
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        borderSide:
                            const BorderSide(color: AppTheme.primary, width: 2),
                      ),
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
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
