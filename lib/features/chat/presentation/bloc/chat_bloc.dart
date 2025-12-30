import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/models/chat_message_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

// ==================== EVENTS ====================
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String reservationId;

  const LoadMessages(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

class LoadMoreMessages extends ChatEvent {}

class SendMessage extends ChatEvent {
  final String content;

  const SendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

class MessageReceived extends ChatEvent {
  final ChatMessage message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MarkMessagesAsRead extends ChatEvent {}

class SetTyping extends ChatEvent {
  final bool isTyping;

  const SetTyping(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}

class OtherUserTyping extends ChatEvent {
  final bool isTyping;

  const OtherUserTyping(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}

// ==================== STATES ====================
class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final bool hasMore;
  final bool isOtherTyping;
  final String? errorMessage;
  final String reservationId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.hasMore = true,
    this.isOtherTyping = false,
    this.errorMessage,
    this.reservationId = '',
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? hasMore,
    bool? isOtherTyping,
    String? errorMessage,
    String? reservationId,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      hasMore: hasMore ?? this.hasMore,
      isOtherTyping: isOtherTyping ?? this.isOtherTyping,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      reservationId: reservationId ?? this.reservationId,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isLoading,
        isSending,
        hasMore,
        isOtherTyping,
        errorMessage,
        reservationId,
      ];
}

// ==================== BLOC ====================
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;
  final SocketService socketService;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;

  ChatBloc({
    required this.repository,
    required this.socketService,
  }) : super(const ChatState()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<SetTyping>(_onSetTyping);
    on<OtherUserTyping>(_onOtherUserTyping);
  }

  void _setupSocketListeners(String reservationId) {
    // Rejoindre le room de la conversation
    socketService.emit('chat:join', {'reservationId': reservationId});

    // Écouter les nouveaux messages via le stream dédié
    _messageSubscription?.cancel();
    _messageSubscription = socketService.chatMessages.listen((data) {
      // Vérifier que le message est pour cette conversation
      final msgReservationId = data['reservationId'] as String?;
      final messageData = data['message'] as Map<String, dynamic>?;

      // Le message peut venir du room reservation:${id} (sans reservationId)
      // ou du room user:${userId} (avec reservationId)
      if (messageData != null) {
        // Vérifier si c'est pour cette conversation
        final msgResId = messageData['reservationId'] as String?;
        if (msgResId == reservationId || msgReservationId == reservationId || msgResId == null) {
          final message = ChatMessageModel.fromJson(messageData);
          add(MessageReceived(message));
        }
      }
    });

    // Écouter l'indicateur de frappe via le stream dédié
    _typingSubscription?.cancel();
    _typingSubscription = socketService.chatTyping.listen((data) {
      final typingReservationId = data['reservationId'] as String?;
      if (typingReservationId == reservationId) {
        final isTyping = data['isTyping'] as bool? ?? false;
        add(OtherUserTyping(isTyping));
      }
    });
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      reservationId: event.reservationId,
    ));

    _setupSocketListeners(event.reservationId);

    final result = await repository.getMessages(event.reservationId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (messages) => emit(state.copyWith(
        isLoading: false,
        messages: messages,
        hasMore: messages.length >= 50,
        clearError: true,
      )),
    );

    // Marquer les messages comme lus
    add(MarkMessagesAsRead());
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isLoading || !state.hasMore || state.messages.isEmpty) return;

    emit(state.copyWith(isLoading: true));

    final oldestMessage = state.messages.first;
    final result = await repository.getMessages(
      state.reservationId,
      before: oldestMessage.createdAt.toIso8601String(),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (messages) {
        final allMessages = [...messages, ...state.messages];
        emit(state.copyWith(
          isLoading: false,
          messages: allMessages,
          hasMore: messages.length >= 50,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (event.content.trim().isEmpty) return;

    emit(state.copyWith(isSending: true));

    final result = await repository.sendMessage(
      state.reservationId,
      event.content,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSending: false,
        errorMessage: failure.message,
      )),
      (message) {
        // Le message sera ajouté via le socket, mais on ajoute localement pour UX immédiate
        final exists = state.messages.any((m) => m.id == message.id);
        if (!exists) {
          emit(state.copyWith(
            isSending: false,
            messages: [...state.messages, message],
            clearError: true,
          ));
        } else {
          emit(state.copyWith(isSending: false, clearError: true));
        }
      },
    );
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    // Éviter les doublons
    final exists = state.messages.any((m) => m.id == event.message.id);
    if (!exists) {
      emit(state.copyWith(
        messages: [...state.messages, event.message],
        isOtherTyping: false,
      ));
      // Marquer comme lu
      add(MarkMessagesAsRead());
    }
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (state.reservationId.isEmpty) return;
    await repository.markAsRead(state.reservationId);
  }

  void _onSetTyping(
    SetTyping event,
    Emitter<ChatState> emit,
  ) {
    socketService.emit('chat:typing', {
      'reservationId': state.reservationId,
      'isTyping': event.isTyping,
    });
  }

  void _onOtherUserTyping(
    OtherUserTyping event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(isOtherTyping: event.isTyping));
  }

  @override
  Future<void> close() {
    // Quitter le room de la conversation
    if (state.reservationId.isNotEmpty) {
      socketService.emit('chat:leave', {'reservationId': state.reservationId});
    }
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    return super.close();
  }
}
