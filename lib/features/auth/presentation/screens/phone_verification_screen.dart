import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Écran de vérification du numéro de téléphone par SMS OTP
class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String role;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _devCode; // Code en mode développement

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Envoyer le code automatiquement au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationCode();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _resendTimer = null;
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    for (var node in _focusNodes) {
      node.dispose();
    }
    _focusNodes.clear();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _sendVerificationCode() {
    context.read<AuthBloc>().add(
          SendPhoneVerificationCode(
            phoneNumber: widget.phoneNumber,
            email: widget.email,
            password: widget.password,
            firstName: widget.firstName,
            lastName: widget.lastName,
            role: widget.role,
          ),
        );
  }

  void _resendCode() {
    if (!_canResend) return;
    _clearCode();
    _startResendTimer();
    context.read<AuthBloc>().add(
          ResendPhoneVerificationCode(phoneNumber: widget.phoneNumber),
        );
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  String _getEnteredCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _verifyCode() {
    final code = _getEnteredCode();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Veuillez entrer le code complet à 6 chiffres';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    context.read<AuthBloc>().add(
          VerifyPhoneCode(
            phoneNumber: widget.phoneNumber,
            code: code,
          ),
        );
  }

  void _onDigitEntered(int index, String value) {
    if (value.length == 1) {
      // Passer au champ suivant
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Dernier champ, vérifier automatiquement
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    }
  }

  void _onKeyPressed(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PhoneCodeSent) {
          // Code envoyé avec succès
          if (state.devCode != null) {
            setState(() {
              _devCode = state.devCode;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Code de vérification envoyé'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else if (state is PhoneVerificationSuccess) {
          // Vérification réussie, compte créé
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        } else if (state is AuthError) {
          setState(() {
            _isVerifying = false;
            _errorMessage = state.message;
          });
        } else if (state is AuthAuthenticated) {
          // Compte créé via la vérification
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            'Vérification',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Icône
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primary2.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android,
                    size: 50,
                    color: AppTheme.primary2,
                  ),
                ),

                const SizedBox(height: 32),

                // Titre
                Text(
                  'Vérification du téléphone',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Entrez le code à 6 chiffres envoyé au',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Numéro de téléphone
                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary2,
                  ),
                ),

                const SizedBox(height: 40),

                // Code en mode dev
                if (_devCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bug_report, color: AppTheme.warning),
                        const SizedBox(width: 12),
                        Text(
                          'Mode dev - Code: $_devCode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Champs OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      height: 60,
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) => _onKeyPressed(index, event),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppTheme.surfaceContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primary2,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.error),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onDigitEntered(index, value),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Message d'erreur
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Bouton vérifier
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.background,
                      disabledBackgroundColor: AppTheme.surfaceContainer,
                      disabledForegroundColor: AppTheme.textTertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isVerifying
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppTheme.background,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Vérifier',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Renvoyer le code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Vous n\'avez pas reçu le code? ',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    if (_canResend)
                      TextButton(
                        onPressed: _resendCode,
                        child: Text(
                          'Renvoyer',
                          style: TextStyle(
                            color: AppTheme.primary2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Renvoyer dans ${_resendCountdown}s',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Modifier le numéro
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon:
                      Icon(Icons.edit, size: 18, color: AppTheme.textSecondary),
                  label: Text(
                    'Modifier le numéro',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
