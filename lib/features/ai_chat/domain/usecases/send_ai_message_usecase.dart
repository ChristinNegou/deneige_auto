import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_chat_message.dart';
import '../repositories/ai_chat_repository.dart';

/// Use case pour envoyer un message à l'assistant IA
class SendAIMessageUseCase {
  final AIChatRepository repository;

  SendAIMessageUseCase(this.repository);

  /// Envoie un message et retourne la réponse
  Future<Either<Failure, AIChatMessage>> call(
    String conversationId,
    String content,
  ) async {
    // Validation
    if (content.trim().isEmpty) {
      return const Left(
          ValidationFailure(message: 'Le message ne peut pas être vide'));
    }

    if (content.length > 2000) {
      return const Left(
        ValidationFailure(
            message: 'Le message ne peut pas dépasser 2000 caractères'),
      );
    }

    return await repository.sendMessage(conversationId, content.trim());
  }
}

/// Use case pour créer une nouvelle conversation
class CreateConversationUseCase {
  final AIChatRepository repository;

  CreateConversationUseCase(this.repository);

  Future<Either<Failure, dynamic>> call({
    String? reservationId,
    String? vehicleId,
  }) async {
    return await repository.createConversation(
      reservationId: reservationId,
      vehicleId: vehicleId,
    );
  }
}

/// Use case pour récupérer les conversations
class GetConversationsUseCase {
  final AIChatRepository repository;

  GetConversationsUseCase(this.repository);

  Future<Either<Failure, dynamic>> call({
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getConversations(page: page, limit: limit);
  }
}

/// Use case pour récupérer le statut du service IA
class GetAIStatusUseCase {
  final AIChatRepository repository;

  GetAIStatusUseCase(this.repository);

  Future<Either<Failure, AIChatStatus>> call() async {
    return await repository.getStatus();
  }
}

/// Use case pour archiver une conversation
class DeleteConversationUseCase {
  final AIChatRepository repository;

  DeleteConversationUseCase(this.repository);

  Future<Either<Failure, void>> call(String conversationId) async {
    return await repository.deleteConversation(conversationId);
  }
}
