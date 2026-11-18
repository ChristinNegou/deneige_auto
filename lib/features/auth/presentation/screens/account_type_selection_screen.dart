import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user.dart';

class AccountTypeSelectionScreen extends StatelessWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Marque
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Icon(
                      Icons.ac_unit_rounded,
                      color: AppTheme.onPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.appTitle, style: AppTheme.headlineSmall),
                ],
              ),
              const Spacer(),
              Text(
                l10n.accountType_welcome,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 28),

              // Carte Client
              _AccountTypeCard(
                title: l10n.accountType_client,
                subtitle: l10n.accountType_clientSubtitle,
                iconWidget: SvgPicture.asset(
                  'assets/icons/person.svg',
                  width: 40,
                  height: 40,
                  colorFilter:
                      ColorFilter.mode(AppTheme.primary, BlendMode.srcIn),
                ),
                isClient: true,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.register,
                    arguments: UserRole.client,
                  );
                },
              ),

              const SizedBox(height: 12),

              // Carte Déneigeur
              _AccountTypeCard(
                title: l10n.accountType_snowWorker,
                subtitle: l10n.accountType_snowWorkerSubtitle,
                iconWidget: SvgPicture.asset(
                  'assets/icons/snowplow.svg',
                  width: 40,
                  height: 40,
                  colorFilter:
                      ColorFilter.mode(AppTheme.accentDark, BlendMode.srcIn),
                ),
                isClient: false,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.register,
                    arguments: UserRole.snowWorker,
                  );
                },
              ),

              const SizedBox(height: 32),

              // Lien vers connexion
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.register_hasAccount,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.login);
                    },
                    child: Text(l10n.login_submit),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final bool isClient;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    required this.isClient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = isClient ? AppTheme.primaryLight : AppTheme.accentLight;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: iconWidget,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: AppTheme.textPrimary),
        ],
      ),
    );
  }
}
