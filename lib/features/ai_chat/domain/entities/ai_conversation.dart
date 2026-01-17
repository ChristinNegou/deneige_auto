import 'package:equatable/equatable.dart';
import 'ai_chat_message.dart';

/// Statut d'une conversation IA
enum AIConversationStatus {
  active,
  archived,
}

/// Entité représentant une conversation avec l'assistant IA
class AIConversation extends Equatable {
  final String id;
  final String title;
  final List<AIChatMessage> messages;
  final AIConversationStatus status;
  final int totalInputTokens;
  final int totalOutputTokens;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? reservationId;
  final String? vehicleId;

  const AIConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.status,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.createdAt,
    required this.lastMessageAt,
    this.reservationId,
    this.vehicleId,
  });

  /// Vérifie si la conversation est active
  bool get isActive => status == AIConversationStatus.active;

  /// Nombre total de messages
  int get messageCount => messages.length;

  /// Dernier message de la conversation
  AIChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Total des tokens utilisés
  int get totalTokens => totalInputTokens + totalOutputTokens;

  /// Crée une copie avec des modifications
  AIConversation copyWith({
    String? id,
    String? title,
    List<AIChatMessage>? messages,
    AIConversationStatus? status,
    int? totalInputTokens,
    int? totalOutputTokens,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? reservationId,
    String? vehicleId,
  }) {
    return AIConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      reservationId: reservationId ?? this.reservationId,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        messages,
        status,
        totalInputTokens,
        totalOutputTokens,
        createdAt,
        lastMessageAt,
        reservationId,
        vehicleId,
      ];
}

/// Action rapide suggérée par l'assistant
class AIQuickAction extends Equatable {
  final String id;
  final String label;
  final String prompt;

  const AIQuickAction({
    required this.id,
    required this.label,
    required this.prompt,
  });

  @override
  List<Object?> get props => [id, label, prompt];
}
