import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/constants/app_routes.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      context.read<AuthBloc>().add(
            ResetPasswordEvent(
              token: widget.token,
              newPassword: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        color: AppTheme.background,
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (listenerContext, state) {
              if (state is ResetPasswordSuccess) {
                ScaffoldMessenger.of(listenerContext).showSnackBar(
                  SnackBar(
                    content: Text(l10n.resetPassword_resetSuccess),
                    backgroundColor: AppTheme.success,
                  ),
                );
                final navigator = Navigator.of(context);
                Future.delayed(const Duration(seconds: 2), () {
                  if (!mounted) return;
                  navigator.pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                });
              } else if (state is AuthError) {
                ScaffoldMessenger.of(listenerContext).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              final isSuccess = state is ResetPasswordSuccess;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Icône
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.lock_reset,
                        size: 80,
                        color:
                            isSuccess ? AppTheme.success : AppTheme.textPrimary,
                      ),
                      const SizedBox(height: 16),

                      // Titre
                      Text(
                        isSuccess
                            ? l10n.resetPassword_successTitle
                            : l10n.resetPassword_title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        isSuccess
                            ? l10n.resetPassword_successDescription
                            : l10n.resetPassword_description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Formulaire
                      if (!isSuccess) ...[
                        Container(
                          decoration: AppTheme.cardElevated,
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              // Champ mot de passe
                              AppTextField(
                                controller: _passwordController,
                                label: l10n.resetPassword_newPassword,
                                hint: '••••••••',
                                prefixIcon: Icons.lock,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.textTertiary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.register_passwordRequired;
                                  }
                                  if (value.length < 6) {
                                    return l10n.resetPassword_minChars;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Champ confirmation mot de passe
                              AppTextField(
                                controller: _confirmPasswordController,
                                label: l10n.register_confirmPassword,
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppTheme.textTertiary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n
                                        .register_confirmPasswordRequired;
                                  }
                                  if (value != _passwordController.text) {
                                    return l10n.register_passwordMismatch;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Indicateur de force du mot de passe
                              if (_passwordController.text.isNotEmpty) ...[
                                _buildPasswordStrengthIndicator(l10n),
                                const SizedBox(height: 24),
                              ],

                              // Bouton de réinitialisation
                              AppButton(
                                text: l10n.resetPassword_resetButton,
                                onPressed:
                                    isLoading ? null : _handleResetPassword,
                                isLoading: isLoading,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Message de succès
                        Container(
                          decoration: AppTheme.cardElevated,
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 64,
                                color: AppTheme.success,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.resetPassword_resetDone,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.resetPassword_canNowLogin,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: l10n.resetPassword_goToLogin,
                                onPressed: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.login,
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Lien retour connexion
                      if (!isSuccess)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.forgotPassword_rememberPassword,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.login,
                                  (route) => false,
                                );
                              },
                              child: Text(
                                l10n.login_submit,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(AppLocalizations l10n) {
    final password = _passwordController.text;
    int strength = 0;
    String strengthText = '';
    Color strengthColor = AppTheme.error;

    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    switch (strength) {
      case 0:
      case 1:
        strengthText = l10n.resetPassword_strengthWeak;
        strengthColor = AppTheme.error;
        break;
      case 2:
      case 3:
        strengthText = l10n.resetPassword_strengthMedium;
        strengthColor = AppTheme.warning;
        break;
      case 4:
      case 5:
        strengthText = l10n.resetPassword_strengthStrong;
        strengthColor = AppTheme.success;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 5,
                backgroundColor: AppTheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.resetPassword_minChars,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }
}
