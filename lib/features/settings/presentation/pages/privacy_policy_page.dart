import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Introduction',
              'Bienvenue sur Deneige Auto. Nous nous engageons à protéger votre vie privée et vos données personnelles. Cette politique explique comment nous collectons, utilisons et protégeons vos informations.',
            ),
            _buildSection(
              'Données collectées',
              '''Nous collectons les données suivantes:
• Informations d'identification (nom, prénom, email, téléphone)
• Informations de localisation pour le service de déneigement
• Informations sur vos véhicules
• Données de paiement (traitées de manière sécurisée par Stripe)
• Historique de vos réservations''',
            ),
            _buildSection(
              'Utilisation des données',
              '''Vos données sont utilisées pour:
• Fournir nos services de déneigement
• Communiquer avec vous concernant vos réservations
• Améliorer nos services
• Traiter vos paiements de manière sécurisée
• Vous envoyer des notifications pertinentes''',
            ),
            _buildSection(
              'Partage des données',
              '''Nous partageons vos données uniquement avec:
• Les déneigeurs assignés à vos réservations (informations nécessaires au service)
• Stripe pour le traitement des paiements
• Les autorités si requis par la loi''',
            ),
            _buildSection(
              'Sécurité',
              'Nous utilisons des mesures de sécurité conformes aux normes de l\'industrie pour protéger vos données, incluant le chiffrement des données sensibles et des connexions sécurisées (HTTPS).',
            ),
            _buildSection(
              'Conservation des données',
              'Vos données sont conservées aussi longtemps que votre compte est actif. Après suppression de votre compte, vos données sont effacées dans un délai de 30 jours.',
            ),
            _buildSection(
              'Vos droits',
              '''Vous avez le droit de:
• Accéder à vos données personnelles
• Corriger vos données inexactes
• Supprimer votre compte et vos données
• Exporter vos données
• Retirer votre consentement à tout moment''',
            ),
            _buildSection(
              'Cookies et technologies similaires',
              'Notre application mobile n\'utilise pas de cookies. Nous utilisons des identifiants d\'appareil uniquement pour les notifications push.',
            ),
            _buildSection(
              'Contact',
              'Pour toute question concernant cette politique de confidentialité, contactez-nous via la section "Aide et Support" de l\'application ou par email à support@deneige-auto.ca',
            ),
            const SizedBox(height: 16),
            Text(
              'Dernière mise à jour: Janvier 2025',
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
