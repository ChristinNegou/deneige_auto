import '../domain/entities/faq_item.dart';

/// FAQ spécifique pour les déneigeurs
class WorkerFaqData {
  static const List<FaqItem> faqItems = [
    // Général
    FaqItem(
      question: 'Comment devenir déneigeur sur Deneige Auto?',
      answer:
          'Pour devenir déneigeur, vous devez créer un compte en tant que déneigeur, compléter votre profil avec vos informations personnelles, ajouter votre équipement disponible et configurer votre compte bancaire pour recevoir vos paiements.',
      category: FaqCategory.general,
    ),
    FaqItem(
      question: 'Quelles sont les conditions pour être déneigeur?',
      answer:
          'Vous devez avoir au moins 18 ans, posséder un équipement de déneigement de base (pelle, balai, grattoir), être disponible pendant les périodes de neige et avoir un compte bancaire canadien pour recevoir vos paiements.',
      category: FaqCategory.general,
    ),
    FaqItem(
      question: 'Puis-je choisir mes zones de travail?',
      answer:
          'Oui! Dans vos paramètres, vous pouvez définir vos zones préférées. Vous recevrez des notifications prioritaires pour les jobs dans ces zones, mais vous pouvez aussi accepter des jobs ailleurs.',
      category: FaqCategory.general,
    ),

    // Jobs / Réservations
    FaqItem(
      question: 'Comment recevoir des jobs?',
      answer:
          'Activez votre disponibilité dans l\'application. Vous recevrez des notifications push pour les nouveaux jobs disponibles dans votre zone. Vous pouvez alors accepter ou refuser chaque job.',
      category: FaqCategory.reservations,
    ),
    FaqItem(
      question: 'Puis-je accepter plusieurs jobs en même temps?',
      answer:
          'Oui, vous pouvez gérer jusqu\'à 5 jobs simultanément. Dans vos paramètres, définissez le nombre maximum de jobs actifs que vous souhaitez avoir en même temps. Nous recommandons 2-3 jobs pour un service optimal.',
      category: FaqCategory.reservations,
    ),
    FaqItem(
      question: 'Comment annuler un job accepté?',
      answer:
          'Vous pouvez annuler un job avant de commencer le travail. Allez dans les détails du job et appuyez sur "Annuler". Attention: des annulations fréquentes peuvent affecter votre score et votre visibilité.',
      category: FaqCategory.reservations,
    ),
    FaqItem(
      question: 'Que faire si je ne trouve pas le véhicule?',
      answer:
          'Utilisez la messagerie intégrée pour contacter le client. Si le véhicule est introuvable après 15 minutes et sans réponse du client, vous pouvez signaler le problème et annuler le job sans pénalité.',
      category: FaqCategory.reservations,
    ),
    FaqItem(
      question: 'Comment signaler un problème avec un job?',
      answer:
          'Dans les détails du job, appuyez sur "Signaler un problème". Décrivez la situation et ajoutez des photos si nécessaire. Notre équipe examinera votre signalement rapidement.',
      category: FaqCategory.reservations,
    ),

    // Paiements
    FaqItem(
      question: 'Comment suis-je payé?',
      answer:
          'Les paiements sont effectués automatiquement via Stripe Connect. Après chaque job complété, le montant est transféré sur votre compte bancaire dans un délai de 2-7 jours ouvrables.',
      category: FaqCategory.payments,
    ),
    FaqItem(
      question: 'Comment configurer mon compte bancaire?',
      answer:
          'Allez dans Paramètres > Mes paiements > Configuration Stripe. Suivez les étapes pour vérifier votre identité et ajouter vos coordonnées bancaires. Ce processus est sécurisé et obligatoire pour recevoir vos paiements.',
      category: FaqCategory.payments,
    ),
    FaqItem(
      question: 'Comment sont calculés mes gains?',
      answer:
          'Vos gains dépendent du type de service (déneigement standard, avec options), de la taille du véhicule et de la distance. Vous voyez le montant exact avant d\'accepter chaque job. Deneige Auto prélève une commission de 15%.',
      category: FaqCategory.payments,
    ),
    FaqItem(
      question: 'Comment fonctionnent les pourboires?',
      answer:
          'Les clients peuvent laisser un pourboire après le service. Les pourboires sont 100% pour vous, sans commission. Vous recevez une notification et le montant est ajouté à votre prochain paiement.',
      category: FaqCategory.payments,
    ),
    FaqItem(
      question: 'Où voir mon historique de gains?',
      answer:
          'Allez dans l\'onglet "Gains" pour voir vos revenus quotidiens, hebdomadaires et mensuels. Vous pouvez aussi voir le détail de chaque job et les pourboires reçus.',
      category: FaqCategory.payments,
    ),

    // Litiges et réclamations
    FaqItem(
      question: 'Que se passe-t-il si un client me signale un no-show?',
      answer:
          'Si un client signale que vous n\'êtes pas venu, vous recevrez une notification et aurez l\'opportunité de répondre. Si vous avez marqué "En route" dans l\'application, cela sera pris en compte. Les faux signalements de clients sont aussi sanctionnés.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Comment répondre à une réclamation client?',
      answer:
          'Vous recevrez une notification dès qu\'un litige est ouvert contre vous. Allez dans l\'application pour voir les détails et répondre. Expliquez votre version des faits et ajoutez des photos comme preuve si disponible. Vous avez généralement 48 heures pour répondre.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Quelles sont les conséquences d\'un litige contre moi?',
      answer:
          'Les conséquences dépendent de la décision et de votre historique:\n• Premier avertissement: notification\n• Récidive: suspension temporaire (3-7 jours)\n• Problèmes répétés: suspension prolongée (30 jours)\n• Cas graves: exclusion permanente\n\nMaintenez un bon service pour éviter les litiges.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Comment contester une décision défavorable?',
      answer:
          'Si vous n\'êtes pas d\'accord avec la décision prise sur un litige, vous pouvez faire appel dans les 7 jours. Fournissez des preuves supplémentaires (photos, messages, etc.) pour appuyer votre contestation.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Comment signaler un client problématique?',
      answer:
          'Si un client est abusif, introuvable malgré vos efforts, ou fait de fausses réclamations, vous pouvez le signaler dans les détails du job. Notre équipe examinera la situation et pourra sanctionner le client si nécessaire.',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Mon paiement est-il affecté pendant un litige?',
      answer:
          'Pendant l\'examen d\'un litige, le paiement correspondant peut être temporairement retenu. Une fois la décision prise:\n• Litige en votre faveur: paiement complet versé\n• Litige contre vous: remboursement au client (partiel ou total selon la décision)',
      category: FaqCategory.disputes,
    ),
    FaqItem(
      question: 'Comment protéger mon score de fiabilité?',
      answer:
          'Pour maintenir un bon score:\n• Arrivez à l\'heure (marquez "En route" dans l\'app)\n• Prenez des photos avant/après chaque job\n• Communiquez avec le client en cas de problème\n• Complétez le travail selon les standards demandés\n• Évitez les annulations de dernière minute',
      category: FaqCategory.disputes,
    ),

    // Compte
    FaqItem(
      question: 'Comment modifier mon équipement disponible?',
      answer:
          'Dans Paramètres ou dans votre Profil, vous pouvez cocher/décocher les équipements que vous possédez: pelle, balai, grattoir, épandeur de sel, souffleuse. Cela aide à vous assigner les jobs appropriés.',
      category: FaqCategory.account,
    ),
    FaqItem(
      question: 'Comment changer mes notifications?',
      answer:
          'Dans Paramètres > Notifications, vous pouvez activer/désactiver les alertes pour: nouveaux jobs, jobs urgents et pourboires reçus.',
      category: FaqCategory.account,
    ),
    FaqItem(
      question: 'Comment améliorer mon score déneigeur?',
      answer:
          'Votre score est basé sur: la qualité du service (évaluations clients), le taux d\'acceptation des jobs, la ponctualité et le taux de complétion. Offrez un service de qualité et soyez fiable pour améliorer votre score.',
      category: FaqCategory.account,
    ),
    FaqItem(
      question: 'Puis-je prendre une pause de l\'application?',
      answer:
          'Oui! Désactivez simplement votre disponibilité dans l\'application. Vous ne recevrez plus de notifications de jobs. Réactivez quand vous êtes prêt à travailler.',
      category: FaqCategory.account,
    ),
  ];

  static List<FaqItem> getByCategory(FaqCategory category) {
    return faqItems.where((item) => item.category == category).toList();
  }
}
