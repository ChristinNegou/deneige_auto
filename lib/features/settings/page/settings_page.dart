import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection_container.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../presentation/bloc/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _language = 'fr';
  String _appVersion = '1.0.0';

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

  @override
  Widget build(BuildContext context) {
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
              title: const Text('Paramètres'),
              backgroundColor: AppTheme.surface,
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      // Section Notifications
                      _buildSectionHeader('Notifications'),
                      _buildSwitchTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications push',
                        subtitle: 'Recevoir des alertes sur votre appareil',
                        value: state.preferences.pushNotificationsEnabled,
                        onChanged: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdatePushNotifications(value));
                        },
                      ),
                      _buildSwitchTile(
                        icon: Icons.volume_up_outlined,
                        title: 'Sons',
                        subtitle: 'Activer les sons de notification',
                        value: state.preferences.soundEnabled,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateSound(value));
                        },
                      ),

                      const Divider(height: 32),

                      // Section Apparence
                      _buildSectionHeader('Apparence'),
                      _buildSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Thème sombre',
                        subtitle: 'Utiliser le thème sombre',
                        value: state.preferences.darkThemeEnabled,
                        onChanged: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateDarkTheme(value));
                        },
                      ),

                      const Divider(height: 32),

                      // Section Langue (NE PAS MODIFIER)
                      _buildSectionHeader('Langue'),
                      _buildListTile(
                        icon: Icons.language,
                        title: 'Langue',
                        trailing: DropdownButton<String>(
                          value: _language,
                          underline: const SizedBox(),
                          dropdownColor: AppTheme.surfaceElevated,
                          items: const [
                            DropdownMenuItem(
                                value: 'fr', child: Text('Français')),
                            DropdownMenuItem(
                                value: 'en', child: Text('English')),
                          ],
                          onChanged: (value) =>
                              setState(() => _language = value!),
                        ),
                      ),

                      const Divider(height: 32),

                      // Section Compte
                      _buildSectionHeader('Compte'),
                      _buildListTile(
                        icon: Icons.person_outline,
                        title: 'Modifier le profil',
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.textTertiary),
                        onTap: () =>
                            Navigator.pushNamed(context, '/profile/edit'),
                      ),
                      _buildListTile(
                        icon: Icons.delete_outline,
                        title: 'Supprimer mon compte',
                        titleColor: AppTheme.error,
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.error),
                        onTap: () => _showDeleteAccountDialog(context),
                      ),

                      const Divider(height: 32),

                      // Section Légal
                      _buildSectionHeader('Légal'),
                      _buildListTile(
                        icon: Icons.policy_outlined,
                        title: 'Politique de confidentialité',
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.textTertiary),
                        onTap: () =>
                            Navigator.pushNamed(context, '/settings/privacy'),
                      ),
                      _buildListTile(
                        icon: Icons.description_outlined,
                        title: 'Conditions d\'utilisation',
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppTheme.textTertiary),
                        onTap: () =>
                            Navigator.pushNamed(context, '/settings/terms'),
                      ),

                      const Divider(height: 32),

                      // Section À propos
                      _buildSectionHeader('À propos'),
                      _buildListTile(
                        icon: Icons.info_outline,
                        title: 'Version de l\'application',
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

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.error),
              SizedBox(width: 12),
              Text(
                'Supprimer le compte',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cette action est irréversible. Toutes vos données seront supprimées.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Entrez votre mot de passe pour confirmer:',
                style: TextStyle(
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
                  hintText: 'Mot de passe',
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
              child: const Text(
                'Annuler',
                style: TextStyle(color: AppTheme.textSecondary),
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
                              const SnackBar(
                                content:
                                    Text('Veuillez entrer votre mot de passe'),
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
                      : const Text('Supprimer'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
