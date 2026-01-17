import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/entities/ai_conversation.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/usecases/send_ai_message_usecase.dart';

part 'ai_chat_event.dart';
part 'ai_chat_state.dart';

/// BLoC pour gérer le chat avec l'assistant IA
class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final AIChatRepository repository;
  final SendAIMessageUseCase sendAIMessage;
  final CreateConversationUseCase createConversation;
  final GetConversationsUseCase getConversations;
  final GetAIStatusUseCase getAIStatus;

  AIChatBloc({
    required this.repository,
    required this.sendAIMessage,
    required this.createConversation,
    required this.getConversations,
    required this.getAIStatus,
  }) : super(const AIChatState()) {
    on<CheckAIStatus>(_onCheckAIStatus);
    on<LoadConversations>(_onLoadConversations);
    on<CreateNewConversation>(_onCreateConversation);
    on<LoadConversation>(_onLoadConversation);
    on<SendMessage>(_onSendMessage);
    on<DeleteConversation>(_onDeleteConversation);
    on<ClearError>(_onClearError);
    on<SelectQuickAction>(_onSelectQuickAction);
  }

  Future<void> _onCheckAIStatus(
    CheckAIStatus event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(isCheckingStatus: true));

    final result = await getAIStatus();

    result.fold(
      (failure) => emit(state.copyWith(
        isCheckingStatus: false,
        isAIAvailable: false,
        errorMessage: failure.message,
      )),
      (status) => emit(state.copyWith(
        isCheckingStatus: false,
        isAIAvailable: status.isAvailable,
        quickActions: status.quickActions,
      )),
    );
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(isLoadingConversations: true, clearError: true));

    final result = await getConversations(page: event.page, limit: event.limit);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingConversations: false,
        errorMessage: failure.message,
      )),
      (conversations) => emit(state.copyWith(
        isLoadingConversations: false,
        conversations: conversations,
      )),
    );
  }

  Future<void> _onCreateConversation(
    CreateNewConversation event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(isCreatingConversation: true, clearError: true));

    final result = await createConversation(
      reservationId: event.reservationId,
      vehicleId: event.vehicleId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isCreatingConversation: false,
        errorMessage: failure.message,
      )),
      (conversation) {
        // Convertir en AIConversation si nécessaire
        final conv = conversation as AIConversation;
        emit(state.copyWith(
          isCreatingConversation: false,
          currentConversation: conv,
          messages: conv.messages,
        ));
      },
    );
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(isLoadingMessages: true, clearError: true));

    final result = await repository.getConversation(event.conversationId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMessages: false,
        errorMessage: failure.message,
      )),
      (conversation) => emit(state.copyWith(
        isLoadingMessages: false,
        currentConversation: conversation,
        messages: conversation.messages,
      )),
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AIChatState> emit,
  ) async {
    if (state.currentConversation == null) return;

    // Ajouter le message utilisateur localement pour UX immédiate
    final userMessage = AIChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: AIChatRole.user,
      content: event.content,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      isSendingMessage: true,
      clearError: true,
      messages: [...state.messages, userMessage],
    ));

    final result = await sendAIMessage(
      state.currentConversation!.id,
      event.content,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSendingMessage: false,
        errorMessage: failure.message,
      )),
      (assistantMessage) {
        // Remplacer le message temp par le vrai et ajouter la réponse
        final updatedMessages =
            state.messages.where((m) => !m.id.startsWith('temp_')).toList();

        // Ajouter le message utilisateur confirmé (sans le temp)
        final confirmedUserMessage = userMessage.copyWith(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        );

        emit(state.copyWith(
          isSendingMessage: false,
          messages: [
            ...updatedMessages,
            confirmedUserMessage,
            assistantMessage
          ],
        ));
      },
    );
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<AIChatState> emit,
  ) async {
    final result = await repository.deleteConversation(event.conversationId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        // Retirer la conversation de la liste
        final updatedConversations = state.conversations
            .where((c) => c.id != event.conversationId)
            .toList();

        // Si c'est la conversation actuelle, la vider
        if (state.currentConversation?.id == event.conversationId) {
          emit(state.copyWith(
            conversations: updatedConversations,
            currentConversation: null,
            messages: [],
          ));
        } else {
          emit(state.copyWith(conversations: updatedConversations));
        }
      },
    );
  }

  void _onClearError(ClearError event, Emitter<AIChatState> emit) {
    emit(state.copyWith(clearError: true));
  }

  void _onSelectQuickAction(
    SelectQuickAction event,
    Emitter<AIChatState> emit,
  ) {
    // Envoyer le prompt de l'action rapide comme message
    add(SendMessage(event.action.prompt));
  }
}
