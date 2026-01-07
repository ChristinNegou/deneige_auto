import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(ForgotPasswordEvent(_emailController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        color: AppTheme.background,
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is ForgotPasswordSuccess) {
                setState(() => _emailSent = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Email de réinitialisation envoyé !'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bouton retour
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: AppTheme.textPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Icône
                      Icon(
                        Icons.lock_reset,
                        size: 80,
                        color: AppTheme.textPrimary,
                      ),
                      const SizedBox(height: 16),

                      // Titre
                      Text(
                        'Mot de passe oublié ?',
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
                        _emailSent
                            ? 'Un email de réinitialisation a été envoyé à ${_emailController.text}'
                            : 'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Formulaire
                      if (!_emailSent) ...[
                        Container(
                          decoration: AppTheme.cardElevated,
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'exemple@email.com',
                                prefixIcon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: 'Envoyer le lien',
                                onPressed:
                                    isLoading ? null : _handleResetPassword,
                                isLoading: isLoading,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Message de confirmation
                        Container(
                          decoration: AppTheme.cardElevated,
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.mark_email_read,
                                size: 64,
                                color: AppTheme.success,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Email envoyé !',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Vérifiez votre boîte de réception et suivez les instructions pour réinitialiser votre mot de passe.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: 'Retour à la connexion',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _emailSent = false;
                                    _emailController.clear();
                                  });
                                },
                                child: Text(
                                  'Renvoyer l\'email',
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Lien retour connexion
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Vous vous souvenez de votre mot de passe ? ',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Se connecter',
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
}
