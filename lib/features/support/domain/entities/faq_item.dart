import 'package:equatable/equatable.dart';

enum FaqCategory {
  general,
  reservations,
  payments,
  account;

  String get label {
    switch (this) {
      case FaqCategory.general:
        return 'Général';
      case FaqCategory.reservations:
        return 'Réservations';
      case FaqCategory.payments:
        return 'Paiements';
      case FaqCategory.account:
        return 'Compte';
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
