import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Un compte admin connecte sur mobile : l'administration se fait sur le
/// site admin (une seule interface a maintenir).
class AdminWebNoticeScreen extends StatelessWidget {
  const AdminWebNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.desktop_windows_outlined,
                  size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 20),
              Text(l10n.adminNotice_title,
                  style: AppTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(l10n.adminNotice_text,
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              SelectableText(AppConfig.adminWebUrl,
                  style: AppTheme.labelLarge, textAlign: TextAlign.center),
              const Spacer(),
              FilledButton(
                onPressed: () => launchUrl(Uri.parse(AppConfig.adminWebUrl),
                    mode: LaunchMode.externalApplication),
                child: Text(l10n.adminNotice_open),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.accountType, (route) => false);
                },
                child: Text(l10n.common_logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
