import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/chat_models.dart';
import 'chat_text_direction.dart';
import 'providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final ChatConversationModel? conversation;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authControllerProvider).role;
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final action = ref.watch(chatActionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to conversations',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _leaveRoom(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation?.titleForRole(role) ?? 'Conversation'),
            Text(
              'Secure care chat',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ChatError(
                message: _friendlyError(error),
                onRetry: () =>
                    ref.invalidate(chatMessagesProvider(widget.conversationId)),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(chatMessagesProvider(widget.conversationId));
                  await ref.read(
                    chatMessagesProvider(widget.conversationId).future,
                  );
                },
                child: items.isEmpty
                    ? const _NoMessages()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final message = items[index];
                          return _MessageBubble(
                            message: message,
                            isMine: message.isMine(role),
                          );
                        },
                      ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: _Composer(
              controller: _messageController,
              isSending: action.isLoading,
              onSend: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final message = await ref
        .read(chatActionProvider.notifier)
        .sendMessage(conversationId: widget.conversationId, content: content);

    if (!mounted) return;
    final error = ref.read(chatActionProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      return;
    }

    if (message != null) {
      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isMine ? scheme.primary : scheme.surfaceContainerHighest;
    final foreground = isMine ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Directionality(
                textDirection: textDirectionFor(message.content),
                child: Text(
                  message.content,
                  textAlign: textAlignFor(message.content),
                  style: TextStyle(color: foreground, height: 1.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  TextDirection _direction = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _direction = textDirectionFor(widget.controller.text);
    widget.controller.addListener(_syncDirectionFromController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncDirectionFromController);
    super.dispose();
  }

  void _syncDirectionFromController() {
    _updateDirection(widget.controller.text);
  }

  void _updateDirection(String value) {
    final direction = textDirectionFor(value);
    if (direction != _direction) {
      setState(() => _direction = direction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                textDirection: _direction,
                textAlign: _direction == TextDirection.rtl
                    ? TextAlign.right
                    : TextAlign.left,
                textInputAction: TextInputAction.send,
                onChanged: _updateDirection,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: widget.isSending ? null : widget.onSend,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: widget.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMessages extends StatelessWidget {
  const _NoMessages();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.mark_chat_unread_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'No messages yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Send a message to begin this care conversation.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChatError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChatError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('403')) {
    return 'You can only open chat conversations linked to your appointments.';
  }
  if (text.contains('401')) {
    return 'Your session expired. Please log in again.';
  }
  return 'We could not load this conversation. Please try again.';
}

void _leaveRoom(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  context.go('/chat');
}
