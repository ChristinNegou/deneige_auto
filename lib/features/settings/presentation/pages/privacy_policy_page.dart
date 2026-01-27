import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.privacy_title),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              l10n.privacy_introTitle,
              l10n.privacy_introBody,
            ),
            _buildSection(
              l10n.privacy_dataCollectedTitle,
              l10n.privacy_dataCollectedBody,
            ),
            _buildSection(
              l10n.privacy_dataUsageTitle,
              l10n.privacy_dataUsageBody,
            ),
            _buildSection(
              l10n.privacy_dataSharingTitle,
              l10n.privacy_dataSharingBody,
            ),
            _buildSection(
              l10n.privacy_securityTitle,
              l10n.privacy_securityBody,
            ),
            _buildSection(
              l10n.privacy_retentionTitle,
              l10n.privacy_retentionBody,
            ),
            _buildSection(
              l10n.privacy_rightsTitle,
              l10n.privacy_rightsBody,
            ),
            _buildSection(
              l10n.privacy_cookiesTitle,
              l10n.privacy_cookiesBody,
            ),
            _buildSection(
              l10n.privacy_contactTitle,
              l10n.privacy_contactBody,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacy_lastUpdate,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
