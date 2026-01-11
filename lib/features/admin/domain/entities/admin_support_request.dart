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

  String get value {
    switch (this) {
      case SupportStatus.pending:
        return 'pending';
      case SupportStatus.inProgress:
        return 'in_progress';
      case SupportStatus.resolved:
        return 'resolved';
      case SupportStatus.closed:
        return 'closed';
    }
  }

  static SupportStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return SupportStatus.pending;
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

class AdminSupportRequest {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final SupportSubject subject;
  final String message;
  final SupportStatus status;
  final String? adminNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminSupportRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.subject,
    required this.message,
    required this.status,
    this.adminNotes,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminSupportRequest.fromJson(Map<String, dynamic> json) {
    return AdminSupportRequest(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      subject:
          SupportSubject.fromString(json['subject']?.toString() ?? 'other'),
      message: json['message']?.toString() ?? '',
      status: SupportStatus.fromString(json['status']?.toString() ?? 'pending'),
      adminNotes: json['adminNotes']?.toString(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AdminSupportRequest copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    SupportSubject? subject,
    String? message,
    SupportStatus? status,
    String? adminNotes,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminSupportRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
