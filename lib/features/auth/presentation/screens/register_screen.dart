import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../legal/presentation/pages/legal_page.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole role;

  const RegisterScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      cleaned = '1$cleaned';
    }
    return '+$cleaned';
  }

  String? _validatePhoneNumber(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.register_phoneRequired;
    }
    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 10 || cleaned.length > 11) {
      return l10n.register_phoneInvalid;
    }
    if (cleaned.length == 11 && !cleaned.startsWith('1')) {
      return l10n.register_phoneInvalid;
    }
    return null;
  }

  void _handleRegister(AppLocalizations l10n) {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.register_acceptTerms),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
          ),
        );
        return;
      }

      final formattedPhone = _formatPhoneNumber(_phoneController.text.trim());
      Navigator.of(context).pushNamed(
        AppRoutes.phoneVerification,
        arguments: {
          'phoneNumber': formattedPhone,
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'role': widget.role.toString().split('.').last,
        },
      );
    }
  }

  String _getRoleTitle(AppLocalizations l10n) => widget.role == UserRole.client
      ? l10n.accountType_client
      : l10n.accountType_snowWorker;

  Widget get _roleIcon => widget.role == UserRole.client
      ? SvgPicture.asset(
          'assets/icons/person.svg',
          width: 35,
          height: 35,
          colorFilter: ColorFilter.mode(_roleColor, BlendMode.srcIn),
        )
      : SvgPicture.asset(
          'assets/icons/snowplow.svg',
          width: 35,
          height: 35,
          colorFilter: ColorFilter.mode(_roleColor, BlendMode.srcIn),
        );

  Color get _roleColor => widget.role == UserRole.client
      ? AppTheme.statusAssigned
      : AppTheme.success;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(l10n),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.paddingXL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Role badge
                          _buildRoleBadge(l10n),

                          const SizedBox(height: 24),

                          // Form card
                          _buildFormCard(isLoading, l10n),

                          const SizedBox(height: 24),

                          // Login link
                          _buildLoginLink(l10n),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
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
            l10n.register_title,
            style: AppTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(AppLocalizations l10n) {
    final roleTitle = _getRoleTitle(l10n);
    return Center(
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: Center(child: _roleIcon),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              l10n.register_accountLabel(roleTitle),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _roleColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.register_subtitle,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isLoading, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prénom et Nom sur la même ligne
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: l10n.common_firstName,
                  hint: l10n.register_firstNameHint,
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.common_required;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: l10n.common_name,
                  hint: l10n.register_lastNameHint,
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.common_required;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email
          _buildTextField(
            controller: _emailController,
            label: l10n.common_email,
            hint: l10n.login_emailHint,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.login_emailRequired;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) {
                return l10n.login_emailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Téléphone
          _buildTextField(
            controller: _phoneController,
            label: l10n.common_phone,
            hint: l10n.register_phoneHint,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) => _validatePhoneNumber(value, l10n),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppTheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.register_verificationCodeSent,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mot de passe
          _buildTextField(
            controller: _passwordController,
            label: l10n.common_password,
            hint: l10n.register_passwordMinChars,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.register_passwordRequired;
              }
              if (value.length < 6) {
                return l10n.register_passwordMinChars;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirmer mot de passe
          _buildTextField(
            controller: _confirmPasswordController,
            label: l10n.register_confirmPassword,
            hint: l10n.register_confirmPasswordHint,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            suffixIcon: GestureDetector(
              onTap: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
              child: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.register_confirmPasswordRequired;
              }
              if (value != _passwordController.text) {
                return l10n.register_passwordMismatch;
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Checkbox conditions d'utilisation
          LegalLinksWidget(
            showCheckbox: true,
            isChecked: _acceptedTerms,
            onCheckChanged: (value) {
              setState(() => _acceptedTerms = value ?? false);
            },
          ),

          const SizedBox(height: 24),

          // Bouton inscription
          _buildRegisterButton(isLoading, l10n),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTheme.bodyMedium.copyWith(fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 10, right: 6),
              child: Icon(icon, color: AppTheme.textTertiary, size: 18),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: suffixIcon,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: AppTheme.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: const BorderSide(color: AppTheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isLoading, AppLocalizations l10n) {
    return GestureDetector(
      onTap: isLoading ? null : () => _handleRegister(l10n),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_roleColor, _roleColor.withValues(alpha: 0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: [
            BoxShadow(
              color: _roleColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppTheme.background,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.register_submit,
                      style: TextStyle(
                        color: AppTheme.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.background,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.register_hasAccount,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
          child: Text(
            l10n.login_submit,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
