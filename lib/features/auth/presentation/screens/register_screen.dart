import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../legal/presentation/pages/legal_page.dart';
import '../../domain/entities/user.dart';

/// Age minimum pour ouvrir un compte (le serveur applique la meme regle).
const int kMinRegistrationAge = 18;

/// Lit une date saisie JJ/MM/AAAA. Retourne null si elle est incomplete ou
/// n'existe pas (ex. 31/02/2000).
DateTime? parseBirthDate(String text) {
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// Age revolu a la date [today].
int ageOn(DateTime birth, DateTime today) {
  var age = today.year - birth.year;
  if (today.month < birth.month ||
      (today.month == birth.month && today.day < birth.day)) {
    age--;
  }
  return age;
}

/// Ajoute les barres obliques pendant la saisie : 12041990 -> 12/04/1990.
class _BirthDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(clipped[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

enum _Step { name, birthDate, email, phone, password, review }

/// Inscription client ou deneigeur, une question par ecran. Le compte est
/// cree a l'ecran suivant, une fois le numero confirme par SMS.
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _birthDateFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  _Step _step = _Step.name;
  String? _error;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  List<TextEditingController> get _controllers => [
        _firstNameController,
        _lastNameController,
        _birthDateController,
        _emailController,
        _phoneController,
        _passwordController,
      ];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_onTyping);
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _firstNameFocus.requestFocus());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in [
      _firstNameFocus,
      _lastNameFocus,
      _birthDateFocus,
      _emailFocus,
      _phoneFocus,
      _passwordFocus,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  /// Efface l'erreur des que la personne corrige, et met a jour le bouton.
  void _onTyping() => setState(() => _error = null);

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _formatPhoneNumber(String phone) {
    var cleaned = _digits(phone);
    if (cleaned.length == 10) cleaned = '1$cleaned';
    return '+$cleaned';
  }

  /// Le bouton Suivant s'active des que l'etape a du contenu.
  bool get _stepFilled {
    switch (_step) {
      case _Step.name:
        return _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty;
      case _Step.birthDate:
        return _birthDateController.text.length == 10;
      case _Step.email:
        return _emailController.text.trim().isNotEmpty;
      case _Step.phone:
        return _digits(_phoneController.text).length >= 10;
      case _Step.password:
        return _passwordController.text.isNotEmpty;
      case _Step.review:
        return _acceptedTerms;
    }
  }

  /// Message d'erreur de l'etape courante, ou null si on peut avancer.
  String? _validateStep(AppLocalizations l10n) {
    switch (_step) {
      case _Step.name:
        // Meme minimum que le serveur.
        if (_firstNameController.text.trim().length < 2 ||
            _lastNameController.text.trim().length < 2) {
          return l10n.registerFlow_nameTooShort;
        }
        return null;
      case _Step.birthDate:
        final birth = parseBirthDate(_birthDateController.text);
        if (birth == null) return l10n.registerFlow_birthInvalid;
        final age = ageOn(birth, DateTime.now());
        if (age > 120) return l10n.registerFlow_birthInvalid;
        if (age < kMinRegistrationAge) {
          return l10n.registerFlow_birthTooYoung(kMinRegistrationAge);
        }
        return null;
      case _Step.email:
        if (!RegExp(r'^[\w-\.+]+@([\w-]+\.)+[\w-]{2,}$')
            .hasMatch(_emailController.text.trim())) {
          return l10n.login_emailInvalid;
        }
        return null;
      case _Step.phone:
        final cleaned = _digits(_phoneController.text);
        if (cleaned.length < 10 ||
            cleaned.length > 11 ||
            (cleaned.length == 11 && !cleaned.startsWith('1'))) {
          return l10n.register_phoneInvalid;
        }
        return null;
      case _Step.password:
        if (_passwordController.text.length < 6) {
          return l10n.register_passwordMinChars;
        }
        return null;
      case _Step.review:
        return _acceptedTerms ? null : l10n.register_acceptTerms;
    }
  }

  FocusNode? _focusFor(_Step step) => switch (step) {
        _Step.name => _firstNameFocus,
        _Step.birthDate => _birthDateFocus,
        _Step.email => _emailFocus,
        _Step.phone => _phoneFocus,
        _Step.password => _passwordFocus,
        _Step.review => null,
      };

  void _goTo(_Step step) {
    setState(() {
      _step = step;
      _error = null;
    });
    final focus = _focusFor(step);
    if (focus == null) {
      FocusScope.of(context).unfocus();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus.requestFocus();
      });
    }
  }

  void _next() {
    final l10n = AppLocalizations.of(context)!;
    final error = _validateStep(l10n);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_step == _Step.review) {
      _submit();
    } else {
      _goTo(_Step.values[_step.index + 1]);
    }
  }

  void _back() {
    if (_step == _Step.name) {
      Navigator.pop(context);
    } else {
      _goTo(_Step.values[_step.index - 1]);
    }
  }

  void _submit() {
    final birth = parseBirthDate(_birthDateController.text)!;
    Navigator.of(context).pushNamed(
      AppRoutes.phoneVerification,
      arguments: {
        'phoneNumber': _formatPhoneNumber(_phoneController.text.trim()),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dateOfBirth': DateFormat('yyyy-MM-dd').format(birth),
        'role': widget.role.toString().split('.').last,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roleTitle = widget.role == UserRole.client
        ? l10n.accountType_client
        : l10n.accountType_snowWorker;
    final progress = (_step.index + 1) / _Step.values.length;

    return PopScope(
      canPop: _step == _Step.name,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(l10n.register_accountLabel(roleTitle),
              style: AppTheme.labelMedium),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  l10n.registerFlow_step(_step.index + 1, _Step.values.length),
                  style: AppTheme.labelMedium,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: AppTheme.border,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(l10n),
                    ),
                  ),
                ),
              ),
              _buildBottom(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations l10n) {
    switch (_step) {
      case _Step.name:
        return _StepLayout(
          title: l10n.registerFlow_nameTitle,
          help: widget.role == UserRole.client
              ? l10n.registerFlow_nameHelpClient
              : l10n.registerFlow_nameHelpWorker,
          error: _error,
          children: [
            _field(
              controller: _firstNameController,
              focusNode: _firstNameFocus,
              label: l10n.common_firstName,
              hint: l10n.register_firstNameHint,
              capitalization: TextCapitalization.words,
              autofill: AutofillHints.givenName,
              action: TextInputAction.next,
              onSubmitted: (_) => _lastNameFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _lastNameController,
              focusNode: _lastNameFocus,
              label: l10n.common_name,
              hint: l10n.register_lastNameHint,
              capitalization: TextCapitalization.words,
              autofill: AutofillHints.familyName,
            ),
          ],
        );
      case _Step.birthDate:
        return _StepLayout(
          title: l10n.registerFlow_birthTitle,
          help: l10n.registerFlow_birthHelp(kMinRegistrationAge),
          error: _error,
          children: [
            _field(
              controller: _birthDateController,
              focusNode: _birthDateFocus,
              hint: l10n.registerFlow_birthHint,
              keyboardType: TextInputType.number,
              formatters: [_BirthDateFormatter()],
              autofill: AutofillHints.birthday,
            ),
          ],
        );
      case _Step.email:
        return _StepLayout(
          title: l10n.registerFlow_emailTitle,
          help: l10n.registerFlow_emailHelp,
          error: _error,
          children: [
            _field(
              controller: _emailController,
              focusNode: _emailFocus,
              hint: l10n.login_emailHint,
              keyboardType: TextInputType.emailAddress,
              autofill: AutofillHints.email,
            ),
          ],
        );
      case _Step.phone:
        return _StepLayout(
          title: l10n.registerFlow_phoneTitle,
          help: l10n.registerFlow_phoneHelp,
          error: _error,
          children: [
            _field(
              controller: _phoneController,
              focusNode: _phoneFocus,
              hint: l10n.register_phoneHint,
              keyboardType: TextInputType.phone,
              autofill: AutofillHints.telephoneNumber,
            ),
          ],
        );
      case _Step.password:
        return _StepLayout(
          title: l10n.registerFlow_passwordTitle,
          help: l10n.register_passwordMinChars,
          error: _error,
          children: [
            _field(
              controller: _passwordController,
              focusNode: _passwordFocus,
              hint: l10n.common_password,
              obscure: _obscurePassword,
              autofill: AutofillHints.newPassword,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      case _Step.review:
        return _buildReview(l10n);
    }
  }

  Widget _buildReview(AppLocalizations l10n) {
    final birth = parseBirthDate(_birthDateController.text);
    final localeName = Localizations.localeOf(context).toString();
    return _StepLayout(
      title: l10n.registerFlow_reviewTitle,
      help: l10n.registerFlow_reviewHelp,
      error: _error,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _ReviewRow(
                label: l10n.registerFlow_reviewName,
                value:
                    '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                onEdit: () => _goTo(_Step.name),
                editLabel: l10n.registerFlow_edit,
              ),
              _ReviewRow(
                label: l10n.registerFlow_reviewBirthDate,
                value: birth == null
                    ? _birthDateController.text
                    : DateFormat.yMMMMd(localeName).format(birth),
                onEdit: () => _goTo(_Step.birthDate),
                editLabel: l10n.registerFlow_edit,
              ),
              _ReviewRow(
                label: l10n.common_email,
                value: _emailController.text.trim(),
                onEdit: () => _goTo(_Step.email),
                editLabel: l10n.registerFlow_edit,
              ),
              _ReviewRow(
                label: l10n.common_phone,
                value: _phoneController.text.trim(),
                onEdit: () => _goTo(_Step.phone),
                editLabel: l10n.registerFlow_edit,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LegalLinksWidget(
          showCheckbox: true,
          isChecked: _acceptedTerms,
          onCheckChanged: (value) => setState(() {
            _acceptedTerms = value ?? false;
            _error = null;
          }),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    String? label,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    String? autofill,
    bool obscure = false,
    Widget? suffix,
    TextInputAction action = TextInputAction.done,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label, style: AppTheme.labelMedium),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          inputFormatters: formatters,
          autofillHints: autofill == null ? null : [autofill],
          obscureText: obscure,
          autocorrect: false,
          textInputAction: action,
          onSubmitted: onSubmitted ?? (_) => _next(),
          style: AppTheme.bodyLarge.copyWith(fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _buildBottom(AppLocalizations l10n) {
    final isLast = _step == _Step.review;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _stepFilled ? _next : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text(
                isLast ? l10n.registerFlow_createAccount : l10n.common_next),
          ),
          if (_step == _Step.name)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.register_hasAccount, style: AppTheme.bodySmall),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.login),
                  child: Text(l10n.login_submit),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Une question : titre, aide, champs, puis l'erreur eventuelle.
class _StepLayout extends StatelessWidget {
  final String title;
  final String help;
  final String? error;
  final List<Widget> children;

  const _StepLayout({
    required this.title,
    required this.help,
    required this.error,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(help,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 28),
        ...children,
        if (error != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 18, color: AppTheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(error!,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final String editLabel;
  final VoidCallback onEdit;
  final bool last;

  const _ReviewRow({
    required this.label,
    required this.value,
    required this.editLabel,
    required this.onEdit,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.bodyMedium),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: Text(editLabel)),
        ],
      ),
    );
  }
}
