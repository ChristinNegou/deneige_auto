import '../../../l10n/app_localizations.dart';
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
    FaqItem(
      question: 'Qu\'est-ce que l\'Assistant IA?',
      answer:
          'L\'Assistant IA est votre aide virtuel disponible 24/7 dans l\'application. Il peut répondre à vos questions sur le service, vous aider à résoudre des problèmes, donner des conseils et vous informer sur les conditions météo actuelles et prévues dans votre région.',
      category: FaqCategory.general,
    ),
    FaqItem(
      question: 'Comment utiliser l\'Assistant IA?',
      answer:
          'Accédez à l\'Assistant IA depuis le menu principal ou en appuyant sur l\'icône de chat. Posez vos questions en langage naturel et l\'assistant vous répondra instantanément. Il peut vous aider avec les réservations, les litiges, les paiements et bien plus.',
      category: FaqCategory.general,
    ),
    FaqItem(
      question: 'L\'Assistant IA peut-il me donner la météo?',
      answer:
          'Oui! L\'Assistant IA a accès aux données météo en temps réel. Demandez-lui simplement "Quelle est la météo?" ou "Va-t-il neiger demain?" pour obtenir les prévisions actuelles et à venir dans votre région.',
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

    // Litiges et réclamations
    FaqItem(
      question: 'Que faire si le déneigeur n\'est pas venu?',
      answer:
          'Si le déneigeur assigné n\'est pas venu à l\'heure prévue, vous pouvez signaler un "no-show" directement depuis les détails de la réservation. Le bouton "Signaler un no-show" apparaît 30 minutes après l\'heure de départ prévue. Si le no-show est confirmé, vous serez remboursé intégralement.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Comment créer un litige?',
      answer:
          'Pour créer un litige:\n1. Allez dans Profil > Mes litiges > Créer un litige\n2. Sélectionnez la réservation concernée\n3. Choisissez le type de problème (travail incomplet, qualité insuffisante, dommage, etc.)\n4. Décrivez la situation en détail\n5. Ajoutez des photos comme preuves\n6. Indiquez le montant réclamé si applicable\n7. Soumettez votre litige',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Quels types de litiges puis-je signaler?',
      answer:
          'Vous pouvez signaler plusieurs types de problèmes:\n• Déneigeur non venu (no-show)\n• Travail incomplet\n• Qualité insuffisante\n• Retard important\n• Dommage causé à votre véhicule\n• Mauvais emplacement déneigé\n• Surfacturation\n• Comportement inapproprié\n• Autre problème',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Comment ajouter des preuves à mon litige?',
      answer:
          'Les preuves renforcent votre dossier. Dans les détails du litige, appuyez sur "Ajouter des preuves" pour:\n• Prendre des photos ou les choisir depuis votre galerie (jusqu\'à 10 photos)\n• Ajouter une description détaillée\n\nConseils: prenez des photos claires, bien éclairées et horodatées si possible.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Qu\'est-ce que l\'analyse IA des litiges?',
      answer:
          'Notre système utilise l\'intelligence artificielle pour analyser objectivement les litiges. L\'IA examine les preuves (photos, descriptions, données GPS, historique), évalue la force des arguments et propose une recommandation. Cette analyse aide notre équipe à prendre des décisions justes et rapides.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Combien de temps ai-je pour signaler un problème?',
      answer:
          'Vous avez 24 heures après la fin du service pour signaler un problème ou un no-show. Passé ce délai, vous pouvez toujours contacter le support, mais le traitement pourrait être plus long.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Comment suivre l\'état de mon litige?',
      answer:
          'Rendez-vous dans Profil > Mes litiges pour voir tous vos litiges et leur statut: Ouvert, En examen, En attente de réponse, Résolu. Vous recevrez une notification dès qu\'une décision sera prise.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Puis-je faire appel d\'une décision?',
      answer:
          'Oui, si vous n\'êtes pas satisfait de la décision prise, vous pouvez faire appel dans les 7 jours suivant la résolution. Allez dans les détails du litige et appuyez sur "Faire appel". Expliquez pourquoi vous contestez la décision.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Comment sont traités les remboursements suite à un litige?',
      answer:
          'Si le litige est résolu en votre faveur, le remboursement est automatiquement traité sur votre méthode de paiement originale. Le délai est généralement de 3-5 jours ouvrables selon votre banque.',
      category: FaqCategory.disputes,
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

  static List<FaqItem> getLocalizedFaqItems(AppLocalizations l10n) {
    return [
      FaqItem(
          question: l10n.faq_q1,
          answer: l10n.faq_a1,
          category: FaqCategory.general),
      FaqItem(
          question: l10n.faq_q2,
          answer: l10n.faq_a2,
          category: FaqCategory.general),
      FaqItem(
          question: l10n.faq_q3,
          answer: l10n.faq_a3,
          category: FaqCategory.general),
      FaqItem(
          question: l10n.faq_q4,
          answer: l10n.faq_a4,
          category: FaqCategory.general),
      FaqItem(
          question: l10n.faq_q5,
          answer: l10n.faq_a5,
          category: FaqCategory.general),
      FaqItem(
          question: l10n.faq_q6,
          answer: l10n.faq_a6,
          category: FaqCategory.general),
      FaqItem(
          question: l10n.faq_q7,
          answer: l10n.faq_a7,
          category: FaqCategory.reservations),
      FaqItem(
          question: l10n.faq_q8,
          answer: l10n.faq_a8,
          category: FaqCategory.reservations),
      FaqItem(
          question: l10n.faq_q9,
          answer: l10n.faq_a9,
          category: FaqCategory.reservations),
      FaqItem(
          question: l10n.faq_q10,
          answer: l10n.faq_a10,
          category: FaqCategory.reservations),
      FaqItem(
          question: l10n.faq_q11,
          answer: l10n.faq_a11,
          category: FaqCategory.payments),
      FaqItem(
          question: l10n.faq_q12,
          answer: l10n.faq_a12,
          category: FaqCategory.payments),
      FaqItem(
          question: l10n.faq_q13,
          answer: l10n.faq_a13,
          category: FaqCategory.payments),
      FaqItem(
          question: l10n.faq_q14,
          answer: l10n.faq_a14,
          category: FaqCategory.payments),
      FaqItem(
          question: l10n.faq_q15,
          answer: l10n.faq_a15,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q16,
          answer: l10n.faq_a16,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q17,
          answer: l10n.faq_a17,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q18,
          answer: l10n.faq_a18,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q19,
          answer: l10n.faq_a19,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q20,
          answer: l10n.faq_a20,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q21,
          answer: l10n.faq_a21,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q22,
          answer: l10n.faq_a22,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q23,
          answer: l10n.faq_a23,
          category: FaqCategory.disputes),
      FaqItem(
          question: l10n.faq_q24,
          answer: l10n.faq_a24,
          category: FaqCategory.account),
      FaqItem(
          question: l10n.faq_q25,
          answer: l10n.faq_a25,
          category: FaqCategory.account),
      FaqItem(
          question: l10n.faq_q26,
          answer: l10n.faq_a26,
          category: FaqCategory.account),
      FaqItem(
          question: l10n.faq_q27,
          answer: l10n.faq_a27,
          category: FaqCategory.account),
    ];
  }

  static List<FaqItem> getLocalizedByCategory(
      AppLocalizations l10n, FaqCategory category) {
    return getLocalizedFaqItems(l10n)
        .where((item) => item.category == category)
        .toList();
  }
}
