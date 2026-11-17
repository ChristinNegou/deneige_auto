import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../disputes/presentation/pages/my_disputes_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (previous, current) {
            // Ne reconstruire que si AuthAuthenticated change ou si on se déconnecte
            return current is AuthAuthenticated ||
                current is AuthUnauthenticated;
          },
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(context, user),
                ),
                // Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildProfileCard(context, user),
                      const SizedBox(height: 24),
                      _buildMenuSection(context),
                      const SizedBox(height: 24),
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Text(l10n.profile_title, style: AppTheme.headlineMedium),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.editProfile),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.border),
            ),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  /// Identite : avatar (photo ou initiales), nom, courriel et telephone.
  Widget _buildProfileCard(BuildContext context, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    final String firstName = user?.firstName ?? l10n.profile_defaultName;
    final String lastName = user?.lastName ?? '';
    final String email = user?.email ?? '';
    final String phone = user?.phoneNumber ?? l10n.common_notSpecified;
    final String? photoUrl = user?.photoUrl;
    final initials = [firstName, lastName]
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .join();

    final initialsAvatar = Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppTheme.onPrimary,
        ),
      ),
    );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: 64,
                          height: 64,
                          errorBuilder: (_, __, ___) => initialsAvatar,
                        )
                      : initialsAvatar,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName'.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headlineMedium,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _buildInfoRow(Icons.phone_outlined, l10n.common_phone, phone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: AppTheme.bodySmall),
        const Spacer(),
        Text(value, style: AppTheme.labelLarge),
      ],
    );
  }

  /// Deux groupes : ce qui concerne le compte, puis les preferences et l'aide.
  Widget _buildMenuSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildMenuGroup([
          _buildMenuItem(
            context,
            icon: Icons.directions_car_filled_outlined,
            title: l10n.profile_myVehicles,
            subtitle: l10n.profile_manageVehicles,
            onTap: () => Navigator.pushNamed(context, AppRoutes.vehicles),
          ),
          _buildMenuItem(
            context,
            icon: Icons.credit_card_rounded,
            title: l10n.profile_payments,
            subtitle: l10n.profile_paymentHistory,
            onTap: () => Navigator.pushNamed(context, AppRoutes.payments),
          ),
          _buildMenuItem(
            context,
            icon: Icons.gavel_rounded,
            title: l10n.profile_myDisputes,
            subtitle: l10n.profile_disputesSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyDisputesPage()),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _buildMenuGroup([
          _buildMenuItem(
            context,
            icon: Icons.notifications_none_rounded,
            title: l10n.profile_notifications,
            subtitle: l10n.notifications_settings,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: l10n.profile_settings,
            subtitle: l10n.profile_settingsSubtitle,
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline_rounded,
            title: l10n.profile_helpSupport,
            subtitle: l10n.profile_helpSubtitle,
            onTap: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
          ),
        ]),
      ],
    );
  }

  Widget _buildMenuGroup(List<Widget> items) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64),
            items[i],
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM + 2),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.labelLarge),
                  const SizedBox(height: 1),
                  Text(subtitle, style: AppTheme.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () => _showLogoutDialog(context),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.error,
        minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
      ),
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: Text(l10n.common_logout),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.common_logout),
        content: Text(
          l10n.common_logoutConfirmAccount,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Déclencher la déconnexion via AuthBloc
              context.read<AuthBloc>().add(LogoutRequested());
              // Naviguer vers la page de sélection de compte
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.accountType,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.onPrimary,
              minimumSize: const Size(0, 44),
            ),
            child: Text(l10n.common_logout),
          ),
        ],
      ),
    );
  }
}
