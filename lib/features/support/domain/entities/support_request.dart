import 'package:equatable/equatable.dart';
import '../../../../l10n/app_localizations.dart';

enum SupportSubject {
  bug,
  question,
  suggestion,
  other;

  String get label {
    switch (this) {
      case SupportSubject.bug:
        return 'Signalement de bug';
      case SupportSubject.question:
        return 'Question';
      case SupportSubject.suggestion:
        return 'Suggestion';
      case SupportSubject.other:
        return 'Autre';
    }
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case SupportSubject.bug:
        return l10n.support_subjectBug;
      case SupportSubject.question:
        return l10n.support_subjectQuestion;
      case SupportSubject.suggestion:
        return l10n.support_subjectSuggestion;
      case SupportSubject.other:
        return l10n.support_subjectOther;
    }
  }

  String get value {
    switch (this) {
      case SupportSubject.bug:
        return 'bug';
      case SupportSubject.question:
        return 'question';
      case SupportSubject.suggestion:
        return 'suggestion';
      case SupportSubject.other:
        return 'other';
    }
  }

  static SupportSubject fromString(String value) {
    switch (value) {
      case 'bug':
        return SupportSubject.bug;
      case 'question':
        return SupportSubject.question;
      case 'suggestion':
        return SupportSubject.suggestion;
      default:
        return SupportSubject.other;
    }
  }
}

enum SupportStatus {
  pending,
  inProgress,
  resolved,
  closed;

  String get label {
    switch (this) {
      case SupportStatus.pending:
        return 'En attente';
      case SupportStatus.inProgress:
        return 'En cours';
      case SupportStatus.resolved:
        return 'Résolu';
      case SupportStatus.closed:
        return 'Fermé';
    }
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case SupportStatus.pending:
        return l10n.support_statusPending;
      case SupportStatus.inProgress:
        return l10n.support_statusInProgress;
      case SupportStatus.resolved:
        return l10n.support_statusResolved;
      case SupportStatus.closed:
        return l10n.support_statusClosed;
    }
  }

  static SupportStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return SupportStatus.inProgress;
      case 'resolved':
        return SupportStatus.resolved;
      case 'closed':
        return SupportStatus.closed;
      default:
        return SupportStatus.pending;
    }
  }
}

class SupportRequest extends Equatable {
  final String? id;
  final SupportSubject subject;
  final String message;
  final SupportStatus status;
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const SupportRequest({
    this.id,
    required this.subject,
    required this.message,
    this.status = SupportStatus.pending,
    this.adminNotes,
    this.createdAt,
    this.resolvedAt,
  });

  @override
  List<Object?> get props => [
        id,
        subject,
        message,
        status,
        adminNotes,
        createdAt,
        resolvedAt,
      ];
}
