import 'package:equatable/equatable.dart';
import '../../../../l10n/app_localizations.dart';

enum FaqCategory {
  general,
  reservations,
  payments,
  disputes,
  account;

  String get label {
    switch (this) {
      case FaqCategory.general:
        return 'Général';
      case FaqCategory.reservations:
        return 'Réservations';
      case FaqCategory.payments:
        return 'Paiements';
      case FaqCategory.disputes:
        return 'Litiges';
      case FaqCategory.account:
        return 'Compte';
    }
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case FaqCategory.general:
        return l10n.faq_catGeneral;
      case FaqCategory.reservations:
        return l10n.faq_catReservations;
      case FaqCategory.payments:
        return l10n.faq_catPayments;
      case FaqCategory.disputes:
        return l10n.faq_catDisputes;
      case FaqCategory.account:
        return l10n.faq_catAccount;
    }
  }
}

class FaqItem extends Equatable {
  final String question;
  final String answer;
  final FaqCategory category;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });

  @override
  List<Object?> get props => [question, answer, category];
}
