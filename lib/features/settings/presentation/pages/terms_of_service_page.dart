import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.settings_termsOfService),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              l10n.terms_section1Title,
              l10n.terms_section1Body,
            ),
            _buildSection(
              l10n.terms_section2Title,
              l10n.terms_section2Body,
            ),
            _buildSection(
              l10n.terms_section3Title,
              l10n.terms_section3Body,
            ),
            _buildSection(
              l10n.terms_section4Title,
              l10n.terms_section4Body,
            ),
            _buildSection(
              l10n.terms_section5Title,
              l10n.terms_section5Body,
            ),
            _buildSection(
              l10n.terms_section6Title,
              l10n.terms_section6Body,
            ),
            _buildSection(
              l10n.terms_section7Title,
              l10n.terms_section7Body,
            ),
            _buildSection(
              l10n.terms_section8Title,
              l10n.terms_section8Body,
            ),
            _buildSection(
              l10n.terms_section9Title,
              l10n.terms_section9Body,
            ),
            _buildSection(
              l10n.terms_section10Title,
              l10n.terms_section10Body,
            ),
            _buildSection(
              l10n.terms_section11Title,
              l10n.terms_section11Body,
            ),
            _buildSection(
              l10n.terms_section12Title,
              l10n.terms_section12Body,
            ),
            _buildSection(
              l10n.terms_section13Title,
              l10n.terms_section13Body,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.terms_lastUpdate,
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
