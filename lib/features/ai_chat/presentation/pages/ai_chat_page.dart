import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ai_chat_bloc.dart';
import '../widgets/ai_chat_bubble.dart';
import '../widgets/ai_typing_indicator.dart';
import '../widgets/ai_quick_actions.dart';

/// Page principale du chat avec l'assistant IA
class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Vérifier le statut et créer une conversation au démarrage
    final bloc = context.read<AIChatBloc>();
    bloc.add(const CheckAIStatus());
    bloc.add(const CreateNewConversation());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<AIChatBloc>().add(SendMessage(content));
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 24),
            SizedBox(width: 8),
            Text('Assistant IA'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nouvelle conversation',
            onPressed: () {
              context.read<AIChatBloc>().add(const CreateNewConversation());
            },
          ),
        ],
      ),
      body: BlocConsumer<AIChatBloc, AIChatState>(
        listener: (context, state) {
          // Scroll en bas quand un nouveau message arrive
          if (state.messages.isNotEmpty && !state.isSendingMessage) {
            _scrollToBottom();
          }

          // Afficher les erreurs
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Theme.of(context).colorScheme.onError,
                  onPressed: () {
                    context.read<AIChatBloc>().add(const ClearError());
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Indicateur de service non disponible
              if (!state.isAIAvailable && !state.isCheckingStatus)
                _buildServiceUnavailableBanner(context),

              // Liste des messages
              Expanded(
                child: state.isLoadingMessages || state.isCreatingConversation
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMessagesList(context, state),
              ),

              // Actions rapides
              if (state.quickActions.isNotEmpty && state.messages.length <= 1)
                AIQuickActions(
                  actions: state.quickActions,
                  onActionSelected: (action) {
                    context.read<AIChatBloc>().add(SelectQuickAction(action));
                  },
                  enabled: state.canSendMessage,
                ),

              // Zone de saisie
              _buildInputArea(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceUnavailableBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'L\'assistant IA est temporairement indisponible',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, AIChatState state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Commencez une conversation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posez vos questions sur Déneige Auto',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: state.messages.length + (state.isSendingMessage ? 1 : 0),
      itemBuilder: (context, index) {
        // Afficher l'indicateur de typing si en attente de réponse
        if (state.isSendingMessage && index == state.messages.length) {
          return const AITypingIndicator();
        }

        final message = state.messages[index];
        return AIChatBubble(
          message: message,
          showTimestamp: true,
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, AIChatState state) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: state.canSendMessage,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Écrivez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: state.canSendMessage ? _sendMessage : null,
            icon: state.isSendingMessage
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
