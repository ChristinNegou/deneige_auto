import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';

enum LegalDocumentType {
  privacyPolicy,
  termsOfService,
}

class LegalPage extends StatelessWidget {
  final LegalDocumentType documentType;

  const LegalPage({
    super.key,
    required this.documentType,
  });

  String _title(BuildContext context) {
    switch (documentType) {
      case LegalDocumentType.privacyPolicy:
        return AppLocalizations.of(context)!.legal_privacyPolicy;
      case LegalDocumentType.termsOfService:
        return AppLocalizations.of(context)!.legal_termsOfService;
    }
  }

  // URLs des documents hébergés (à remplacer par vos vraies URLs)
  static const String privacyPolicyUrl =
      'https://deneige-auto.com/legal/politique-confidentialite';
  static const String termsOfServiceUrl =
      'https://deneige-auto.com/legal/conditions-utilisation';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_title(context)),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (documentType) {
      case LegalDocumentType.privacyPolicy:
        return _buildPrivacyPolicyContent(context);
      case LegalDocumentType.termsOfService:
        return _buildTermsOfServiceContent(context);
    }
  }

  Widget _buildPrivacyPolicyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLastUpdated(context, '19 janvier 2025'),
        const SizedBox(height: 24),
        _buildSection(
          '1. Introduction',
          'Bienvenue sur Deneige-Auto. La présente politique de confidentialité décrit comment nous collectons, utilisons, stockons et protégeons vos renseignements personnels conformément à la Loi sur la protection des renseignements personnels dans le secteur privé du Québec (Loi 25) et aux autres lois applicables.\n\nEn utilisant notre application mobile et nos services, vous consentez aux pratiques décrites dans cette politique.',
        ),
        _buildSection(
          '2. Renseignements que nous collectons',
          '''Nous collectons les types de renseignements suivants :

• Identité : Nom, prénom, adresse courriel
• Coordonnées : Numéro de téléphone, adresse
• Informations de paiement : Via Stripe (traitement sécurisé)
• Informations sur le véhicule : Marque, modèle, couleur, plaque, photo
• Données de localisation : Coordonnées GPS pour localiser votre véhicule
• Photos : Photos du véhicule avant/après déneigement''',
        ),
        _buildSection(
          '3. Utilisation des données',
          '''Nous utilisons vos données pour :

• Fournir nos services de déneigement
• Traiter les paiements et remboursements
• Envoyer des notifications sur votre réservation
• Améliorer nos services
• Assurer la sécurité et prévenir la fraude
• Gérer les litiges entre clients et déneigeurs''',
        ),
        _buildSection(
          '4. Partage des données',
          '''Nous partageons vos données avec :

• Les déneigeurs (pour exécuter le service)
• Stripe (traitement des paiements)
• Firebase (notifications push)
• Cloudinary (hébergement des photos)
• Anthropic/Claude AI (assistance par chatbot)

Nous ne vendons jamais vos données à des tiers.''',
        ),
        _buildSection(
          '5. Vos droits (Loi 25)',
          '''Vous disposez des droits suivants :

• Droit d'accès à vos données
• Droit de rectification
• Droit à l'effacement
• Droit à la portabilité
• Droit de retirer votre consentement

Pour exercer vos droits : privacy@deneige-auto.com''',
        ),
        _buildSection(
          '6. Conservation des données',
          '''• Données de compte : Durée de l'inscription + 3 ans
• Historique des réservations : 7 ans (obligations fiscales)
• Photos de véhicules : 90 jours après le service
• Données de litiges : 5 ans après résolution''',
        ),
        _buildSection(
          '7. Sécurité',
          'Nous mettons en œuvre des mesures de sécurité appropriées : chiffrement des données en transit et au repos, authentification sécurisée, accès limité aux données.',
        ),
        _buildSection(
          '8. Contact',
          '''Pour toute question concernant cette politique :

Courriel : privacy@deneige-auto.com
Commission d'accès à l'information du Québec : www.cai.gouv.qc.ca''',
        ),
      ],
    );
  }

  Widget _buildTermsOfServiceContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLastUpdated(context, '19 janvier 2025'),
        const SizedBox(height: 24),
        _buildSection(
          '1. Acceptation des conditions',
          'En utilisant l\'application Deneige-Auto, vous acceptez d\'être lié par les présentes Conditions Générales d\'Utilisation. Si vous n\'acceptez pas ces Conditions, veuillez ne pas utiliser l\'Application.',
        ),
        _buildSection(
          '2. Description du service',
          '''Deneige-Auto est une plateforme de mise en relation entre :
• Des clients souhaitant faire déneiger leur véhicule
• Des déneigeurs indépendants offrant des services de déneigement

Deneige-Auto agit comme intermédiaire et ne fournit pas directement les services de déneigement.''',
        ),
        _buildSection(
          '3. Inscription',
          '''Pour utiliser l'Application, vous devez :
• Être âgé d'au moins 18 ans
• Fournir des informations exactes et complètes
• Maintenir la confidentialité de vos identifiants''',
        ),
        _buildSection(
          '4. Conditions pour les clients',
          '''En effectuant une réservation, vous vous engagez à :
• Fournir l'emplacement exact de votre véhicule
• Vous assurer que le véhicule est accessible
• Respecter l'heure de départ indiquée''',
        ),
        _buildSection(
          '5. Politique d\'annulation',
          '''• Plus de 2h avant : Remboursement complet
• Entre 30 min et 2h : 50% du montant
• Moins de 30 min : Aucun remboursement
• Après assignation : Aucun remboursement''',
        ),
        _buildSection(
          '6. Conditions pour les déneigeurs',
          '''Les déneigeurs sont des travailleurs autonomes indépendants responsables de :
• Leurs impôts et cotisations sociales
• Leur équipement de déneigement
• Leur assurance responsabilité civile

Commission de la plateforme : 20%''',
        ),
        _buildSection(
          '7. Litiges',
          '''En cas de problème, vous pouvez ouvrir un litige dans les 72h suivant le service. Notre équipe examine les preuves et rend une décision dans les 5 jours ouvrables.''',
        ),
        _buildSection(
          '8. Responsabilité',
          '''Deneige-Auto agit comme intermédiaire et n'est pas responsable de la qualité du travail effectué par les déneigeurs ni des dommages causés aux véhicules.''',
        ),
        _buildSection(
          '9. Droit applicable',
          '''Ces Conditions sont régies par les lois du Québec et les lois fédérales du Canada. Tout litige sera soumis aux tribunaux du Québec.''',
        ),
        _buildSection(
          '10. Contact',
          '''Pour toute question :
Courriel : support@deneige-auto.com''',
        ),
      ],
    );
  }

  Widget _buildLastUpdated(BuildContext context, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppLocalizations.of(context)!.legal_lastUpdated(date),
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.info,
          fontWeight: FontWeight.w500,
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
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher les liens légaux (utilisable dans plusieurs écrans)
class LegalLinksWidget extends StatelessWidget {
  final bool showCheckbox;
  final bool? isChecked;
  final ValueChanged<bool?>? onCheckChanged;
  final Color? textColor;

  const LegalLinksWidget({
    super.key,
    this.showCheckbox = false,
    this.isChecked,
    this.onCheckChanged,
    this.textColor,
  });

  void _openLegalPage(BuildContext context, LegalDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalPage(documentType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppTheme.textSecondary;

    if (showCheckbox) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isChecked ?? false,
              onChanged: onCheckChanged,
              activeColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  AppLocalizations.of(context)!.legal_iAccept,
                  style: TextStyle(fontSize: 13, color: color),
                ),
                GestureDetector(
                  onTap: () =>
                      _openLegalPage(context, LegalDocumentType.termsOfService),
                  child: Text(
                    AppLocalizations.of(context)!.legal_termsOfService,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.legal_andThe,
                  style: TextStyle(fontSize: 13, color: color),
                ),
                GestureDetector(
                  onTap: () =>
                      _openLegalPage(context, LegalDocumentType.privacyPolicy),
                  child: Text(
                    AppLocalizations.of(context)!.legal_privacyPolicy,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Version sans checkbox (pour login ou settings)
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        GestureDetector(
          onTap: () =>
              _openLegalPage(context, LegalDocumentType.termsOfService),
          child: Text(
            AppLocalizations.of(context)!.legal_termsOfService,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          ' • ',
          style: TextStyle(fontSize: 12, color: color),
        ),
        GestureDetector(
          onTap: () => _openLegalPage(context, LegalDocumentType.privacyPolicy),
          child: Text(
            AppLocalizations.of(context)!.legal_privacyPolicy,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

/// Page listant tous les documents légaux (pour les paramètres)
class LegalDocumentsListPage extends StatelessWidget {
  const LegalDocumentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.legal_legalNotices),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDocumentTile(
            context,
            icon: Icons.description_outlined,
            title: AppLocalizations.of(context)!.legal_termsOfService,
            subtitle: AppLocalizations.of(context)!.legal_appUsageRules,
            documentType: LegalDocumentType.termsOfService,
          ),
          const SizedBox(height: 12),
          _buildDocumentTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: AppLocalizations.of(context)!.legal_privacyPolicy,
            subtitle: AppLocalizations.of(context)!.legal_privacyPolicySubtitle,
            documentType: LegalDocumentType.privacyPolicy,
          ),
          const SizedBox(height: 24),
          _buildInfoCard(context),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LegalDocumentType documentType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.shadowSM,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textTertiary,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LegalPage(documentType: documentType),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.info, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.legal_yourRights,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.legal_rightsDescription,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.legal_contactEmail,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
