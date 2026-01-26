import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/locale_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../legal/presentation/pages/legal_page.dart';
import '../presentation/bloc/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '1.0.0';
  final LocaleService _localeService = sl<LocaleService>();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (_) {
      // Keep default version
    }
  }

  void _changeLanguage(String languageCode) {
    _localeService.setLocale(Locale(languageCode));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = _localeService.locale.languageCode;

    return BlocProvider(
      create: (context) => sl<SettingsBloc>()..add(LoadSettings()),
      child: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.error,
              ),
            );
            context.read<SettingsBloc>().add(ClearSettingsMessages());
          }

          if (state.successMessage != null) {
            context.read<SettingsBloc>().add(ClearSettingsMessages());
          }

          if (state.isAccountDeleted) {
            // Logout and navigate to login
            context.read<AuthBloc>().add(LogoutRequested());
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              title: Text(l10n.settings_title),
              backgroundColor: AppTheme.surface,
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      // Section Notifications
                      _buildSectionHeader(l10n.settings_notifications),
                      _buildSwitchTile(
                        icon: Icons.notifications_outlined,
                        title: l10n.settings_pushNotifications,
                        subtitle: l10n.settings_pushNotificationsDesc,
                        value: state.preferences.pushNotificationsEnabled,
                        onChanged: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdatePushNotifications(value));
                        },
                      ),
                      _buildSwitchTile(
                        icon: Icons.volume_up_outlined,
                        title: l10n.settings_sounds,
                        subtitle: l10n.settings_soundsDesc,
                        value: state.preferences.soundEnabled,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateSound(value));
                        },
                      ),

                      const Divider(height: 32),

                      // Section Apparence
                      _buildSectionHeader(l10n.settings_appearance),
                      _buildSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        title: l10n.settings_darkTheme,
                        subtitle: l10n.settings_darkThemeDesc,
                        value: state.preferences.darkThemeEnabled,
                        onChanged: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateDarkTheme(value));
                        },
                      ),

                      const Divider(height: 32),

                      // Section Langue
                      _buildSectionHeader(l10n.settings_language),
                      _buildListTile(
                        icon: Icons.language,
                        title: l10n.settings_language,
                        trailing: DropdownButton<String>(
                          value: currentLanguage,
                          underline: const SizedBox(),
                          dropdownColor: AppTheme.surfaceElevated,
                          items: [
                            DropdownMenuItem(
                                value: 'fr',
                                child: Text(l10n.settings_languageFrench)),
                            DropdownMenuItem(
                                value: 'en',
                                child: Text(l10n.settings_languageEnglish)),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _changeLanguage(value);
                            }
                          },
                        ),
                      ),

                      const Divider(height: 32),

                      // Section Compte
                      _buildSectionHeader(l10n.settings_account),
                      _buildListTile(
                        icon: Icons.person_outline,
                        title: l10n.settings_editProfile,
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.textTertiary),
                        onTap: () =>
                            Navigator.pushNamed(context, '/profile/edit'),
                      ),
                      _buildListTile(
                        icon: Icons.delete_outline,
                        title: l10n.settings_deleteAccount,
                        titleColor: AppTheme.error,
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.error),
                        onTap: () => _showDeleteAccountDialog(context, l10n),
                      ),

                      const Divider(height: 32),

                      // Section Legal
                      _buildSectionHeader(l10n.settings_legal),
                      _buildListTile(
                        icon: Icons.gavel_outlined,
                        title: l10n.settings_legalMentions,
                        subtitle: l10n.settings_legalSubtitle,
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.textTertiary),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LegalDocumentsListPage(),
                          ),
                        ),
                      ),
                      _buildListTile(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.settings_privacyPolicy,
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.textTertiary),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LegalPage(
                              documentType: LegalDocumentType.privacyPolicy,
                            ),
                          ),
                        ),
                      ),
                      _buildListTile(
                        icon: Icons.description_outlined,
                        title: l10n.settings_termsOfService,
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.textTertiary),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LegalPage(
                              documentType: LegalDocumentType.termsOfService,
                            ),
                          ),
                        ),
                      ),

                      const Divider(height: 32),

                      // Section About
                      _buildSectionHeader(l10n.settings_about),
                      _buildListTile(
                        icon: Icons.info_outline,
                        title: l10n.settings_appVersion,
                        subtitle: _appVersion,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 13,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppLocalizations l10n) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
              const SizedBox(width: 12),
              Text(
                l10n.settings_deleteAccountTitle,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settings_deleteAccountWarning,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.settings_enterPassword,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.common_password,
                  hintStyle: const TextStyle(color: AppTheme.textTertiary),
                  filled: true,
                  fillColor: AppTheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textTertiary,
                    ),
                    onPressed: () {
                      setDialogState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.common_cancel,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state.isDeleting
                      ? null
                      : () {
                          if (passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.settings_passwordRequired),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            return;
                          }
                          context.read<SettingsBloc>().add(
                                DeleteAccountRequested(passwordController.text),
                              );
                          Navigator.pop(dialogContext);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: state.isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.common_delete),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
