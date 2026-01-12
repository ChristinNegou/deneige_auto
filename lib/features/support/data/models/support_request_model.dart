import '../../domain/entities/support_request.dart';
import '../../../../core/utils/time_utils.dart';

class SupportRequestModel extends SupportRequest {
  const SupportRequestModel({
    super.id,
    required super.subject,
    required super.message,
    super.status,
    super.adminNotes,
    super.createdAt,
    super.resolvedAt,
  });

  factory SupportRequestModel.fromJson(Map<String, dynamic> json) {
    return SupportRequestModel(
      id: json['id'] as String?,
      subject: SupportSubject.fromString(json['subject'] as String? ?? 'other'),
      message: json['message'] as String? ?? '',
      status: SupportStatus.fromString(json['status'] as String? ?? 'pending'),
      adminNotes: json['adminNotes'] as String?,
      createdAt: TimeUtils.parseUtcToLocalOrNull(json['createdAt'] as String?),
      resolvedAt:
          TimeUtils.parseUtcToLocalOrNull(json['resolvedAt'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.value,
      'message': message,
    };
  }

  factory SupportRequestModel.fromEntity(SupportRequest entity) {
    return SupportRequestModel(
      id: entity.id,
      subject: entity.subject,
      message: entity.message,
      status: entity.status,
      adminNotes: entity.adminNotes,
      createdAt: entity.createdAt,
      resolvedAt: entity.resolvedAt,
    );
  }
}
