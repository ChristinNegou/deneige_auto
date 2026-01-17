import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_chat_message.dart';
import '../entities/ai_conversation.dart';

/// Interface du repository pour le chat IA
abstract class AIChatRepository {
  /// Récupère le statut du service IA
  Future<Either<Failure, AIChatStatus>> getStatus();

  /// Récupère la liste des conversations de l'utilisateur
  Future<Either<Failure, List<AIConversation>>> getConversations({
    int page = 1,
    int limit = 20,
  });

  /// Crée une nouvelle conversation
  Future<Either<Failure, AIConversation>> createConversation({
    String? reservationId,
    String? vehicleId,
  });

  /// Récupère une conversation spécifique
  Future<Either<Failure, AIConversation>> getConversation(
      String conversationId);

  /// Envoie un message et reçoit la réponse
  Future<Either<Failure, AIChatMessage>> sendMessage(
    String conversationId,
    String content,
  );

  /// Envoie un message avec streaming de la réponse
  Stream<Either<Failure, String>> sendMessageStreaming(
    String conversationId,
    String content,
  );

  /// Archive/supprime une conversation
  Future<Either<Failure, void>> deleteConversation(String conversationId);

  /// Récupère les messages d'une conversation
  Future<Either<Failure, List<AIChatMessage>>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  });
}

/// Statut du service IA
class AIChatStatus {
  final bool enabled;
  final bool configured;
  final List<AIQuickAction> quickActions;

  const AIChatStatus({
    required this.enabled,
    required this.configured,
    required this.quickActions,
  });

  bool get isAvailable => enabled && configured;
}
