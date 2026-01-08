import '../domain/entities/faq_item.dart';

class FaqData {
  static const List<FaqItem> faqItems = [
    // Général
    FaqItem(
      question: 'Comment fonctionne Deneige Auto?',
      answer:
          'Deneige Auto vous permet de réserver un service de déneigement pour votre véhicule. Créez une réservation en sélectionnant votre véhicule, son emplacement, la date et l\'heure souhaitées. Un déneigeur disponible dans votre zone sera assigné et viendra déneiger votre véhicule.',
      category: FaqCategory.general,
    ),
    FaqItem(
      question: 'Dans quelles zones le service est-il disponible?',
      answer:
          'Actuellement, notre service est disponible dans la grande région de Montréal et ses environs. Nous élargissons continuellement notre zone de couverture. Consultez la carte dans l\'application pour voir si votre emplacement est couvert.',
      category: FaqCategory.general,
    ),
    FaqItem(
      question: 'Quelles sont les heures de service?',
      answer:
          'Notre service est disponible 7 jours sur 7, de 5h00 à 22h00. Les horaires peuvent varier pendant les périodes de tempête intense.',
      category: FaqCategory.general,
    ),

    // Réservations
    FaqItem(
      question: 'Comment faire une réservation?',
      answer:
          '1. Ouvrez l\'application et appuyez sur "Nouvelle réservation"\n2. Sélectionnez votre véhicule ou ajoutez-en un nouveau\n3. Indiquez l\'emplacement du véhicule\n4. Choisissez la date et l\'heure\n5. Sélectionnez les options souhaitées\n6. Confirmez et payez',
      category: FaqCategory.reservations,
    ),
    FaqItem(
      question: 'Puis-je annuler ma réservation?',
      answer:
          'Oui, vous pouvez annuler votre réservation selon les conditions suivantes:\n• Plus de 24h avant: remboursement complet\n• Entre 12h et 24h avant: remboursement de 50%\n• Moins de 12h avant: aucun remboursement',
      category: FaqCategory.reservations,
    ),
    FaqItem(
      question: 'Comment savoir quand le déneigeur arrive?',
      answer:
          'Vous recevrez une notification push lorsque le déneigeur sera en route vers votre véhicule. Vous pouvez également suivre sa position en temps réel sur la carte dans l\'application.',
      category: FaqCategory.reservations,
    ),
    FaqItem(
      question: 'Que faire si le déneigeur ne trouve pas mon véhicule?',
      answer:
          'Assurez-vous d\'avoir bien décrit l\'emplacement de votre véhicule. Le déneigeur vous contactera via la messagerie de l\'application s\'il a des difficultés. Vous pouvez aussi ajouter une photo de votre véhicule pour faciliter son identification.',
      category: FaqCategory.reservations,
    ),

    // Paiements
    FaqItem(
      question: 'Quels modes de paiement sont acceptés?',
      answer:
          'Nous acceptons les cartes de crédit Visa, Mastercard et American Express. Le paiement est traité de manière sécurisée via Stripe.',
      category: FaqCategory.payments,
    ),
    FaqItem(
      question: 'Comment obtenir un remboursement?',
      answer:
          'Les remboursements sont automatiquement traités selon notre politique d\'annulation. Pour les cas spéciaux (service non satisfaisant, etc.), contactez notre support via la section "Aide et Support".',
      category: FaqCategory.payments,
    ),
    FaqItem(
      question: 'Puis-je ajouter un pourboire?',
      answer:
          'Oui! Après la fin du service, vous avez la possibilité d\'ajouter un pourboire au déneigeur. Cette option apparaît sur l\'écran de notation du service.',
      category: FaqCategory.payments,
    ),
    FaqItem(
      question: 'Comment gérer mes cartes de paiement?',
      answer:
          'Rendez-vous dans Profil > Paiements > Méthodes de paiement. Vous pouvez y ajouter, supprimer ou définir une carte par défaut.',
      category: FaqCategory.payments,
    ),

    // Compte
    FaqItem(
      question: 'Comment modifier mes informations personnelles?',
      answer:
          'Allez dans Profil > Modifier le profil pour changer votre nom, numéro de téléphone ou photo de profil.',
      category: FaqCategory.account,
    ),
    FaqItem(
      question: 'Comment ajouter ou supprimer un véhicule?',
      answer:
          'Rendez-vous dans Profil > Mes véhicules. Appuyez sur "+" pour ajouter un nouveau véhicule ou faites glisser vers la gauche sur un véhicule existant pour le supprimer.',
      category: FaqCategory.account,
    ),
    FaqItem(
      question: 'Comment supprimer mon compte?',
      answer:
          'Allez dans Paramètres > Supprimer mon compte. Cette action est irréversible et supprimera toutes vos données.',
      category: FaqCategory.account,
    ),
    FaqItem(
      question: 'J\'ai oublié mon mot de passe, que faire?',
      answer:
          'Sur l\'écran de connexion, appuyez sur "Mot de passe oublié?". Entrez votre email et vous recevrez un lien pour réinitialiser votre mot de passe.',
      category: FaqCategory.account,
    ),
  ];

  static List<FaqItem> getByCategory(FaqCategory category) {
    return faqItems.where((item) => item.category == category).toList();
  }
}
