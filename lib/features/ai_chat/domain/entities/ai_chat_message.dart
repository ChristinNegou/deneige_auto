import 'package:equatable/equatable.dart';

/// Rôle du message dans la conversation IA
enum AIChatRole {
  user,
  assistant,
}

/// Entité représentant un message dans une conversation IA
class AIChatMessage extends Equatable {
  final String id;
  final AIChatRole role;
  final String content;
  final DateTime timestamp;
  final int? inputTokens;
  final int? outputTokens;
  final bool simulated;

  const AIChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.inputTokens,
    this.outputTokens,
    this.simulated = false,
  });

  /// Vérifie si c'est un message de l'utilisateur
  bool get isFromUser => role == AIChatRole.user;

  /// Vérifie si c'est un message de l'assistant
  bool get isFromAssistant => role == AIChatRole.assistant;

  /// Crée une copie avec des modifications
  AIChatMessage copyWith({
    String? id,
    AIChatRole? role,
    String? content,
    DateTime? timestamp,
    int? inputTokens,
    int? outputTokens,
    bool? simulated,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      simulated: simulated ?? this.simulated,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        content,
        timestamp,
        inputTokens,
        outputTokens,
        simulated,
      ];
}
