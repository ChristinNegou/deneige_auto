part of 'ai_chat_bloc.dart';

/// Événements du BLoC AI Chat
abstract class AIChatEvent extends Equatable {
  const AIChatEvent();

  @override
  List<Object?> get props => [];
}

/// Vérifier le statut du service IA
class CheckAIStatus extends AIChatEvent {
  const CheckAIStatus();
}

/// Charger la liste des conversations
class LoadConversations extends AIChatEvent {
  final int page;
  final int limit;

  const LoadConversations({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

/// Créer une nouvelle conversation
class CreateNewConversation extends AIChatEvent {
  final String? reservationId;
  final String? vehicleId;

  const CreateNewConversation({this.reservationId, this.vehicleId});

  @override
  List<Object?> get props => [reservationId, vehicleId];
}

/// Charger une conversation existante
class LoadConversation extends AIChatEvent {
  final String conversationId;

  const LoadConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Envoyer un message
class SendMessage extends AIChatEvent {
  final String content;

  const SendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

/// Supprimer/archiver une conversation
class DeleteConversation extends AIChatEvent {
  final String conversationId;

  const DeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Effacer l'erreur
class ClearError extends AIChatEvent {
  const ClearError();
}

/// Sélectionner une action rapide
class SelectQuickAction extends AIChatEvent {
  final AIQuickAction action;

  const SelectQuickAction(this.action);

  @override
  List<Object?> get props => [action];
}
