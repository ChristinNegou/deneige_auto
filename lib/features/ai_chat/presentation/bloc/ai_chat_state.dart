part of 'ai_chat_bloc.dart';

/// État du BLoC AI Chat
class AIChatState extends Equatable {
  // Statut du service
  final bool isCheckingStatus;
  final bool isAIAvailable;
  final List<AIQuickAction> quickActions;

  // Liste des conversations
  final bool isLoadingConversations;
  final List<AIConversation> conversations;

  // Conversation actuelle
  final bool isCreatingConversation;
  final bool isLoadingMessages;
  final AIConversation? currentConversation;
  final List<AIChatMessage> messages;

  // Envoi de message
  final bool isSendingMessage;

  // Erreur
  final String? errorMessage;

  const AIChatState({
    this.isCheckingStatus = false,
    this.isAIAvailable = false,
    this.quickActions = const [],
    this.isLoadingConversations = false,
    this.conversations = const [],
    this.isCreatingConversation = false,
    this.isLoadingMessages = false,
    this.currentConversation,
    this.messages = const [],
    this.isSendingMessage = false,
    this.errorMessage,
  });

  /// Vérifie si une opération est en cours
  bool get isLoading =>
      isCheckingStatus ||
      isLoadingConversations ||
      isCreatingConversation ||
      isLoadingMessages ||
      isSendingMessage;

  /// Vérifie si on peut envoyer un message
  bool get canSendMessage =>
      isAIAvailable && currentConversation != null && !isSendingMessage;

  /// Vérifie s'il y a une erreur
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Crée une copie avec des modifications
  AIChatState copyWith({
    bool? isCheckingStatus,
    bool? isAIAvailable,
    List<AIQuickAction>? quickActions,
    bool? isLoadingConversations,
    List<AIConversation>? conversations,
    bool? isCreatingConversation,
    bool? isLoadingMessages,
    AIConversation? currentConversation,
    List<AIChatMessage>? messages,
    bool? isSendingMessage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AIChatState(
      isCheckingStatus: isCheckingStatus ?? this.isCheckingStatus,
      isAIAvailable: isAIAvailable ?? this.isAIAvailable,
      quickActions: quickActions ?? this.quickActions,
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      conversations: conversations ?? this.conversations,
      isCreatingConversation:
          isCreatingConversation ?? this.isCreatingConversation,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      currentConversation: currentConversation ?? this.currentConversation,
      messages: messages ?? this.messages,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isCheckingStatus,
        isAIAvailable,
        quickActions,
        isLoadingConversations,
        conversations,
        isCreatingConversation,
        isLoadingMessages,
        currentConversation,
        messages,
        isSendingMessage,
        errorMessage,
      ];
}
