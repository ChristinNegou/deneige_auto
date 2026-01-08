import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Acceptation des conditions',
              'En utilisant l\'application Deneige Auto, vous acceptez d\'être lié par les présentes conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
            ),
            _buildSection(
              '2. Description du service',
              'Deneige Auto est une plateforme mettant en relation des clients ayant besoin de services de déneigement avec des prestataires de services (déneigeurs) indépendants. Nous ne sommes pas l\'employeur des déneigeurs.',
            ),
            _buildSection(
              '3. Inscription et compte',
              '''Pour utiliser nos services, vous devez:
• Être âgé d'au moins 18 ans
• Fournir des informations exactes et à jour
• Maintenir la confidentialité de vos identifiants
• Nous informer de toute utilisation non autorisée de votre compte''',
            ),
            _buildSection(
              '4. Réservations et paiements',
              '''• Les prix affichés incluent les taxes applicables
• Le paiement est effectué au moment de la réservation
• Les annulations sont soumises à notre politique d'annulation
• Un remboursement peut être demandé selon les conditions applicables''',
            ),
            _buildSection(
              '5. Politique d\'annulation',
              '''• Annulation plus de 24h avant: remboursement complet
• Annulation entre 12h et 24h avant: remboursement de 50%
• Annulation moins de 12h avant: aucun remboursement
• Annulation par le déneigeur: remboursement complet et priorité de réassignation''',
            ),
            _buildSection(
              '6. Responsabilités de l\'utilisateur',
              '''Vous vous engagez à:
• Fournir un accès sécuritaire au véhicule
• Décrire précisément l'emplacement du véhicule
• Être disponible pour toute communication urgente
• Respecter les déneigeurs et leur travail''',
            ),
            _buildSection(
              '7. Responsabilités des déneigeurs',
              '''Les déneigeurs s'engagent à:
• Effectuer le service avec professionnalisme
• Respecter les horaires convenus
• Prendre soin des véhicules des clients
• Signaler tout problème ou dommage''',
            ),
            _buildSection(
              '8. Limitation de responsabilité',
              'Deneige Auto agit comme intermédiaire et ne peut être tenu responsable des dommages directs ou indirects résultant de l\'exécution des services par les déneigeurs. Tout litige doit être signalé dans les 24h suivant le service.',
            ),
            _buildSection(
              '9. Propriété intellectuelle',
              'Tous les contenus de l\'application (logos, textes, images, code) sont la propriété de Deneige Auto et sont protégés par les lois sur la propriété intellectuelle.',
            ),
            _buildSection(
              '10. Modification des conditions',
              'Nous nous réservons le droit de modifier ces conditions à tout moment. Les utilisateurs seront informés des changements significatifs par notification dans l\'application.',
            ),
            _buildSection(
              '11. Résiliation',
              'Nous pouvons suspendre ou résilier votre compte en cas de violation de ces conditions. Vous pouvez supprimer votre compte à tout moment depuis les paramètres de l\'application.',
            ),
            _buildSection(
              '12. Droit applicable',
              'Ces conditions sont régies par les lois de la province de Québec, Canada. Tout litige sera soumis aux tribunaux compétents de Montréal.',
            ),
            _buildSection(
              '13. Contact',
              'Pour toute question concernant ces conditions, contactez-nous via la section "Aide et Support" de l\'application.',
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
