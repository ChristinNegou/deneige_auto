import '../../domain/entities/ai_chat_message.dart';
import '../../domain/entities/ai_conversation.dart';

/// Modèle JSON pour un message IA
class AIChatMessageModel extends AIChatMessage {
  const AIChatMessageModel({
    required super.id,
    required super.role,
    required super.content,
    required super.timestamp,
    super.inputTokens,
    super.outputTokens,
    super.simulated,
  });

  factory AIChatMessageModel.fromJson(Map<String, dynamic> json) {
    return AIChatMessageModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      role: _parseRole(json['role'] as String? ?? 'user'),
      content: json['content'] as String? ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      inputTokens: json['metadata']?['tokens']?['input'] as int?,
      outputTokens: json['metadata']?['tokens']?['output'] as int?,
      simulated: json['metadata']?['simulated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role == AIChatRole.user ? 'user' : 'assistant',
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': {
        'tokens': {
          'input': inputTokens,
          'output': outputTokens,
        },
        'simulated': simulated,
      },
    };
  }

  static AIChatRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'assistant':
        return AIChatRole.assistant;
      case 'user':
      default:
        return AIChatRole.user;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Modèle JSON pour une conversation IA
class AIConversationModel extends AIConversation {
  const AIConversationModel({
    required super.id,
    required super.title,
    required super.messages,
    required super.status,
    required super.totalInputTokens,
    required super.totalOutputTokens,
    required super.createdAt,
    required super.lastMessageAt,
    super.reservationId,
    super.vehicleId,
  });

  factory AIConversationModel.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesJson
        .map((m) => AIChatMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return AIConversationModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Nouvelle conversation',
      messages: messages,
      status: _parseStatus(json['status'] as String? ?? 'active'),
      totalInputTokens: json['totalTokens']?['input'] as int? ?? 0,
      totalOutputTokens: json['totalTokens']?['output'] as int? ?? 0,
      createdAt: _parseTimestamp(json['createdAt']),
      lastMessageAt: _parseTimestamp(json['lastMessageAt']),
      reservationId: json['context']?['reservationId'] as String?,
      vehicleId: json['context']?['vehicleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages':
          messages.map((m) => (m as AIChatMessageModel).toJson()).toList(),
      'status': status == AIConversationStatus.active ? 'active' : 'archived',
      'totalTokens': {
        'input': totalInputTokens,
        'output': totalOutputTokens,
      },
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'context': {
        'reservationId': reservationId,
        'vehicleId': vehicleId,
      },
    };
  }

  static AIConversationStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'archived':
        return AIConversationStatus.archived;
      case 'active':
      default:
        return AIConversationStatus.active;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Modèle pour une action rapide
class AIQuickActionModel extends AIQuickAction {
  const AIQuickActionModel({
    required super.id,
    required super.label,
    required super.prompt,
  });

  factory AIQuickActionModel.fromJson(Map<String, dynamic> json) {
    return AIQuickActionModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
    );
  }
}
